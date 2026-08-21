import 'dart:isolate';

import 'package:eyes_mobile/features/object_detection/infrastructure/model_asset_loader.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/tflite_lite_interpreter.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/tflite_object_detector.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_frame_preprocessor.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_worker_protocol.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
void runVisionIsolate(VisionWorkerBootstrap bootstrap) async {
  final commands = ReceivePort('eyes-vision-worker-commands');
  TfliteObjectDetector? detector;
  var ready = false;
  var disposedByCommand = false;
  Object? terminalFailure;

  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(
      bootstrap.rootIsolateToken,
    );
    final transferredAssets = bootstrap.modelAssets.materialize();
    final model = ModelAssetLoader().verify(
      manifestSource: transferredAssets.manifestSource,
      modelBytes: transferredAssets.modelBytes,
    );
    detector = TfliteObjectDetector(
      model: model,
      interpreterFactory: const TfliteLiteInterpreterFactory(),
    );
    ready = true;
    bootstrap.responses.send(VisionWorkerReady(commands.sendPort));

    await for (final Object? message in commands) {
      if (message is VisionDisposeCommand) {
        disposedByCommand = true;
        break;
      }
      if (message is! VisionDetectCommand) {
        continue;
      }

      try {
        final frame = message.frame.materialize();
        final result = await detector.detect(frame);
        bootstrap.responses.send(
          VisionDetectionSucceeded(
            requestId: message.requestId,
            result: result,
          ),
        );
      } on VisionPreprocessingException {
        bootstrap.responses.send(
          VisionRequestFailed(
            requestId: message.requestId,
            technicalCode: 'invalid-camera-frame',
            message: 'O frame recebido da câmera é inválido.',
          ),
        );
      } on Object catch (error) {
        terminalFailure = error;
        break;
      }
    }
  } on Object catch (error) {
    terminalFailure = error;
  } finally {
    commands.close();
    try {
      await detector?.close();
    } on Object catch (error) {
      terminalFailure ??= error;
    }

    if (disposedByCommand) {
      bootstrap.responses.send(const VisionWorkerDisposed());
    } else if (!ready) {
      bootstrap.responses.send(
        const VisionStartupFailed(
          technicalCode: 'vision-model-initialization-failed',
          message: 'Não foi possível inicializar o modelo local.',
        ),
      );
    } else if (terminalFailure != null) {
      bootstrap.responses.send(
        const VisionWorkerFatalFailure(
          technicalCode: 'vision-inference-runtime-failed',
          message: 'O mecanismo de visão computacional foi interrompido.',
        ),
      );
    }
  }
}
