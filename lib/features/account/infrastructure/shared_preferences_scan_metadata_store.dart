import 'dart:convert';

import 'package:eyes_mobile/features/account/application/scan_metadata_store.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// All read/modify/write operations share one serial executor. Never evicts.
final class SharedPreferencesScanMetadataStore implements ScanMetadataStore {
  SharedPreferencesScanMetadataStore(this._preferences);

  static const queueKey = 'account.scan-metadata.v1';
  static const ownerKey = 'account.scan-consent-owner.v1';
  static const installationKey = 'account.scan-installation.v1';
  static const maximumSessions = 20;
  final SharedPreferencesAsync _preferences;
  Future<void> _tail = Future.value();

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<String?> readConsentOwner() =>
      _serial(() => _preferences.getString(ownerKey));

  @override
  Future<void> writeConsentOwner(String? owner) => _serial(() async {
    if (owner == null) {
      await _preferences.remove(ownerKey);
      await _preferences.remove(installationKey);
    } else {
      await _preferences.setString(ownerKey, owner);
    }
  });

  @override
  Future<String> installationId() => _serial(() async {
    final existing = await _preferences.getString(installationKey);
    if (existing != null) return existing;
    final created = metadataUuid();
    await _preferences.setString(installationKey, created);
    return created;
  });

  Future<List<ScanMetadata>> _read() async =>
      (await _preferences.getStringList(queueKey) ?? <String>[])
          .map(
            (raw) =>
                ScanMetadata.fromJson(jsonDecode(raw) as Map<String, dynamic>),
          )
          .toList();

  Future<void> _write(List<ScanMetadata> items) => _preferences.setStringList(
    queueKey,
    items.map((item) => jsonEncode(item.toJson())).toList(),
  );

  @override
  Future<List<ScanMetadata>> pending() => _serial(_read);

  @override
  Future<void> add(ScanMetadata session) => _serial(() async {
    final items = await _read();
    final existing = items.where((item) => item.id == session.id).firstOrNull;
    if (existing != null) {
      if (jsonEncode(existing.toJson()) != jsonEncode(session.toJson())) {
        throw const FormatException('Conflicting local session.');
      }
      return;
    }
    if (items.length >= maximumSessions) throw const ScanMetadataQueueFull();
    items.add(session);
    await _write(items);
  });

  @override
  Future<void> remove(String id) => _serial(() async {
    final items = await _read();
    items.removeWhere((item) => item.id == id);
    await _write(items);
  });

  @override
  Future<void> clear() => _serial(() => _preferences.remove(queueKey));
}
