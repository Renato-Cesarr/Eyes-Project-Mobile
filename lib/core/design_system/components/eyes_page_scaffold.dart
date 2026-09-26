import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class EyesPageScaffold extends StatelessWidget {
  const EyesPageScaffold({
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.maxContentWidth,
    this.scrollable = true,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double? maxContentWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final layout = context.eyesLayout;
          final content = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth ?? layout.contentMaxWidth,
              ),
              child: Padding(
                padding: layout.pagePaddingFor(constraints.maxWidth),
                child: child,
              ),
            ),
          );
          return scrollable ? SingleChildScrollView(child: content) : content;
        },
      ),
    ),
  );
}
