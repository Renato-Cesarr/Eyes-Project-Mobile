import 'dart:async';

import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_failure.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_session_state.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/camera_preview_surface.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CameraDiagnosticsPage extends ConsumerStatefulWidget {
  const CameraDiagnosticsPage({super.key});

  @override
  ConsumerState<CameraDiagnosticsPage> createState() =>
      _CameraDiagnosticsPageState();
}

final class _CameraDiagnosticsPageState
    extends ConsumerState<CameraDiagnosticsPage>
    with WidgetsBindingObserver {
  late final ScanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(scanControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(_controller.handleBackground());
      case AppLifecycleState.resumed:
        unawaited(_controller.handleForeground());
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cameraPageTitle)),
      body: SafeArea(
        child: state.when(
          data: (CameraSessionState session) =>
              _CameraContent(session: session),
          error: (Object error, StackTrace stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.cameraUnexpectedError),
            ),
          ),
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

final class _CameraContent extends ConsumerWidget {
  const _CameraContent({required this.session});

  final CameraSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusText = _statusText(l10n, session.status);
    final failureText = _failureText(l10n, session.failure);
    final previewAspectRatio = session.previewAspectRatio;

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
                if (session.status == CameraScanStatus.streaming &&
                    previewAspectRatio != null) ...[
                  CameraPreviewSurface(aspectRatio: previewAspectRatio),
                  const SizedBox(height: 20),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      label: '${l10n.cameraStatusLabel}: $statusText',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.cameraStatusLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusText,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (failureText != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              failureText,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _PrimaryCameraAction(session: session),
                if (session.status == CameraScanStatus.streaming) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(scanControllerProvider.notifier).stop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 56),
                    ),
                    child: Text(l10n.cameraStop),
                  ),
                ],
                if (kDebugMode &&
                    session.status == CameraScanStatus.streaming) ...<Widget>[
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

final class _PrimaryCameraAction extends ConsumerWidget {
  const _PrimaryCameraAction({required this.session});

  final CameraSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(scanControllerProvider.notifier);

    if (session.status == CameraScanStatus.permanentlyDenied) {
      return FilledButton.icon(
        onPressed: controller.openSettings,
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
        onPressed: controller.pause,
        icon: const ExcludeSemantics(child: Icon(Icons.pause_outlined)),
        label: Text(l10n.cameraPause),
      );
    }
    if (session.status == CameraScanStatus.paused) {
      return FilledButton.icon(
        onPressed: controller.resume,
        icon: const ExcludeSemantics(child: Icon(Icons.play_arrow_outlined)),
        label: Text(l10n.cameraResume),
      );
    }
    if (session.status == CameraScanStatus.denied ||
        session.status == CameraScanStatus.busy ||
        session.status == CameraScanStatus.unavailable) {
      return FilledButton.icon(
        onPressed: controller.retry,
        icon: const ExcludeSemantics(child: Icon(Icons.refresh_outlined)),
        label: Text(l10n.tryAgain),
      );
    }
    return FilledButton.icon(
      onPressed: controller.start,
      icon: const ExcludeSemantics(child: Icon(Icons.camera_alt_outlined)),
      label: Text(l10n.cameraStart),
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

String _statusText(AppLocalizations l10n, CameraScanStatus status) {
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

String? _failureText(AppLocalizations l10n, CameraFailure? failure) {
  if (failure == null) {
    return null;
  }
  return switch (failure.reason) {
    CameraFailureReason.permissionDenied => l10n.cameraPermissionDeniedHelp,
    CameraFailureReason.permissionPermanentlyDenied =>
      l10n.cameraPermissionPermanentlyDeniedHelp,
    CameraFailureReason.permissionRestricted =>
      l10n.cameraPermissionRestrictedHelp,
    CameraFailureReason.cameraBusy => l10n.cameraBusyHelp,
    CameraFailureReason.noCamera => l10n.cameraMissingHelp,
    CameraFailureReason.initializationTimeout => l10n.cameraTimeoutHelp,
    CameraFailureReason.initializationFailed => l10n.cameraInitializationHelp,
    CameraFailureReason.streamFailed => l10n.cameraStreamHelp,
  };
}
