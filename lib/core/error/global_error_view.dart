import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/design_system/components/eyes_state_view.dart';
import 'package:flutter/material.dart';

final class GlobalErrorView extends StatelessWidget {
  const GlobalErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: const Material(
        child: SafeArea(
          child: EyesStateView.error(
            title: 'Ocorreu um erro inesperado',
            message: 'Feche e abra o aplicativo.',
          ),
        ),
      ),
    );
  }
}
