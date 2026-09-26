import 'package:eyes_mobile/features/scanning/infrastructure/camera_preview_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraPreviewSurface.orientedAspectRatio', () {
    test('inverts a landscape sensor ratio for a portrait viewport', () {
      final ratio = CameraPreviewSurface.orientedAspectRatio(
        sourceAspectRatio: 16 / 9,
        viewport: const Size(412, 915),
      );

      expect(ratio, closeTo(9 / 16, 0.0001));
    });

    test('keeps a landscape sensor ratio in a landscape viewport', () {
      final ratio = CameraPreviewSurface.orientedAspectRatio(
        sourceAspectRatio: 16 / 9,
        viewport: const Size(915, 412),
      );

      expect(ratio, closeTo(16 / 9, 0.0001));
    });

    test('inverts a portrait source after supported rotation', () {
      final ratio = CameraPreviewSurface.orientedAspectRatio(
        sourceAspectRatio: 9 / 16,
        viewport: const Size(915, 412),
      );

      expect(ratio, closeTo(16 / 9, 0.0001));
    });
  });
}
