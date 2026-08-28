import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/recovery/accessible_recovery_panel.dart';
import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/core/recovery/recovery_content.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_binding.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_runtime_state.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:eyes_mobile/features/scanning/application/assistive_scan_coordinator.dart';
import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:eyes_mobile/features/scanning/application/scan_failure_policy.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_session_state.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/camera_preview_surface.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CameraDiagnosticsPage extends ConsumerStatefulWidget {
  const CameraDiagnosticsPage({super.key});

  @override
  ConsumerState<CameraDiagnosticsPage> createState() =>
      _CameraDiagnosticsPageState();
}

final class _CameraDiagnosticsPageState
    extends ConsumerState<CameraDiagnosticsPage>
    with WidgetsBindingObserver {
  late final AssistiveScanCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = ref.read(assistiveScanCoordinatorProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_coordinator.prepare());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_coordinator.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(_coordinator.handleBackground());
      case AppLifecycleState.resumed:
        unawaited(_coordinator.handleForeground());
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(assistiveFeedbackBindingProvider);
    final camera = ref.watch(scanControllerProvider);
    final vision = ref.watch(visionControllerProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen<AsyncValue<VisionRuntimeState>>(visionControllerProvider, (
      previous,
      next,
    ) {
      final wasReady =
          previous?.asData?.value.status == VisionRuntimeStatus.ready;
      final isReady = next.asData?.value.status == VisionRuntimeStatus.ready;
      final wasFailed = previous?.hasError ?? false;
      if (isReady && !wasReady) {
        unawaited(ref.read(accessibleFeedbackServiceProvider).confirm());
      } else if (next.hasError && !wasFailed) {
        unawaited(ref.read(accessibleFeedbackServiceProvider).warn());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cameraPageTitle),
        actions: [
          IconButton(
            tooltip: l10n.openFeedbackSettings,
            onPressed: () => context.pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: camera.when(
          data: (session) => _AssistiveScanContent(
            session: session,
            vision: vision,
            coordinator: _coordinator,
          ),
          error: (Object error, StackTrace stackTrace) =>
              _UnexpectedScanError(coordinator: _coordinator),
          loading: () => Center(
            child: Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}

final class _AssistiveScanContent extends ConsumerWidget {
  const _AssistiveScanContent({
    required this.session,
    required this.vision,
    required this.coordinator,
  });

  final CameraSessionState session;
  final AsyncValue<VisionRuntimeState> vision;
  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusText = _scanStatusText(l10n, session, vision);
    final blockingFailure = _blockingFailure(session, vision);
    final feedbackNotice = ref
        .watch(assistiveFeedbackControllerProvider)
        .asData
        ?.value
        .notice;
    final degradedFailure = _degradedFailure(feedbackNotice);
    final runtime = vision.asData?.value;
    final isVisionReady = runtime?.status == VisionRuntimeStatus.ready;
    final isActivelyScanning =
        isVisionReady && session.status == CameraScanStatus.streaming;
    final previewAspectRatio = session.previewAspectRatio;
    final latestAlert = isActivelyScanning
        ? ref.watch(proximityControllerProvider).lastAlert
        : null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.cameraPrivacyNotice,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                if (isActivelyScanning && previewAspectRatio != null) ...[
                  ExcludeSemantics(
                    child: CameraPreviewSurface(
                      aspectRatio: previewAspectRatio,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Card(
                  child: Semantics(
                    container: true,
                    liveRegion: blockingFailure == null,
                    excludeSemantics: true,
                    label: '${l10n.scanStatusLabel}: $statusText',
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.scanStatusLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusText,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (blockingFailure != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _RecoveryPanel(
                    failure: blockingFailure,
                    visionFailure: vision.hasError,
                    coordinator: coordinator,
                  ),
                ],
                if (blockingFailure == null &&
                    degradedFailure != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _RecoveryPanel(
                    failure: degradedFailure,
                    visionFailure: false,
                    coordinator: coordinator,
                  ),
                ],
                if (latestAlert != null) ...[
                  const SizedBox(height: 16),
                  _ProximityAnnouncement(event: latestAlert),
                ],
                const SizedBox(height: 24),
                if (blockingFailure == null)
                  _PrimaryScanAction(
                    session: session,
                    vision: vision,
                    coordinator: coordinator,
                  ),
                if (isActivelyScanning) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: coordinator.stop,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 56),
                    ),
                    child: Text(l10n.cameraStop),
                  ),
                ],
                if (kDebugMode && isActivelyScanning) ...<Widget>[
                  const SizedBox(height: 24),
                  _CameraTelemetryCard(session: session),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

OperationalFailure? _blockingFailure(
  CameraSessionState session,
  AsyncValue<VisionRuntimeState> vision,
) {
  if (vision.hasError) {
    return ScanFailurePolicy.fromVision(vision.error!);
  }
  final cameraFailure = session.failure;
  return cameraFailure == null
      ? null
      : ScanFailurePolicy.fromCamera(cameraFailure);
}

OperationalFailure? _degradedFailure(FeedbackNotice? notice) =>
    notice == null ? null : ScanFailurePolicy.fromFeedbackNotice(notice);

final class _RecoveryPanel extends ConsumerWidget {
  const _RecoveryPanel({
    required this.failure,
    required this.visionFailure,
    required this.coordinator,
  });

  final OperationalFailure failure;
  final bool visionFailure;
  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = RecoveryContentResolver.resolve(l10n, failure.kind);
    final secondary = failure.secondaryAction;
    return AccessibleRecoveryPanel(
      announcementKey: failure.kind,
      title: content.title,
      message: content.message,
      primaryActionLabel: RecoveryContentResolver.actionLabel(
        l10n,
        failure.primaryAction,
      ),
      onPrimaryAction: () => _execute(context, ref, failure.primaryAction),
      secondaryActionLabel: secondary == null
          ? null
          : RecoveryContentResolver.actionLabel(l10n, secondary),
      onSecondaryAction: secondary == null
          ? null
          : () => _execute(context, ref, secondary),
      blocking: failure.blocksAssistiveScan,
    );
  }

  void _execute(
    BuildContext context,
    WidgetRef ref,
    OperationalRecoveryAction action,
  ) {
    switch (action) {
      case OperationalRecoveryAction.retry:
        unawaited(
          visionFailure ? coordinator.retryVision() : coordinator.start(),
        );
        return;
      case OperationalRecoveryAction.openDeviceSettings:
        unawaited(ref.read(scanControllerProvider.notifier).openSettings());
        return;
      case OperationalRecoveryAction.openFeedbackSettings:
        unawaited(context.pushNamed(AppRoutes.settings));
        return;
      case OperationalRecoveryAction.continueOffline:
        return;
      case OperationalRecoveryAction.returnToSafety:
        unawaited(coordinator.stop());
        context.goNamed(AppRoutes.home);
        return;
    }
  }
}

final class _UnexpectedScanError extends ConsumerWidget {
  const _UnexpectedScanError({required this.coordinator});

  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _RecoveryPanel(
            failure: const OperationalFailure(
              kind: OperationalFailureKind.unexpected,
              impact: OperationalFailureImpact.blocking,
              primaryAction: OperationalRecoveryAction.retry,
              secondaryAction: OperationalRecoveryAction.returnToSafety,
            ),
            visionFailure: false,
            coordinator: coordinator,
          ),
        ),
      ),
    );
  }
}

final class _PrimaryScanAction extends ConsumerWidget {
  const _PrimaryScanAction({
    required this.session,
    required this.vision,
    required this.coordinator,
  });

  final CameraSessionState session;
  final AsyncValue<VisionRuntimeState> vision;
  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runtime = vision.asData?.value;

    if (vision.hasError) {
      return FilledButton.icon(
        onPressed: coordinator.retryVision,
        icon: const ExcludeSemantics(child: Icon(Icons.refresh_outlined)),
        label: Text(l10n.visionRetry),
      );
    }
    if (vision.isLoading || runtime?.status == VisionRuntimeStatus.recovering) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(l10n.visionPreparingAction),
      );
    }
    if (session.status == CameraScanStatus.permanentlyDenied) {
      return FilledButton.icon(
        onPressed: ref.read(scanControllerProvider.notifier).openSettings,
        icon: const ExcludeSemantics(child: Icon(Icons.settings_outlined)),
        label: Text(l10n.cameraOpenSettings),
      );
    }
    if (session.isOperationPending) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(l10n.cameraPreparing),
      );
    }
    if (session.status == CameraScanStatus.streaming) {
      return FilledButton.icon(
        onPressed: coordinator.pause,
        icon: const ExcludeSemantics(child: Icon(Icons.pause_outlined)),
        label: Text(l10n.cameraPause),
      );
    }
    if (session.status == CameraScanStatus.paused) {
      return FilledButton.icon(
        onPressed: coordinator.resume,
        icon: const ExcludeSemantics(child: Icon(Icons.play_arrow_outlined)),
        label: Text(l10n.cameraResume),
      );
    }
    if (session.status == CameraScanStatus.denied ||
        session.status == CameraScanStatus.busy ||
        session.status == CameraScanStatus.unavailable) {
      return FilledButton.icon(
        onPressed: coordinator.start,
        icon: const ExcludeSemantics(child: Icon(Icons.refresh_outlined)),
        label: Text(l10n.tryAgain),
      );
    }
    return FilledButton.icon(
      onPressed: runtime?.status == VisionRuntimeStatus.ready
          ? coordinator.start
          : null,
      icon: const ExcludeSemantics(child: Icon(Icons.camera_alt_outlined)),
      label: Text(l10n.cameraStart),
    );
  }
}

final class _ProximityAnnouncement extends ConsumerWidget {
  const _ProximityAnnouncement({required this.event});

  final ProximityAlertEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(assistiveFeedbackControllerProvider);
    final detail =
        settings.asData?.value.preferences.detailLevel ??
        FeedbackPreferences.defaults.detailLevel;
    final text = AssistiveAlertMessageComposer.compose(event, detail).text;
    return Semantics(
      container: true,
      // O TTS do produto anuncia o evento. Mantê-lo fora de uma live region
      // evita que o TalkBack fale a mesma frase simultaneamente.
      liveRegion: false,
      excludeSemantics: true,
      label: text,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}

final class _CameraTelemetryCard extends StatelessWidget {
  const _CameraTelemetryCard({required this.session});

  final CameraSessionState session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final telemetry = session.telemetry;
    return ExcludeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l10n.cameraTelemetry(
              telemetry.framesPerSecond.toStringAsFixed(1),
              telemetry.receivedFrames,
              telemetry.processedFrames,
              telemetry.droppedFrames,
              telemetry.lastProcessingTime.inMilliseconds,
            ),
          ),
        ),
      ),
    );
  }
}

String _scanStatusText(
  AppLocalizations l10n,
  CameraSessionState session,
  AsyncValue<VisionRuntimeState> vision,
) {
  if (vision.hasError) {
    return l10n.visionFailed;
  }
  if (vision.isLoading) {
    return l10n.visionPreparing;
  }
  final runtime = vision.requireValue;
  if (runtime.status == VisionRuntimeStatus.recovering) {
    return l10n.visionRecovering;
  }
  if (runtime.status == VisionRuntimeStatus.paused &&
      session.status != CameraScanStatus.paused) {
    return l10n.visionPaused;
  }
  if (runtime.status == VisionRuntimeStatus.ready &&
      session.status == CameraScanStatus.streaming) {
    return l10n.scanReady;
  }
  if (runtime.status == VisionRuntimeStatus.ready &&
      session.status == CameraScanStatus.idle) {
    return l10n.visionReady;
  }
  return _cameraStatusText(l10n, session.status);
}

String _cameraStatusText(AppLocalizations l10n, CameraScanStatus status) {
  return switch (status) {
    CameraScanStatus.idle => l10n.cameraStatusIdle,
    CameraScanStatus.requestingPermission =>
      l10n.cameraStatusRequestingPermission,
    CameraScanStatus.preparing => l10n.cameraStatusPreparing,
    CameraScanStatus.streaming => l10n.cameraStatusStreaming,
    CameraScanStatus.paused => l10n.cameraStatusPaused,
    CameraScanStatus.denied => l10n.cameraStatusDenied,
    CameraScanStatus.permanentlyDenied => l10n.cameraStatusPermanentlyDenied,
    CameraScanStatus.busy => l10n.cameraStatusBusy,
    CameraScanStatus.unavailable => l10n.cameraStatusUnavailable,
  };
}
