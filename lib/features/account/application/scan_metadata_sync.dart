import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/scan_metadata_store.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';
import 'package:eyes_mobile/features/account/infrastructure/dio_scan_metadata_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScanSyncStatus {
  disabled,
  idle,
  collecting,
  queued,
  sending,
  retryable,
  authenticationRequired,
  unavailable,
  blocked,
  storageFailure,
  queueFull,
  deleted,
  deleteFailed,
}

final class ScanSyncSnapshot {
  const ScanSyncSnapshot(this.status, {this.pendingSessions = 0});
  final ScanSyncStatus status;
  final int pendingSessions;
}

/// Collection never awaits HTTP. Closed sessions are replayed unchanged until
/// every batch and the finish receipt have been verified.
final class ScanMetadataSync {
  ScanMetadataSync({
    required this.store,
    required this.preferences,
    required this.accounts,
    required this.gateway,
    this.remoteAvailable = true,
    DateTime Function()? clock,
    this.retryDelays = const [
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 2),
      Duration(minutes: 5),
    ],
  }) : _clock = clock ?? DateTime.now {
    _subscription = accounts.changes.listen(_accountChanged);
    ready = _refresh();
  }

  final ScanMetadataStore store;
  final SyncPreferencesRepository preferences;
  final RemoteSessionStore accounts;
  final ScanMetadataGateway gateway;
  final bool remoteAvailable;
  final DateTime Function() _clock;
  final List<Duration> retryDelays;
  late final Future<void> ready;
  late final StreamSubscription<RemoteSessionChange> _subscription;
  final _changes = StreamController<ScanSyncSnapshot>.broadcast();
  Stream<ScanSyncSnapshot> get changes => _changes.stream;
  ScanSyncSnapshot snapshot = const ScanSyncSnapshot(ScanSyncStatus.disabled);
  RemoteSession? _account;
  String? _owner;
  String? _installation;
  bool _consented = false;
  bool _scanning = false;
  bool _disposed = false;
  bool _policyBusy = false;
  bool _persistenceFailed = false;
  int _epoch = 0;
  int _attempt = 0;
  Timer? _retry;
  CancelToken? _cancellation;
  Future<void>? _running;
  Future<void> _writes = Future.value();
  final List<ScanMetadata> _unsaved = [];
  _OpenScan? _open;
  final Map<AssistiveAlertMessage, ProximityAlertEvent> _candidates = {};
  ProximityAlertEvent? _speaking;
  String? _speechText;

  bool get consented => _consented;
  bool get scanning => _scanning;

  void _set(ScanSyncStatus status, {int? pending}) {
    if (_disposed) return;
    snapshot = ScanSyncSnapshot(
      status,
      pendingSessions: pending ?? snapshot.pendingSessions,
    );
    _changes.add(snapshot);
  }

  Future<void> _refresh() async {
    final epoch = _epoch;
    try {
      await _writes;
      final account = await accounts.read();
      final owner = await store.readConsentOwner();
      final consent = await preferences.readConsent();
      final installation = consent && owner != null
          ? await store.installationId()
          : null;
      final pending = await store.pending();
      if (_disposed || _policyBusy || epoch != _epoch) return;
      _account = account;
      _owner = owner;
      _installation = installation;
      _consented = consent && owner != null && account?.user.id == owner;
      final count = pending.where((s) => s.ownerId == owner).length;
      if (_unsaved.isNotEmpty) {
        _set(ScanSyncStatus.storageFailure, pending: count + _unsaved.length);
        return;
      }
      if (!_consented) {
        _set(
          consent && owner != null && account == null
              ? ScanSyncStatus.authenticationRequired
              : ScanSyncStatus.disabled,
          pending: count,
        );
      } else if (!remoteAvailable) {
        _set(ScanSyncStatus.unavailable, pending: count);
      } else if (_scanning) {
        _set(ScanSyncStatus.queued, pending: count + _unsaved.length);
        _begin();
        _set(
          _open == null ? ScanSyncStatus.queueFull : ScanSyncStatus.collecting,
        );
      } else {
        _set(
          count > 0 ? ScanSyncStatus.queued : ScanSyncStatus.idle,
          pending: count,
        );
      }
    } on Object {
      if (epoch == _epoch) {
        _consented = false;
        _set(ScanSyncStatus.storageFailure);
      }
    }
  }

  void _cancel() {
    _epoch++;
    _retry?.cancel();
    _retry = null;
    _cancellation?.cancel();
  }

  void _accountChanged(RemoteSessionChange change) {
    _cancel();
    // Expiration preserves metadata already collected under this consent.
    if (change.reason == RemoteSessionChangeReason.expired) {
      _close();
    } else {
      _open = null;
      _candidates.clear();
    }
    _consented = false;
    _account = null;
    unawaited(_refresh());
  }

  Future<void> setConsent(bool enabled) async {
    if (_policyBusy || _disposed) return;
    _policyBusy = true;
    _cancel();
    _open = null;
    _candidates.clear();
    _speaking = null;
    _consented = false;
    try {
      await _running;
      await _writes;
      if (enabled) {
        final account = await accounts.read();
        if (account == null || !remoteAvailable) {
          _set(
            account == null
                ? ScanSyncStatus.authenticationRequired
                : ScanSyncStatus.unavailable,
          );
          return;
        }
        final previousOwner = await store.readConsentOwner();
        if (previousOwner != null && previousOwner != account.user.id) {
          await store.clear();
          _unsaved.clear();
        }
        await store.writeConsentOwner(account.user.id);
        await preferences.writeConsent(true);
      } else {
        await preferences.writeConsent(false);
        await store.writeConsentOwner(null);
        await store.clear();
        _unsaved.clear();
      }
      _attempt = 0;
      _persistenceFailed = false;
    } finally {
      _policyBusy = false;
    }
    await _refresh();
  }

  void setScanning(bool value) {
    if (_disposed || value == _scanning) return;
    _scanning = value;
    if (value) {
      _cancel();
      _begin();
      if (_consented && _open != null) _set(ScanSyncStatus.collecting);
    } else {
      _close();
      unawaited(_afterScan());
    }
  }

  Future<void> _afterScan() async {
    await _writes;
    if (_disposed || _scanning) return;
    await _refresh();
    await retry();
  }

  void _begin() {
    if (_open != null ||
        !_consented ||
        _policyBusy ||
        !remoteAvailable ||
        _owner == null ||
        _installation == null) {
      return;
    }
    if (snapshot.pendingSessions >= 20 || _persistenceFailed) {
      _set(
        _persistenceFailed
            ? ScanSyncStatus.storageFailure
            : ScanSyncStatus.queueFull,
      );
      return;
    }
    _open = _OpenScan(_owner!, _installation!, metadataTime(_clock()));
  }

  void recordFrame(DetectionBatch batch) {
    if (_open == null || _persistenceFailed) return;
    if (batch.capturedAt.difference(_open!.startedAt) >=
            const Duration(minutes: 119) ||
        _open!.frames >= 999999 ||
        (_open!.inferenceMicros + batch.timings.inference.inMicroseconds) ~/
                1000 >
            1000000000) {
      _close();
      _begin();
    }
    final open = _open;
    if (open == null || batch.capturedAt.isBefore(open.startedAt)) return;
    open.frames++;
    open.inferenceMicros += batch.timings.inference.inMicroseconds;
  }

  void onAlertQueued(ProximityAlertEvent event, AssistiveAlertMessage message) {
    if (_open == null || _persistenceFailed || event.confidence == null) return;
    _candidates[message] = event;
    if (_candidates.length > 16) _candidates.remove(_candidates.keys.first);
  }

  void onPlaybackRequested(AssistiveAlertMessage message) {
    _speaking = _candidates.remove(message);
    _speechText = message.text;
  }

  void recordSpeechStarted(String message, DateTime startedAt) {
    final event = _speaking;
    _speaking = null;
    if (event == null || message != _speechText || _open == null) return;
    final open = _open!;
    if (event.occurredAt.isBefore(open.startedAt) ||
        startedAt.isBefore(event.occurredAt) ||
        startedAt.difference(open.startedAt) > const Duration(hours: 2)) {
      return;
    }
    final latency = startedAt.difference(event.occurredAt).inMilliseconds;
    if (open.events.length >= 200 || open.ttsMillis + latency > 1000000000) {
      // Start a new segment before subsequent frames; do not fabricate frame counts.
      _close();
      _begin();
      _set(ScanSyncStatus.blocked);
      return;
    }
    open.events.add(
      ScanMetadataEvent(
        id: metadataUuid(),
        kind: event.kind,
        confidence: double.parse(event.confidence!.toStringAsFixed(6)),
        band: event.band,
        direction: event.direction,
        occurredAt: event.occurredAt,
      ),
    );
    open.ttsMillis += latency;
    if (open.events.length == 200) {
      _close();
      _begin();
    }
  }

  void _close() {
    final open = _open;
    _open = null;
    _candidates.clear();
    _speaking = null;
    if (open == null || open.frames == 0) return;
    final now = metadataTime(_clock());
    final lastEvent = open.events.isEmpty
        ? open.startedAt
        : open.events.last.occurredAt;
    final end = now.isBefore(lastEvent) ? lastEvent : now;
    if (end.difference(open.startedAt) > const Duration(hours: 2)) {
      _set(ScanSyncStatus.blocked);
      return;
    }
    final closed = ScanMetadata(
      ownerId: open.owner,
      id: open.id,
      installationId: open.installation,
      startedAt: open.startedAt,
      endedAt: end,
      events: open.events,
      processedFrames: open.frames,
      inferenceMillisTotal: open.inferenceMicros ~/ 1000,
      ttsLatencySamples: open.events.length,
      ttsLatencyMillisTotal: open.ttsMillis,
    );
    _set(
      _scanning ? ScanSyncStatus.collecting : ScanSyncStatus.queued,
      pending: snapshot.pendingSessions + 1,
    );
    _unsaved.add(closed);
    _writes = _writes.then((_) async {
      try {
        await store.add(closed);
        _unsaved.remove(closed);
        if (_unsaved.isEmpty) _persistenceFailed = false;
        _set(
          _scanning ? ScanSyncStatus.collecting : ScanSyncStatus.queued,
          pending: snapshot.pendingSessions,
        );
      } on ScanMetadataQueueFull {
        _persistenceFailed = true;
        _set(ScanSyncStatus.queueFull);
      } on Object {
        _persistenceFailed = true;
        _set(ScanSyncStatus.storageFailure);
      }
    });
  }

  Future<void> retry() async {
    if (_disposed ||
        _scanning ||
        _running != null ||
        _policyBusy ||
        !_consented ||
        _unsaved.isNotEmpty ||
        !remoteAvailable) {
      return;
    }
    _retry?.cancel();
    _retry = null;
    _running = _upload();
    try {
      await _running;
    } finally {
      _running = null;
    }
  }

  Future<void> retryManually() async {
    if (_policyBusy || _disposed) return;
    _attempt = 0;
    await _writes;
    for (final session in _unsaved.toList()) {
      try {
        await store.add(session);
        _unsaved.remove(session);
      } on Object {
        _set(ScanSyncStatus.storageFailure);
        return;
      }
    }
    _persistenceFailed = false;
    await _refresh();
    await retry();
  }

  Future<void> _upload() async {
    final epoch = _epoch;
    final account = _account;
    if (account == null || account.user.id != _owner) return;
    final cancellation = CancelToken();
    _cancellation = cancellation;
    try {
      await _writes;
      final pending = await store.pending();
      for (final session in pending.where(
        (s) => s.ownerId == account.user.id,
      )) {
        if (epoch != _epoch || _scanning || _disposed) return;
        if (_clock().difference(session.startedAt) >=
            const Duration(days: 30)) {
          _set(ScanSyncStatus.blocked);
          return;
        }
        _set(ScanSyncStatus.sending);
        await gateway.upload(session, account, cancellation);
        if (epoch != _epoch || _scanning || _disposed) return;
        await store.remove(session.id);
        _set(
          ScanSyncStatus.queued,
          pending: (snapshot.pendingSessions - 1).clamp(0, 20),
        );
      }
      _attempt = 0;
      _set(ScanSyncStatus.idle, pending: 0);
    } on DioException catch (error) {
      if (epoch != _epoch || error.type == DioExceptionType.cancel) return;
      final status = error.response?.statusCode;
      if (status == 401) {
        _set(ScanSyncStatus.authenticationRequired);
        final current = await accounts.read();
        if (current?.accessToken == account.accessToken) {
          await accounts.clear(reason: RemoteSessionChangeReason.expired);
        }
      } else if (status == 409) {
        _set(ScanSyncStatus.unavailable);
      } else if (status == null ||
          status >= 500 ||
          status == 408 ||
          status == 429) {
        _set(ScanSyncStatus.retryable);
        if (_attempt < retryDelays.length) {
          _retry = Timer(retryDelays[_attempt++], () => unawaited(retry()));
        }
      } else {
        _set(ScanSyncStatus.blocked);
      }
    } on Object {
      if (epoch == _epoch) _set(ScanSyncStatus.blocked);
    } finally {
      if (_cancellation == cancellation) _cancellation = null;
    }
  }

  Future<void> deleteHistory() async {
    final account = await accounts.read();
    if (account == null) {
      _set(ScanSyncStatus.authenticationRequired);
      return;
    }
    await setConsent(false);
    final cancellation = CancelToken();
    final epoch = _epoch;
    _policyBusy = true;
    _cancellation = cancellation;
    try {
      await gateway.deleteHistory(account, cancellation);
      if (epoch == _epoch) _set(ScanSyncStatus.deleted, pending: 0);
    } on DioException catch (error) {
      if (epoch == _epoch) {
        _set(
          error.response?.statusCode == 401
              ? ScanSyncStatus.authenticationRequired
              : ScanSyncStatus.deleteFailed,
        );
      }
    } on Object {
      if (epoch == _epoch) _set(ScanSyncStatus.deleteFailed);
    } finally {
      _policyBusy = false;
      if (_cancellation == cancellation) _cancellation = null;
      if (epoch != _epoch) unawaited(_refresh());
    }
  }

  Future<void> dispose() async {
    _cancel();
    _disposed = true;
    _open = null;
    await _subscription.cancel();
    await _running;
    await _writes;
    // A hidden UI may pause its subscription. Closing notifications must not
    // hold resource disposal until that UI resumes.
    unawaited(_changes.close());
  }
}

final class _OpenScan {
  _OpenScan(this.owner, this.installation, this.startedAt);
  final String owner;
  final String installation;
  final DateTime startedAt;
  final String id = metadataUuid();
  final List<ScanMetadataEvent> events = [];
  int frames = 0;
  int inferenceMicros = 0;
  int ttsMillis = 0;
}

/// Bootstrap enables the real service; offline-only test hosts need no network.
final scanMetadataSyncProvider = Provider<ScanMetadataSync?>((ref) => null);

final scanSyncSnapshotProvider = StreamProvider<ScanSyncSnapshot>((ref) async* {
  final service = ref.watch(scanMetadataSyncProvider);
  if (service == null) {
    yield const ScanSyncSnapshot(ScanSyncStatus.disabled);
    return;
  }
  yield service.snapshot;
  yield* service.changes;
});
