import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';

abstract interface class ObjectDetectorGateway {
  Future<DetectionBatch> detect(VisionFrame frame);

  Future<void> close();
}
