import 'package:camera/camera.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/mobile_camera_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CameraPreviewSurface extends ConsumerWidget {
  const CameraPreviewSurface({
    required this.aspectRatio,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    super.key,
  }) : assert(aspectRatio > 0);

  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateway = ref.read(cameraGatewayProvider);
    final controller = gateway is MobileCameraGateway
        ? gateway.previewController
        : null;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final displayAspectRatio = orientedAspectRatio(
                sourceAspectRatio: aspectRatio,
                viewport: constraints.biggest,
              );
              final preview = controller == null
                  ? const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Icon(
                          Icons.videocam_off_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    )
                  : CameraPreview(controller);

              if (fit == BoxFit.contain || !constraints.hasBoundedHeight) {
                return AspectRatio(
                  aspectRatio: displayAspectRatio,
                  child: preview,
                );
              }

              // A câmera mantém a proporção nativa e cobre o palco sem
              // deformação. O excedente é recortado de forma centralizada.
              return SizedBox.expand(
                child: FittedBox(
                  fit: fit,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: displayAspectRatio * 1000,
                    height: 1000,
                    child: preview,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Aligns the sensor ratio with the visible orientation without stretching
  /// pixels. Android cameras commonly report a landscape ratio while the app
  /// is being used in portrait.
  static double orientedAspectRatio({
    required double sourceAspectRatio,
    required Size viewport,
  }) {
    if (!viewport.width.isFinite || !viewport.height.isFinite) {
      return sourceAspectRatio;
    }
    final viewportIsPortrait = viewport.height > viewport.width;
    final sourceIsPortrait = sourceAspectRatio < 1;
    return viewportIsPortrait == sourceIsPortrait
        ? sourceAspectRatio
        : 1 / sourceAspectRatio;
  }
}
