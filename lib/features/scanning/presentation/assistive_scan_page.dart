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
import 'package:eyes_mobile/features/scanning/application/assistive_scan_status.dart';
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

final class AssistiveScanPage extends ConsumerStatefulWidget {
  const AssistiveScanPage({super.key});

  @override
  ConsumerState<AssistiveScanPage> createState() => _AssistiveScanPageState();
}

final class _AssistiveScanPageState extends ConsumerState<AssistiveScanPage>
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
    unawaited(_coordinator.stop(announce: false));
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
        title: Text(l10n.assistiveScanTitle),
        actions: [
          IconButton(
            tooltip: l10n.openHelpAndSafety,
            onPressed: () => unawaited(context.pushNamed(AppRoutes.help)),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: l10n.openFeedbackSettings,
            onPressed: () => unawaited(context.pushNamed(AppRoutes.settings)),
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
    final operationalStatus = AssistiveScanStatus.resolve(session, vision);
    final statusText = _scanStatusText(
      l10n,
      operationalStatus.phase,
      session,
      vision,
    );
    final blockingFailure = _blockingFailure(session, vision);
    final feedbackState = ref.watch(assistiveFeedbackControllerProvider);
    final feedbackNotice = feedbackState.asData?.value.notice;
    final preferences =
        feedbackState.asData?.value.preferences ?? FeedbackPreferences.defaults;
    final degradedFailure = _degradedFailure(feedbackNotice);
    final runtime = vision.asData?.value;
    final isVisionReady = runtime?.status == VisionRuntimeStatus.ready;
    final isActivelyScanning = operationalStatus.isScanning && isVisionReady;
    final canEndSession =
        operationalStatus.phase == AssistiveScanPhase.scanning ||
        operationalStatus.phase == AssistiveScanPhase.paused;
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
                _CapabilityOverview(
                  preferences: preferences,
                  notice: feedbackNotice,
                ),
                const SizedBox(height: 16),
                _OperationalStatusCard(
                  phase: operationalStatus.phase,
                  statusText: statusText,
                  announce: blockingFailure == null,
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
                    phase: operationalStatus.phase,
                    coordinator: coordinator,
                  ),
                if (canEndSession) ...<Widget>[
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: l10n.scanStop,
                    hint: l10n.scanStopHint,
                    excludeSemantics: true,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          unawaited(_confirmStop(context, coordinator)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 56),
                      ),
                      icon: const ExcludeSemantics(
                        child: Icon(Icons.stop_circle_outlined),
                      ),
                      label: Text(l10n.scanStop),
                    ),
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

final class _CapabilityOverview extends StatelessWidget {
  const _CapabilityOverview({required this.preferences, required this.notice});

  final FeedbackPreferences preferences;
  final FeedbackNotice? notice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final speechAvailable = notice != FeedbackNotice.speechUnavailable;
    final hapticsAvailable = notice != FeedbackNotice.hapticsUnavailable;
    final hapticsLabel = !preferences.hapticsEnabled
        ? l10n.scanHapticsDisabled
        : hapticsAvailable
        ? l10n.scanHapticsAvailable
        : l10n.scanHapticsUnavailable;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                l10n.scanCapabilitiesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: <Widget>[
                _CapabilityItem(
                  icon: speechAvailable
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  label: speechAvailable
                      ? l10n.scanAudioAvailable
                      : l10n.scanAudioUnavailable,
                ),
                _CapabilityItem(
                  icon: preferences.hapticsEnabled && hapticsAvailable
                      ? Icons.vibration_outlined
                      : Icons.phone_android_outlined,
                  label: hapticsLabel,
                ),
                _CapabilityItem(
                  icon: Icons.offline_bolt_outlined,
                  label: l10n.scanOfflineAvailable,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _CapabilityItem extends StatelessWidget {
  const _CapabilityItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 8),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}

final class _OperationalStatusCard extends StatelessWidget {
  const _OperationalStatusCard({
    required this.phase,
    required this.statusText,
    required this.announce,
  });

  final AssistiveScanPhase phase;
  final String statusText;
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Semantics(
        key: ValueKey<AssistiveScanPhase>(phase),
        container: true,
        liveRegion: announce,
        label: '${l10n.scanStatusLabel}: $statusText',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(child: Icon(_phaseIcon(phase), size: 32)),
              const SizedBox(width: 16),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}

IconData _phaseIcon(AssistiveScanPhase phase) => switch (phase) {
  AssistiveScanPhase.loadingModel ||
  AssistiveScanPhase.requestingPermission ||
  AssistiveScanPhase.preparingCamera => Icons.hourglass_top_outlined,
  AssistiveScanPhase.ready => Icons.play_circle_outline,
  AssistiveScanPhase.scanning => Icons.radar_outlined,
  AssistiveScanPhase.paused => Icons.pause_circle_outline,
  AssistiveScanPhase.ended => Icons.stop_circle_outlined,
  AssistiveScanPhase.unavailable => Icons.error_outline,
};

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

final class _PrimaryScanAction extends StatefulWidget {
  const _PrimaryScanAction({required this.phase, required this.coordinator});

  final AssistiveScanPhase phase;
  final AssistiveScanCoordinator coordinator;

  @override
  State<_PrimaryScanAction> createState() => _PrimaryScanActionState();
}

final class _PrimaryScanActionState extends State<_PrimaryScanAction> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'primary-scan-action');

  @override
  void didUpdateWidget(covariant _PrimaryScanAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase &&
        !AssistiveScanStatus(widget.phase).isPending &&
        widget.phase != AssistiveScanPhase.unavailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final action = _primaryAction(l10n, widget.phase, widget.coordinator);
    return Focus(
      focusNode: _focusNode,
      child: Semantics(
        button: true,
        enabled: action.onPressed != null,
        label: action.label,
        hint: action.hint,
        excludeSemantics: true,
        child: FilledButton.icon(
          onPressed: action.onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
          ),
          icon: ExcludeSemantics(
            child: action.isPending
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(action.icon),
          ),
          label: Text(action.label),
        ),
      ),
    );
  }
}

typedef _PrimaryAction = ({
  String label,
  String hint,
  IconData icon,
  VoidCallback? onPressed,
  bool isPending,
});

_PrimaryAction _primaryAction(
  AppLocalizations l10n,
  AssistiveScanPhase phase,
  AssistiveScanCoordinator coordinator,
) => switch (phase) {
  AssistiveScanPhase.ready || AssistiveScanPhase.ended => (
    label: l10n.scanStart,
    hint: l10n.scanStartHint,
    icon: Icons.play_arrow_outlined,
    onPressed: coordinator.start,
    isPending: false,
  ),
  AssistiveScanPhase.scanning => (
    label: l10n.scanPause,
    hint: l10n.scanPauseHint,
    icon: Icons.pause_outlined,
    onPressed: coordinator.pause,
    isPending: false,
  ),
  AssistiveScanPhase.paused => (
    label: l10n.scanResume,
    hint: l10n.scanResumeHint,
    icon: Icons.play_arrow_outlined,
    onPressed: coordinator.resume,
    isPending: false,
  ),
  AssistiveScanPhase.loadingModel => (
    label: l10n.visionPreparingAction,
    hint: l10n.scanPreparingHint,
    icon: Icons.hourglass_top_outlined,
    onPressed: null,
    isPending: true,
  ),
  AssistiveScanPhase.requestingPermission ||
  AssistiveScanPhase.preparingCamera => (
    label: l10n.cameraPreparing,
    hint: l10n.scanPreparingHint,
    icon: Icons.hourglass_top_outlined,
    onPressed: null,
    isPending: true,
  ),
  AssistiveScanPhase.unavailable => (
    label: l10n.tryAgain,
    hint: l10n.scanPreparingHint,
    icon: Icons.refresh_outlined,
    onPressed: null,
    isPending: false,
  ),
};

Future<void> _confirmStop(
  BuildContext context,
  AssistiveScanCoordinator coordinator,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(l10n.scanStopDialogTitle),
      content: Text(l10n.scanStopDialogMessage),
      actions: <Widget>[
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.scanKeepRunning),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.scanConfirmStop),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await coordinator.stop();
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
  AssistiveScanPhase phase,
  CameraSessionState session,
  AsyncValue<VisionRuntimeState> vision,
) => switch (phase) {
  AssistiveScanPhase.loadingModel =>
    vision.isLoading ? l10n.visionPreparing : l10n.visionRecovering,
  AssistiveScanPhase.ready => l10n.visionReady,
  AssistiveScanPhase.requestingPermission =>
    l10n.cameraStatusRequestingPermission,
  AssistiveScanPhase.preparingCamera => l10n.cameraStatusPreparing,
  AssistiveScanPhase.scanning => l10n.scanReady,
  AssistiveScanPhase.paused => l10n.cameraStatusPaused,
  AssistiveScanPhase.ended => l10n.scanEnded,
  AssistiveScanPhase.unavailable =>
    vision.hasError
        ? l10n.visionFailed
        : _cameraStatusText(l10n, session.status),
};

String _cameraStatusText(AppLocalizations l10n, CameraScanStatus status) {
  return switch (status) {
    CameraScanStatus.idle => l10n.cameraStatusIdle,
    CameraScanStatus.requestingPermission =>
      l10n.cameraStatusRequestingPermission,
    CameraScanStatus.preparing => l10n.cameraStatusPreparing,
    CameraScanStatus.streaming => l10n.cameraStatusStreaming,
    CameraScanStatus.paused => l10n.cameraStatusPaused,
    CameraScanStatus.ended => l10n.scanEnded,
    CameraScanStatus.denied => l10n.cameraStatusDenied,
    CameraScanStatus.permanentlyDenied => l10n.cameraStatusPermanentlyDenied,
    CameraScanStatus.busy => l10n.cameraStatusBusy,
    CameraScanStatus.unavailable => l10n.cameraStatusUnavailable,
  };
}
