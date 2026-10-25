import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CameraSourceKind { phone, webcam }

final class WebcamDevice {
  const WebcamDevice({required this.id, required this.name});

  final int id;
  final String name;
}

final class CameraSourceState {
  const CameraSourceState({
    this.preference,
    this.webcams = const <WebcamDevice>[],
    this.active,
  });

  /// A null preference means: prefer an attached webcam on the next start.
  final CameraSourceKind? preference;
  final List<WebcamDevice> webcams;
  final CameraSourceKind? active;

  CameraSourceKind get selected =>
      preference ??
      (webcams.isNotEmpty ? CameraSourceKind.webcam : CameraSourceKind.phone);

  bool get webcamAvailable => webcams.isNotEmpty;
}

abstract interface class CameraSourcePreferenceStore {
  Future<CameraSourceKind?> load();

  Future<void> save(CameraSourceKind kind);
}

abstract interface class CameraSourceSelector {
  CameraSourceState get sourceState;

  Stream<CameraSourceState> get sourceChanges;

  Future<CameraSourceState> refreshSources();

  Future<void> selectSource(CameraSourceKind kind);
}

/// The camera gateway remains replaceable in tests and on platforms without USB.
final Provider<CameraSourceSelector?> cameraSourceSelectorProvider =
    Provider<CameraSourceSelector?>((Ref ref) {
      final gateway = ref.read(cameraGatewayProvider);
      return gateway is CameraSourceSelector
          ? gateway as CameraSourceSelector
          : null;
    });

final StreamProvider<CameraSourceState> cameraSourceStateProvider =
    StreamProvider<CameraSourceState>((Ref ref) async* {
      final selector = ref.read(cameraSourceSelectorProvider);
      if (selector == null) {
        yield const CameraSourceState();
        return;
      }
      yield await selector.refreshSources();
      yield* selector.sourceChanges;
    });
