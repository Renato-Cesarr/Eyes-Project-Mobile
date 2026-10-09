import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/features/account/application/account_controller.dart';
import 'package:eyes_mobile/features/account/application/scan_metadata_sync.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class ScanSyncPanel extends ConsumerWidget {
  const ScanSyncPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(scanMetadataSyncProvider);
    if (sync == null) return const SizedBox.shrink();
    final snapshot =
        ref.watch(scanSyncSnapshotProvider).asData?.value ?? sync.snapshot;
    final account = ref.watch(accountControllerProvider).asData?.value;
    final busy = account?.isSubmitting ?? true;
    final l10n = AppLocalizations.of(context);
    final message = switch (snapshot.status) {
      ScanSyncStatus.disabled => l10n.scanSyncDisabled,
      ScanSyncStatus.idle => l10n.scanSyncIdle,
      ScanSyncStatus.collecting => l10n.scanSyncCollecting,
      ScanSyncStatus.queued => l10n.scanSyncQueued,
      ScanSyncStatus.sending => l10n.scanSyncSending,
      ScanSyncStatus.retryable => l10n.scanSyncRetryable,
      ScanSyncStatus.authenticationRequired => l10n.scanSyncAuthentication,
      ScanSyncStatus.unavailable => l10n.scanSyncUnavailable,
      ScanSyncStatus.blocked => l10n.scanSyncBlocked,
      ScanSyncStatus.storageFailure => l10n.scanSyncStorage,
      ScanSyncStatus.queueFull => l10n.scanSyncFull,
      ScanSyncStatus.deleted => l10n.scanSyncDeleted,
      ScanSyncStatus.deleteFailed => l10n.scanSyncDeleteFailed,
    };
    return Padding(
      padding: EdgeInsets.only(top: context.eyesLayout.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EyesStatusBanner(
            title: l10n.scanSyncTitle,
            message:
                '$message ${l10n.scanSyncPending(snapshot.pendingSessions)}',
            liveRegion: true,
          ),
          if (account?.isSignedIn == true) ...[
            SizedBox(height: context.eyesLayout.spaceMd),
            EyesButton(
              label: l10n.scanSyncRetry,
              onPressed:
                  busy ||
                      sync.scanning ||
                      !sync.consented ||
                      snapshot.status == ScanSyncStatus.sending
                  ? null
                  : () => sync.retryManually(),
              icon: Icons.sync_outlined,
              variant: EyesButtonVariant.outlined,
              expand: true,
            ),
            SizedBox(height: context.eyesLayout.spaceMd),
            EyesButton(
              label: l10n.scanSyncDelete,
              onPressed: busy
                  ? null
                  : () async {
                      final confirmed = await EyesConfirmationDialog.show(
                        context,
                        title: l10n.scanSyncDelete,
                        message: l10n.scanSyncDeleteMessage,
                        confirmLabel: l10n.scanSyncDeleteConfirm,
                        cancelLabel: l10n.cancel,
                      );
                      if (confirmed == true && context.mounted) {
                        await ref
                            .read(accountControllerProvider.notifier)
                            .deleteSyncHistory();
                      }
                    },
              icon: Icons.delete_outline,
              variant: EyesButtonVariant.outlined,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}
