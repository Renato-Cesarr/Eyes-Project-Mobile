import 'dart:isolate';

import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:flutter/services.dart';

typedef VisionWorkerEntrypoint = void Function(VisionWorkerBootstrap bootstrap);

/// Internal cross-isolate protocol. These values are public only so the
/// transport can be exercised without loading the native TFLite runtime.
final class VisionWorkerBootstrap {
  const VisionWorkerBootstrap({
    required this.responses,
    required this.rootIsolateToken,
    required this.modelAssets,
  });

  final SendPort responses;
  final RootIsolateToken rootIsolateToken;
  final TransferableModelAssets modelAssets;
}

final class TransferredModelAssets {
  const TransferredModelAssets({
    required this.manifestSource,
    required this.modelBytes,
  });

  final String manifestSource;
  final Uint8List modelBytes;
}

final class TransferableModelAssets {
  TransferableModelAssets._({
    required this.manifestSource,
    required this.modelBytes,
  });

  factory TransferableModelAssets.fromBytes({
    required String manifestSource,
    required Uint8List modelBytes,
  }) {
    return TransferableModelAssets._(
      manifestSource: manifestSource,
      modelBytes: TransferableTypedData.fromList([modelBytes]),
    );
  }

  final String manifestSource;
  final TransferableTypedData modelBytes;

  TransferredModelAssets materialize() {
    return TransferredModelAssets(
      manifestSource: manifestSource,
      modelBytes: modelBytes.materialize().asUint8List(),
    );
  }
}

final class VisionPlaneLayout {
  const VisionPlaneLayout({
    required this.offset,
    required this.length,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final int offset;
  final int length;
  final int bytesPerRow;
  final int bytesPerPixel;
}

final class TransferableVisionFrame {
  TransferableVisionFrame._({
    required this.width,
    required this.height,
    required this.formatIndex,
    required this.rotationIndex,
    required this.capturedAtMicrosecondsUtc,
    required this.layouts,
    required this.bytes,
  });

  factory TransferableVisionFrame.fromFrame(VisionFrame frame) {
    if (frame.planes.isEmpty) {
      throw ArgumentError.value(frame.planes, 'planes', 'não pode ser vazio');
    }
    var offset = 0;
    final layouts = <VisionPlaneLayout>[];
    for (final plane in frame.planes) {
      layouts.add(
        VisionPlaneLayout(
          offset: offset,
          length: plane.bytes.length,
          bytesPerRow: plane.bytesPerRow,
          bytesPerPixel: plane.bytesPerPixel,
        ),
      );
      offset += plane.bytes.length;
    }
    return TransferableVisionFrame._(
      width: frame.width,
      height: frame.height,
      formatIndex: frame.format.index,
      rotationIndex: frame.rotation.index,
      capturedAtMicrosecondsUtc: frame.capturedAt
          .toUtc()
          .microsecondsSinceEpoch,
      layouts: List<VisionPlaneLayout>.unmodifiable(layouts),
      bytes: TransferableTypedData.fromList(
        frame.planes.map((plane) => plane.bytes).toList(growable: false),
      ),
    );
  }

  final int width;
  final int height;
  final int formatIndex;
  final int rotationIndex;
  final int capturedAtMicrosecondsUtc;
  final List<VisionPlaneLayout> layouts;
  final TransferableTypedData bytes;

  VisionFrame materialize() {
    if (formatIndex < 0 || formatIndex >= VisionPixelFormat.values.length) {
      throw const FormatException('Formato de frame inválido.');
    }
    if (rotationIndex < 0 || rotationIndex >= VisionRotation.values.length) {
      throw const FormatException('Rotação de frame inválida.');
    }
    final buffer = bytes.materialize().asUint8List();
    final planes = layouts
        .map((layout) {
          final end = layout.offset + layout.length;
          if (layout.offset < 0 || end > buffer.length || end < layout.offset) {
            throw const FormatException('Layout de plano inválido.');
          }
          return VisionFramePlane(
            bytes: Uint8List.sublistView(buffer, layout.offset, end),
            bytesPerRow: layout.bytesPerRow,
            bytesPerPixel: layout.bytesPerPixel,
          );
        })
        .toList(growable: false);
    return VisionFrame(
      width: width,
      height: height,
      format: VisionPixelFormat.values[formatIndex],
      planes: planes,
      rotation: VisionRotation.values[rotationIndex],
      capturedAt: DateTime.fromMicrosecondsSinceEpoch(
        capturedAtMicrosecondsUtc,
        isUtc: true,
      ),
    );
  }
}

final class VisionWorkerReady {
  const VisionWorkerReady(this.commands);

  final SendPort commands;
}

final class VisionDetectCommand {
  const VisionDetectCommand({required this.requestId, required this.frame});

  final int requestId;
  final TransferableVisionFrame frame;
}

final class VisionDisposeCommand {
  const VisionDisposeCommand();
}

final class VisionDetectionSucceeded {
  const VisionDetectionSucceeded({
    required this.requestId,
    required this.result,
  });

  final int requestId;
  final DetectionBatch result;
}

final class VisionRequestFailed {
  const VisionRequestFailed({
    required this.requestId,
    required this.technicalCode,
    required this.message,
  });

  final int requestId;
  final String technicalCode;
  final String message;
}

final class VisionStartupFailed {
  const VisionStartupFailed({
    required this.technicalCode,
    required this.message,
  });

  final String technicalCode;
  final String message;
}

final class VisionWorkerFatalFailure {
  const VisionWorkerFatalFailure({
    required this.technicalCode,
    required this.message,
  });

  final String technicalCode;
  final String message;
}

final class VisionWorkerDisposed {
  const VisionWorkerDisposed();
}
