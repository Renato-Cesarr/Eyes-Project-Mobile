import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
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

    return EyesPageScaffold(
      title: l10n.cameraPageTitle,
      adaptiveTitle: true,
      scrollable: false,
      contentPadding: EdgeInsets.zero,
      maxContentWidth: double.infinity,
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
    final feedback = feedbackState.asData?.value;
    final degradedFailure = _degradedFailure(feedback);
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

    if (blockingFailure != null) {
      return _BlockingRecoveryView(
        failure: blockingFailure,
        visionFailure: vision.hasError,
        phase: operationalStatus.phase,
        statusText: statusText,
        coordinator: coordinator,
      );
    }

    return _CameraFirstScanView(
      phase: operationalStatus.phase,
      statusText: statusText,
      isActivelyScanning: isActivelyScanning,
      previewAspectRatio: previewAspectRatio,
      latestAlert: latestAlert,
      degradedFailure: degradedFailure,
      canEndSession: canEndSession,
      coordinator: coordinator,
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

OperationalFailure? _degradedFailure(AssistiveFeedbackState? feedback) {
  if (feedback == null) {
    return null;
  }
  if (feedback.speechAvailability == FeedbackChannelAvailability.unavailable) {
    return ScanFailurePolicy.fromFeedbackNotice(
      FeedbackNotice.speechUnavailable,
    );
  }
  if (feedback.preferences.hapticsEnabled &&
      feedback.hapticsAvailability == FeedbackChannelAvailability.unavailable) {
    return ScanFailurePolicy.fromFeedbackNotice(
      FeedbackNotice.hapticsUnavailable,
    );
  }
  return ScanFailurePolicy.fromFeedbackNotice(feedback.notice);
}

final class _CameraFirstScanView extends StatelessWidget {
  const _CameraFirstScanView({
    required this.phase,
    required this.statusText,
    required this.isActivelyScanning,
    required this.previewAspectRatio,
    required this.latestAlert,
    required this.degradedFailure,
    required this.canEndSession,
    required this.coordinator,
  });

  final AssistiveScanPhase phase;
  final String statusText;
  final bool isActivelyScanning;
  final double? previewAspectRatio;
  final ProximityAlertEvent? latestAlert;
  final OperationalFailure? degradedFailure;
  final bool canEndSession;
  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    final viewport = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final needsScrollableOverlay = textScale > 1.4 || viewport.height < 700;
    final status = _OperationalStatusOverlay(
      phase: phase,
      statusText: statusText,
    );
    final tail = <Widget>[
      if (latestAlert != null) ...<Widget>[
        _ProximityAnnouncement(event: latestAlert!),
        SizedBox(height: layout.spaceMd),
      ],
      if (degradedFailure != null) ...<Widget>[
        _DegradedRecoveryBanner(failure: degradedFailure!),
        SizedBox(height: layout.spaceMd),
      ],
      _ScanControlDock(
        phase: phase,
        isActivelyScanning: isActivelyScanning,
        canEndSession: canEndSession,
        coordinator: coordinator,
      ),
    ];
    return Stack(
      key: const ValueKey<String>('assistive-scan-stage'),
      fit: StackFit.expand,
      children: <Widget>[
        _ScanStageSurface(
          phase: phase,
          isActivelyScanning: isActivelyScanning,
          previewAspectRatio: previewAspectRatio,
        ),
        const IgnorePointer(child: _ScanStageScrim()),
        SafeArea(
          child: needsScrollableOverlay
              ? SingleChildScrollView(
                  padding: EdgeInsets.all(layout.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      status,
                      SizedBox(
                        height: (viewport.height * 0.16)
                            .clamp(layout.spaceXl, 144)
                            .toDouble(),
                      ),
                      ...tail,
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(layout.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[status, const Spacer(), ...tail],
                  ),
                ),
        ),
      ],
    );
  }
}

final class _ScanStageSurface extends StatelessWidget {
  const _ScanStageSurface({
    required this.phase,
    required this.isActivelyScanning,
    required this.previewAspectRatio,
  });

  final AssistiveScanPhase phase;
  final bool isActivelyScanning;
  final double? previewAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (isActivelyScanning && previewAspectRatio != null) {
      return CameraPreviewSurface(
        aspectRatio: previewAspectRatio!,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.zero,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              scheme.primaryContainer,
              scheme.surface,
              scheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            _phaseIcon(phase),
            size: 112,
            color: scheme.primary.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

final class _ScanStageScrim extends StatelessWidget {
  const _ScanStageScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const <double>[0, 0.28, 0.58, 1],
          colors: <Color>[
            Colors.black.withValues(alpha: 0.54),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.72),
          ],
        ),
      ),
    );
  }
}

final class _OperationalStatusOverlay extends StatelessWidget {
  const _OperationalStatusOverlay({
    required this.phase,
    required this.statusText,
  });

  final AssistiveScanPhase phase;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layout = context.eyesLayout;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.readingMaxWidth),
        child: Semantics(
          key: ValueKey<AssistiveScanPhase>(phase),
          container: true,
          liveRegion: true,
          label: '${l10n.scanStatusLabel}: $statusText',
          excludeSemantics: true,
          child: Material(
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: scheme.outline),
              borderRadius: BorderRadius.circular(layout.radiusLg),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout.spaceLg,
                vertical: layout.spaceMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(_phaseIcon(phase), color: scheme.primary, size: 28),
                  SizedBox(width: layout.spaceMd),
                  Expanded(
                    child: Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(width: layout.spaceSm),
                  Icon(
                    Icons.offline_bolt_outlined,
                    color: context.eyesColors.success,
                    semanticLabel: l10n.scanOfflineAvailable,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _DegradedRecoveryBanner extends StatelessWidget {
  const _DegradedRecoveryBanner({required this.failure});

  final OperationalFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layout = context.eyesLayout;
    final content = RecoveryContentResolver.resolve(l10n, failure.kind);
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.readingMaxWidth),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(layout.radiusLg),
          child: Padding(
            padding: EdgeInsets.all(layout.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                EyesStatusBanner(
                  title: content.title,
                  message: content.message,
                  tone: EyesStatusTone.warning,
                  liveRegion: true,
                ),
                SizedBox(height: layout.spaceSm),
                EyesButton(
                  label: RecoveryContentResolver.actionLabel(
                    l10n,
                    failure.primaryAction,
                  ),
                  onPressed: () =>
                      unawaited(context.pushNamed(AppRoutes.settings)),
                  variant: EyesButtonVariant.text,
                  icon: Icons.tune_outlined,
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ScanControlDock extends StatelessWidget {
  const _ScanControlDock({
    required this.phase,
    required this.isActivelyScanning,
    required this.canEndSession,
    required this.coordinator,
  });

  final AssistiveScanPhase phase;
  final bool isActivelyScanning;
  final bool canEndSession;
  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        key: const ValueKey<String>('scan-control-dock'),
        constraints: BoxConstraints(maxWidth: layout.readingMaxWidth),
        child: Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: scheme.outline),
            borderRadius: BorderRadius.circular(layout.radiusLg),
          ),
          child: Padding(
            padding: EdgeInsets.all(layout.spaceMd),
            child: _ControlDockContent(
              phase: phase,
              isActivelyScanning: isActivelyScanning,
              canEndSession: canEndSession,
              coordinator: coordinator,
            ),
          ),
        ),
      ),
    );
  }
}

final class _ControlDockContent extends StatelessWidget {
  const _ControlDockContent({
    required this.phase,
    required this.isActivelyScanning,
    required this.canEndSession,
    required this.coordinator,
  });

  final AssistiveScanPhase phase;
  final bool isActivelyScanning;
  final bool canEndSession;
  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layout = context.eyesLayout;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final availableWidth =
        MediaQuery.sizeOf(context).width -
        (layout.spaceLg * 2) -
        (layout.spaceMd * 2);
    final vertical = textScale > 1.4 || availableWidth < 440;
    final primary = _PrimaryScanAction(
      phase: phase,
      coordinator: coordinator,
      expand: vertical || !canEndSession,
    );
    final stop = EyesButton(
      label: l10n.scanStop,
      semanticHint: l10n.scanStopHint,
      onPressed: () => unawaited(_confirmStop(context, coordinator)),
      variant: EyesButtonVariant.outlined,
      icon: Icons.stop_circle_outlined,
      expand: vertical,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (canEndSession)
          Flex(
            direction: vertical ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: vertical
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.start,
            children: <Widget>[
              if (vertical) primary else Expanded(child: primary),
              SizedBox(
                width: vertical ? 0 : layout.spaceSm,
                height: vertical ? layout.spaceSm : 0,
              ),
              if (vertical) stop else Expanded(child: stop),
            ],
          )
        else
          primary,
        if (isActivelyScanning) ...<Widget>[
          SizedBox(height: layout.spaceSm),
          Text(
            l10n.cameraPrivacyNotice,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

final class _BlockingRecoveryView extends StatelessWidget {
  const _BlockingRecoveryView({
    required this.failure,
    required this.visionFailure,
    required this.phase,
    required this.statusText,
    required this.coordinator,
  });

  final OperationalFailure failure;
  final bool visionFailure;
  final AssistiveScanPhase phase;
  final String statusText;
  final AssistiveScanCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: layout.pagePaddingFor(MediaQuery.sizeOf(context).width),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layout.readingMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!visionFailure) ...<Widget>[
                  _OperationalStatusOverlay(
                    phase: phase,
                    statusText: statusText,
                  ),
                  SizedBox(height: layout.spaceLg),
                ],
                Semantics(
                  container: visionFailure,
                  label: visionFailure
                      ? '${l10n.scanStatusLabel}: $statusText'
                      : null,
                  child: _RecoveryPanel(
                    failure: failure,
                    visionFailure: visionFailure,
                    coordinator: coordinator,
                  ),
                ),
              ],
            ),
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
  const _PrimaryScanAction({
    required this.phase,
    required this.coordinator,
    required this.expand,
  });

  final AssistiveScanPhase phase;
  final AssistiveScanCoordinator coordinator;
  final bool expand;

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
      child: EyesButton(
        label: action.label,
        semanticHint: action.hint,
        onPressed: action.onPressed,
        icon: action.icon,
        loading: action.isPending,
        expand: widget.expand,
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
    final layout = context.eyesLayout;
    final scheme = Theme.of(context).colorScheme;
    final isCritical = event.band == ProximityBand.veryNear;
    final background = isCritical ? scheme.error : context.eyesColors.warning;
    final foreground = isCritical
        ? scheme.onError
        : context.eyesColors.onWarning;
    return Semantics(
      container: true,
      // O TTS do produto anuncia o evento. Mantê-lo fora de uma live region
      // evita que o TalkBack fale a mesma frase simultaneamente.
      liveRegion: false,
      excludeSemantics: true,
      label: text,
      child: Material(
        color: background,
        elevation: 6,
        shadowColor: Colors.black87,
        borderRadius: BorderRadius.circular(layout.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(layout.spaceLg),
          child: Row(
            children: <Widget>[
              Icon(
                _directionIcon(event.direction),
                color: foreground,
                size: 36,
              ),
              SizedBox(width: layout.spaceMd),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _directionIcon(ProximityDirection direction) => switch (direction) {
  ProximityDirection.left => Icons.arrow_back_rounded,
  ProximityDirection.ahead => Icons.arrow_upward_rounded,
  ProximityDirection.right => Icons.arrow_forward_rounded,
};

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
