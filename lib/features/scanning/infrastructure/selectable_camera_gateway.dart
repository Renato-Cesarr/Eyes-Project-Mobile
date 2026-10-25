import 'dart:async';

import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/camera_source.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/uvc_camera_gateway.dart';

/// Chooses one producer of CameraFrame. Detection and feedback are unchanged.
final class SelectableCameraGateway
    implements CameraGateway, CameraSourceSelector {
  SelectableCameraGateway(this._phone, this._webcam, this._store) {
    _deviceSubscription = _webcam.deviceEvents.listen((_) {
      unawaited(refreshSources());
    });
  }

  final CameraGateway _phone;
  final WebcamCameraGateway _webcam;
  final CameraSourcePreferenceStore _store;
  final StreamController<CameraSourceState> _changes =
      StreamController<CameraSourceState>.broadcast();
  StreamSubscription<Object?>? _deviceSubscription;
  CameraSourceState _state = const CameraSourceState();
  CameraGateway? _activeGateway;
  bool _preferenceLoaded = false;
  bool _disposed = false;

  CameraGateway? get activeGateway => _activeGateway;

  @override
  CameraSourceState get sourceState => _state;

  @override
  Stream<CameraSourceState> get sourceChanges => _changes.stream;

  @override
  Future<CameraSourceState> refreshSources() async {
    if (_disposed) return _state;
    if (!_preferenceLoaded) {
      final preference = await _store.load();
      _preferenceLoaded = true;
      _state = CameraSourceState(
        preference: preference,
        webcams: _state.webcams,
        active: _state.active,
        fellBackToPhone: _state.fellBackToPhone,
      );
    }
    try {
      final webcams = await _webcam.discover();
      _publish(
        CameraSourceState(
          preference: _state.preference,
          webcams: List<WebcamDevice>.unmodifiable(webcams),
          active: _state.active,
          fellBackToPhone: _state.fellBackToPhone,
        ),
      );
    } on Object {
      // Internal camera remains available if USB enumeration fails.
      _publish(
        CameraSourceState(
          preference: _state.preference,
          active: _state.active,
          fellBackToPhone: _state.fellBackToPhone,
        ),
      );
    }
    return _state;
  }

  @override
  Future<void> selectSource(CameraSourceKind kind) async {
    await _store.save(kind);
    _preferenceLoaded = true;
    _publish(
      CameraSourceState(
        preference: kind,
        webcams: _state.webcams,
        active: _state.active,
        fellBackToPhone: _state.fellBackToPhone,
      ),
    );
  }

  void _publish(CameraSourceState value) {
    if (_disposed) return;
    _state = value;
    _changes.add(value);
  }

  @override
  double? get previewAspectRatio => _activeGateway?.previewAspectRatio;

  @override
  bool get isPreviewReady => _activeGateway?.isPreviewReady ?? false;

  @override
  Future<CameraPermissionState> checkPermission() => _phone.checkPermission();

  @override
  Future<CameraPermissionState> requestPermission() =>
      _phone.requestPermission();

  @override
  Future<bool> openSettings() => _phone.openSettings();

  @override
  Future<void> initialize(CameraConfiguration configuration) async {
    await release();
    final sources = await refreshSources();
    final kind = sources.selected;
    if (kind == CameraSourceKind.webcam && !sources.webcamAvailable) {
      throw const CameraGatewayException(
        CameraGatewayFailureReason.noCamera,
        code: 'webcam-not-connected',
      );
    }
    final gateway = kind == CameraSourceKind.webcam ? _webcam : _phone;
    final selectedConfiguration = configuration.withSource(
      kind,
      webcamDeviceId: kind == CameraSourceKind.webcam
          ? sources.webcams.first.id
          : null,
    );
    _activeGateway = gateway;
    try {
      await gateway.initialize(selectedConfiguration);
    } on CameraGatewayException {
      await release();
      if (kind != CameraSourceKind.webcam || sources.preference != null) {
        rethrow;
      }
      // Auto-selection happens before a stream starts. A USB device can be
      // enumerated yet fail to negotiate video; keep assistance available via
      // the phone and disclose the fallback in the accessible status.
      _activeGateway = _phone;
      try {
        await _phone.initialize(
          configuration.withSource(CameraSourceKind.phone),
        );
      } on Object {
        await release();
        rethrow;
      }
      _publish(
        CameraSourceState(
          preference: null,
          webcams: _state.webcams,
          active: CameraSourceKind.phone,
          fellBackToPhone: true,
        ),
      );
      return;
    } on Object {
      await release();
      rethrow;
    }
    _publish(
      CameraSourceState(
        preference: _state.preference,
        webcams: _state.webcams,
        active: kind,
      ),
    );
  }

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async {
    final gateway = _activeGateway;
    if (gateway == null) {
      throw const CameraGatewayException(
        CameraGatewayFailureReason.initialization,
        code: 'source-not-initialized',
      );
    }
    await gateway.startStream(
      onFrame: onFrame,
      onTelemetry: onTelemetry,
      onError: onError,
    );
  }

  @override
  Future<void> release() async {
    final gateway = _activeGateway;
    _activeGateway = null;
    if (gateway != null) await gateway.release();
    _publish(
      CameraSourceState(preference: _state.preference, webcams: _state.webcams),
    );
  }

  Future<void> dispose() async {
    await _deviceSubscription?.cancel();
    await release();
    _disposed = true;
    await _webcam.dispose();
    await _changes.close();
  }
}
