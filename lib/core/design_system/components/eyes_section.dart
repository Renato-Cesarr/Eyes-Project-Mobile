import 'package:eyes_mobile/core/design_system/components/eyes_card.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class EyesSection extends StatelessWidget {
  const EyesSection({
    required this.title,
    required this.children,
    this.description,
    this.icon,
    super.key,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    return EyesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (icon case final icon?) ...<Widget>[
                ExcludeSemantics(child: Icon(icon, size: 28)),
                SizedBox(width: layout.spaceMd),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
          if (description case final description?) ...<Widget>[
            SizedBox(height: layout.spaceSm),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (children.isNotEmpty) SizedBox(height: layout.spaceLg),
          for (var index = 0; index < children.length; index++) ...<Widget>[
            children[index],
            if (index < children.length - 1) SizedBox(height: layout.spaceMd),
          ],
        ],
      ),
    );
  }
}
