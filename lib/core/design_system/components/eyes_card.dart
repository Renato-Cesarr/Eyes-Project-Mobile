import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class EyesCard extends StatelessWidget {
  const EyesCard({
    required this.child,
    this.backgroundColor,
    this.semanticLabel,
    this.padding,
    super.key,
  });

  final Widget child;
  final Color? backgroundColor;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = Card(
      color: backgroundColor,
      child: Padding(
        padding: padding ?? EdgeInsets.all(context.eyesLayout.spaceXl),
        child: child,
      ),
    );
    return Semantics(container: true, label: semanticLabel, child: content);
  }
}
