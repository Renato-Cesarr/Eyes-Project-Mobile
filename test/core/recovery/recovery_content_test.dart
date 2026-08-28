import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/core/recovery/recovery_content.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations_pt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsPtBr();

  test('every operational failure has actionable localized content', () {
    for (final kind in OperationalFailureKind.values) {
      final content = RecoveryContentResolver.resolve(l10n, kind);
      expect(content.title.trim(), isNotEmpty, reason: kind.name);
      expect(content.message.trim(), isNotEmpty, reason: kind.name);
      expect(
        '${content.title} ${content.message}',
        isNot(contains('technicalCode')),
        reason: kind.name,
      );
    }
  });

  test('every recovery action has a localized label', () {
    for (final action in OperationalRecoveryAction.values) {
      expect(
        RecoveryContentResolver.actionLabel(l10n, action).trim(),
        isNotEmpty,
        reason: action.name,
      );
    }
  });
}
