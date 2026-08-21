enum DetectedObjectKind { person, chair, table, backpack }

final class NormalizedBoundingBox {
  NormalizedBoundingBox({
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  }) {
    final coordinates = [top, left, bottom, right];
    if (coordinates.any((coordinate) => !coordinate.isFinite)) {
      throw ArgumentError.value(
        coordinates,
        'coordinates',
        'devem ser finitas',
      );
    }
    if (coordinates.any((coordinate) => coordinate < 0 || coordinate > 1)) {
      throw RangeError.range(
        coordinates.firstWhere(
          (coordinate) => coordinate < 0 || coordinate > 1,
        ),
        0,
        1,
        'coordinate',
      );
    }
    if (bottom <= top || right <= left) {
      throw ArgumentError.value(
        coordinates,
        'coordinates',
        'devem delimitar uma área positiva',
      );
    }
  }

  final double top;
  final double left;
  final double bottom;
  final double right;
}

final class DetectedObject {
  DetectedObject({
    required this.kind,
    required this.confidence,
    required this.boundingBox,
  }) {
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw RangeError.range(confidence, 0, 1, 'confidence');
    }
  }

  final DetectedObjectKind kind;
  final double confidence;
  final NormalizedBoundingBox boundingBox;
}

final class DetectionTimings {
  const DetectionTimings({
    required this.preprocessing,
    required this.inference,
    required this.postprocessing,
  });

  final Duration preprocessing;
  final Duration inference;
  final Duration postprocessing;

  Duration get total => preprocessing + inference + postprocessing;
}

final class DetectionBatch {
  DetectionBatch({
    required List<DetectedObject> detections,
    required this.capturedAt,
    required this.timings,
  }) : detections = List<DetectedObject>.unmodifiable(detections);

  final List<DetectedObject> detections;
  final DateTime capturedAt;
  final DetectionTimings timings;
}
