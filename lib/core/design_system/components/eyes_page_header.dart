import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class EyesPageHeader extends StatelessWidget {
  const EyesPageHeader({
    required this.title,
    this.description,
    this.leading,
    super.key,
  });

  final String title;
  final String? description;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    final description = this.description;
    return Semantics(
      container: true,
      header: true,
      label: description == null ? title : '$title. $description',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            SizedBox(width: layout.spaceLg),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (description != null) ...<Widget>[
                  SizedBox(height: layout.spaceSm),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
