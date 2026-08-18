import 'package:camera/camera.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/mobile_camera_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CameraPreviewSurface extends ConsumerWidget {
  const CameraPreviewSurface({required this.aspectRatio, super.key});

  final double aspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateway = ref.read(cameraGatewayProvider);
    final controller = gateway is MobileCameraGateway
        ? gateway.previewController
        : null;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Colors.black,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: controller == null
                ? const Center(
                    child: Icon(
                      Icons.videocam_off_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  )
                : CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
