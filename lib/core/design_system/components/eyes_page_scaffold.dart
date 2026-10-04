import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class EyesPageScaffold extends StatelessWidget {
  const EyesPageScaffold({
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.leading,
    this.leadingWidth,
    this.titleSpacing,
    this.maxContentWidth,
    this.scrollable = true,
    this.contentPadding,
    this.adaptiveTitle = false,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? leading;
  final double? leadingWidth;
  final double? titleSpacing;
  final double? maxContentWidth;
  final bool scrollable;
  final EdgeInsetsGeometry? contentPadding;
  final bool adaptiveTitle;

  @override
  Widget build(BuildContext context) {
    var toolbarHeight = kToolbarHeight;
    if (adaptiveTitle) {
      final painter =
          TextPainter(
            text: TextSpan(
              text: title,
              style:
                  Theme.of(context).appBarTheme.titleTextStyle ??
                  Theme.of(context).textTheme.titleLarge,
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(
            maxWidth:
                (MediaQuery.sizeOf(context).width - 112 - actions.length * 48)
                    .clamp(1, double.infinity),
          );
      toolbarHeight = (painter.height + 16).clamp(
        kToolbarHeight,
        double.infinity,
      );
      painter.dispose();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: adaptiveTitle ? 3 : 1,
          softWrap: adaptiveTitle,
        ),
        leading: leading,
        leadingWidth: leadingWidth,
        titleSpacing: titleSpacing,
        actions: actions,
        toolbarHeight: toolbarHeight,
      ),
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
                  padding:
                      contentPadding ??
                      layout.pagePaddingFor(constraints.maxWidth),
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
}
