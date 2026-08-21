import 'dart:async';
import 'dart:isolate';

import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_isolate_entrypoint.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_model_asset_source.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_worker_protocol.dart';
import 'package:flutter/services.dart';

final class IsolateVisionWorker implements VisionWorker {
  IsolateVisionWorker({
    this.entrypoint = runVisionIsolate,
    this.startTimeout = const Duration(seconds: 20),
    this.requestTimeout = const Duration(seconds: 5),
    this.disposeTimeout = const Duration(seconds: 3),
    this.modelAssetSource = const RootVisionModelAssetSource(),
  });

  final VisionWorkerEntrypoint entrypoint;
  final Duration startTimeout;
  final Duration requestTimeout;
  final Duration disposeTimeout;
  final VisionModelAssetSource modelAssetSource;

  final StreamController<VisionWorkerSnapshot> _snapshots =
      StreamController<VisionWorkerSnapshot>.broadcast(sync: true);
  final Map<int, Completer<DetectionBatch>> _requests = {};
  final Map<int, Timer> _requestTimers = {};

  VisionWorkerSnapshot _snapshot = const VisionWorkerSnapshot.idle();
  Isolate? _isolate;
  SendPort? _commands;
  ReceivePort? _responsesPort;
  ReceivePort? _errorsPort;
  ReceivePort? _exitPort;
  StreamSubscription<Object?>? _responsesSubscription;
  StreamSubscription<Object?>? _errorsSubscription;
  StreamSubscription<Object?>? _exitSubscription;
  Completer<void>? _startCompleter;
  Completer<void>? _disposeCompleter;
  Timer? _startTimer;
  Timer? _disposeTimer;
  int _requestSequence = 0;
  int _generation = 0;

  @override
  VisionWorkerSnapshot get snapshot => _snapshot;

  @override
  Stream<VisionWorkerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> start() async {
    switch (_snapshot.phase) {
      case VisionWorkerPhase.ready:
        return;
      case VisionWorkerPhase.starting:
        return _startCompleter!.future;
      case VisionWorkerPhase.disposing:
        await _disposeCompleter!.future;
      case VisionWorkerPhase.idle:
      case VisionWorkerPhase.failed:
        break;
    }

    _resetTransport(killIsolate: true);
    final token = RootIsolateToken.instance;
    if (token == null) {
      final failure = const VisionWorkerException(
        VisionWorkerFailureReason.initialization,
        'O isolate principal do Flutter não está disponível.',
        technicalCode: 'missing-root-isolate-token',
      );
      _setFailed(failure);
      throw failure;
    }

    final generation = ++_generation;
    final responses = ReceivePort('eyes-vision-responses');
    final errors = ReceivePort('eyes-vision-errors');
    final exits = ReceivePort('eyes-vision-exit');
    _responsesPort = responses;
    _errorsPort = errors;
    _exitPort = exits;
    _responsesSubscription = responses.listen(_handleResponse);
    _errorsSubscription = errors.listen(_handleIsolateError);
    _exitSubscription = exits.listen(_handleIsolateExit);
    final completer = Completer<void>();
    _startCompleter = completer;
    // The public async start future cannot observe this completer until asset
    // loading finishes. Attach an early listener so lifecycle cancellation
    // during that gap is never reported as an unhandled asynchronous error.
    unawaited(
      completer.future.then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {},
      ),
    );
    _setSnapshot(const VisionWorkerSnapshot(phase: VisionWorkerPhase.starting));
    _startTimer = Timer(startTimeout, () {
      _setFailed(
        const VisionWorkerException(
          VisionWorkerFailureReason.startupTimeout,
          'A inicialização da visão computacional excedeu o tempo limite.',
          technicalCode: 'vision-start-timeout',
        ),
      );
    });

    try {
      final modelAssets = await modelAssetSource.load();
      if (generation != _generation ||
          _snapshot.phase != VisionWorkerPhase.starting) {
        return completer.future;
      }
      final isolate = await Isolate.spawn<VisionWorkerBootstrap>(
        entrypoint,
        VisionWorkerBootstrap(
          responses: responses.sendPort,
          rootIsolateToken: token,
          modelAssets: modelAssets,
        ),
        onError: errors.sendPort,
        onExit: exits.sendPort,
        errorsAreFatal: true,
        debugName: 'eyes-vision-worker',
      );
      if (generation != _generation ||
          _snapshot.phase == VisionWorkerPhase.failed) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        _isolate = isolate;
      }
    } on Object {
      _setFailed(
        const VisionWorkerException(
          VisionWorkerFailureReason.initialization,
          'Não foi possível criar o isolate de visão computacional.',
          technicalCode: 'vision-isolate-spawn-failed',
        ),
      );
    }

    return completer.future;
  }

  @override
  Future<DetectionBatch> detect(VisionFrame frame) {
    if (_snapshot.phase != VisionWorkerPhase.ready || _commands == null) {
      throw const VisionWorkerException(
        VisionWorkerFailureReason.notReady,
        'A visão computacional ainda não está pronta.',
        technicalCode: 'vision-worker-not-ready',
      );
    }
    if (_requests.isNotEmpty) {
      throw const VisionWorkerException(
        VisionWorkerFailureReason.busy,
        'Já existe um frame em processamento.',
        technicalCode: 'vision-worker-busy',
      );
    }

    final requestId = ++_requestSequence;
    final completer = Completer<DetectionBatch>();
    _requests[requestId] = completer;
    _requestTimers[requestId] = Timer(requestTimeout, () {
      _setFailed(
        const VisionWorkerException(
          VisionWorkerFailureReason.requestTimeout,
          'A inferência local excedeu o tempo limite.',
          technicalCode: 'vision-request-timeout',
        ),
      );
    });

    try {
      _commands!.send(
        VisionDetectCommand(
          requestId: requestId,
          frame: TransferableVisionFrame.fromFrame(frame),
        ),
      );
    } on Object {
      _completeRequestWithError(
        requestId,
        const VisionWorkerException(
          VisionWorkerFailureReason.invalidFrame,
          'O frame não pôde ser transferido para processamento.',
          technicalCode: 'vision-frame-transfer-failed',
        ),
      );
    }
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    if (_snapshot.phase == VisionWorkerPhase.idle) {
      return;
    }
    if (_snapshot.phase == VisionWorkerPhase.disposing) {
      return _disposeCompleter!.future;
    }

    final completer = Completer<void>();
    _disposeCompleter = completer;
    _startTimer?.cancel();
    _startTimer = null;
    _completeStartWithError(
      const VisionWorkerException(
        VisionWorkerFailureReason.notReady,
        'A inicialização foi cancelada pelo ciclo de vida.',
        technicalCode: 'vision-start-cancelled',
      ),
    );
    _setSnapshot(
      const VisionWorkerSnapshot(phase: VisionWorkerPhase.disposing),
    );

    final commands = _commands;
    if (commands == null) {
      _finishDispose(killIsolate: true);
      return completer.future;
    }
    commands.send(const VisionDisposeCommand());
    _disposeTimer = Timer(disposeTimeout, () {
      final failure = const VisionWorkerException(
        VisionWorkerFailureReason.disposeTimeout,
        'O encerramento da visão computacional excedeu o tempo limite.',
        technicalCode: 'vision-dispose-timeout',
      );
      _setFailed(failure);
      if (!completer.isCompleted) {
        completer.completeError(failure, StackTrace.current);
      }
    });
    return completer.future;
  }

  void _handleResponse(Object? message) {
    switch (message) {
      case VisionWorkerReady(:final commands):
        if (_snapshot.phase != VisionWorkerPhase.starting) {
          commands.send(const VisionDisposeCommand());
          return;
        }
        _commands = commands;
        _startTimer?.cancel();
        _startTimer = null;
        _setSnapshot(
          const VisionWorkerSnapshot(phase: VisionWorkerPhase.ready),
        );
        final completer = _startCompleter;
        _startCompleter = null;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      case VisionDetectionSucceeded(:final requestId, :final result):
        final completer = _removeRequest(requestId);
        if (completer != null && !completer.isCompleted) {
          completer.complete(result);
        }
      case VisionRequestFailed(
        :final requestId,
        :final technicalCode,
        :final message,
      ):
        _completeRequestWithError(
          requestId,
          VisionWorkerException(
            VisionWorkerFailureReason.invalidFrame,
            message,
            technicalCode: technicalCode,
          ),
        );
      case VisionStartupFailed(:final technicalCode, :final message):
        _setFailed(
          VisionWorkerException(
            VisionWorkerFailureReason.initialization,
            message,
            technicalCode: technicalCode,
          ),
        );
      case VisionWorkerFatalFailure(:final technicalCode, :final message):
        _setFailed(
          VisionWorkerException(
            VisionWorkerFailureReason.inference,
            message,
            technicalCode: technicalCode,
          ),
        );
      case VisionWorkerDisposed():
        _finishDispose();
      case null:
        break;
      default:
        _setFailed(
          const VisionWorkerException(
            VisionWorkerFailureReason.isolateCrashed,
            'O isolate retornou uma mensagem desconhecida.',
            technicalCode: 'vision-protocol-invalid-message',
          ),
        );
    }
  }

  void _handleIsolateError(Object? payload) {
    _setFailed(
      const VisionWorkerException(
        VisionWorkerFailureReason.isolateCrashed,
        'O isolate de visão computacional foi interrompido.',
        technicalCode: 'vision-isolate-uncaught-error',
      ),
    );
  }

  void _handleIsolateExit(Object? payload) {
    if (_snapshot.phase == VisionWorkerPhase.disposing) {
      _finishDispose();
      return;
    }
    if (_snapshot.phase == VisionWorkerPhase.idle ||
        _snapshot.phase == VisionWorkerPhase.failed) {
      return;
    }
    _setFailed(
      const VisionWorkerException(
        VisionWorkerFailureReason.isolateCrashed,
        'O isolate de visão computacional encerrou inesperadamente.',
        technicalCode: 'vision-isolate-unexpected-exit',
      ),
    );
  }

  void _setFailed(VisionWorkerException failure) {
    if (_snapshot.phase == VisionWorkerPhase.failed) {
      return;
    }
    _startTimer?.cancel();
    _startTimer = null;
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _completeStartWithError(failure);
    _completeAllRequestsWithError(failure);
    final disposeCompleter = _disposeCompleter;
    _disposeCompleter = null;
    if (disposeCompleter != null && !disposeCompleter.isCompleted) {
      disposeCompleter.completeError(failure, StackTrace.current);
    }
    _setSnapshot(
      VisionWorkerSnapshot(phase: VisionWorkerPhase.failed, failure: failure),
    );
    _resetTransport(killIsolate: true);
  }

  void _finishDispose({bool killIsolate = false}) {
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _completeAllRequestsWithError(
      const VisionWorkerException(
        VisionWorkerFailureReason.notReady,
        'O worker foi encerrado durante o processamento.',
        technicalCode: 'vision-worker-disposed',
      ),
    );
    final completer = _disposeCompleter;
    _disposeCompleter = null;
    _resetTransport(killIsolate: killIsolate);
    _setSnapshot(const VisionWorkerSnapshot.idle());
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _completeStartWithError(VisionWorkerException failure) {
    final completer = _startCompleter;
    _startCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(failure, StackTrace.current);
    }
  }

  Completer<DetectionBatch>? _removeRequest(int requestId) {
    _requestTimers.remove(requestId)?.cancel();
    return _requests.remove(requestId);
  }

  void _completeRequestWithError(int requestId, VisionWorkerException failure) {
    final completer = _removeRequest(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(failure, StackTrace.current);
    }
  }

  void _completeAllRequestsWithError(VisionWorkerException failure) {
    for (final timer in _requestTimers.values) {
      timer.cancel();
    }
    _requestTimers.clear();
    final requests = _requests.values.toList(growable: false);
    _requests.clear();
    for (final completer in requests) {
      if (!completer.isCompleted) {
        completer.completeError(failure, StackTrace.current);
      }
    }
  }

  void _resetTransport({required bool killIsolate}) {
    _generation++;
    if (killIsolate) {
      _isolate?.kill(priority: Isolate.immediate);
    }
    _isolate = null;
    _commands = null;
    _responsesPort?.close();
    _errorsPort?.close();
    _exitPort?.close();
    _responsesPort = null;
    _errorsPort = null;
    _exitPort = null;
    unawaited(_responsesSubscription?.cancel());
    unawaited(_errorsSubscription?.cancel());
    unawaited(_exitSubscription?.cancel());
    _responsesSubscription = null;
    _errorsSubscription = null;
    _exitSubscription = null;
  }

  void _setSnapshot(VisionWorkerSnapshot value) {
    _snapshot = value;
    if (!_snapshots.isClosed) {
      _snapshots.add(value);
    }
  }
}
