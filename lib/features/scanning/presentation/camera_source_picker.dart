import 'dart:async';

import 'package:eyes_mobile/features/scanning/application/assistive_scan_coordinator.dart';
import 'package:eyes_mobile/features/scanning/application/camera_source.dart';
import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CameraSourcePicker extends ConsumerStatefulWidget {
  const CameraSourcePicker({required this.coordinator, super.key});

  final AssistiveScanCoordinator coordinator;

  @override
  ConsumerState<CameraSourcePicker> createState() => _CameraSourcePickerState();
}

final class _CameraSourcePickerState extends ConsumerState<CameraSourcePicker> {
  bool _switching = false;

  Future<void> _select(CameraSourceKind kind) async {
    if (_switching) return;
    final selector = ref.read(cameraSourceSelectorProvider);
    if (selector == null) return;
    final current = ref.read(cameraSourceStateProvider).asData?.value;
    if (current?.selected == kind && current?.preference == kind) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _switching = true);
    final wasStreaming =
        ref.read(scanControllerProvider).asData?.value.status ==
        CameraScanStatus.streaming;
    try {
      if (wasStreaming) await widget.coordinator.stop(announce: false);
      await selector.selectSource(kind);
      await HapticFeedback.selectionClick();
      if (wasStreaming) await widget.coordinator.start();
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.cameraSourceSwitchFailed)));
      }
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cameraSourceStateProvider);
    final source = state.asData?.value;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.cameraSourceTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(l10n.cameraSourcePreferenceHelp),
              const SizedBox(height: 20),
              _sourceTile(
                kind: CameraSourceKind.webcam,
                label: l10n.cameraSourceWebcam,
                detail: source?.webcamAvailable == true
                    ? source!.webcams.first.name
                    : l10n.cameraSourceWebcamMissing,
                selected: source?.selected == CameraSourceKind.webcam,
                enabled: source?.webcamAvailable == true && !_switching,
                icon: Icons.videocam_outlined,
              ),
              const SizedBox(height: 8),
              _sourceTile(
                kind: CameraSourceKind.phone,
                label: l10n.cameraSourcePhone,
                detail: l10n.cameraSourcePhoneDetail,
                selected: source?.selected == CameraSourceKind.phone,
                enabled: source != null && !_switching,
                icon: Icons.phone_android_outlined,
              ),
              if (state.isLoading || _switching) ...<Widget>[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (state.hasError) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  l10n.cameraSourceDiscoveryFailed,
                  style: TextStyle(color: scheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.cameraSourceCalibrationNotice,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceTile({
    required CameraSourceKind kind,
    required String label,
    required String detail,
    required bool selected,
    required bool enabled,
    required IconData icon,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$label. $detail',
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: 64,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(detail),
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: enabled ? () => unawaited(_select(kind)) : null,
      ),
    );
  }
}
