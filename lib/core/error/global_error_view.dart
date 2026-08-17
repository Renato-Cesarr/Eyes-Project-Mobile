import 'package:flutter/material.dart';

final class GlobalErrorView extends StatelessWidget {
  const GlobalErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              liveRegion: true,
              label: 'Ocorreu um erro inesperado. Feche e abra o aplicativo.',
              child: const Text(
                'Ocorreu um erro inesperado.\nFeche e abra o aplicativo.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
