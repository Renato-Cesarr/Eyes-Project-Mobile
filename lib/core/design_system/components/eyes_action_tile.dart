import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class EyesActionTile extends StatelessWidget {
  const EyesActionTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.trailing = const Icon(Icons.chevron_right),
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(layout.radiusMd),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: layout.minimumTapTarget),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: layout.spaceSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (icon case final icon?) ...<Widget>[
                    ExcludeSemantics(child: Icon(icon, size: 28)),
                    SizedBox(width: layout.spaceMd),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (subtitle case final subtitle?) ...<Widget>[
                          SizedBox(height: layout.spaceXs),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing case final trailing?) ...<Widget>[
                    SizedBox(width: layout.spaceSm),
                    ExcludeSemantics(child: trailing),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
