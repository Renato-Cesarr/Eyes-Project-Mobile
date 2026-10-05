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
    var titleLines = 1;
    if (adaptiveTitle) {
      final appBarTheme = Theme.of(context).appBarTheme;
      final hasLeading =
          leading != null || (ModalRoute.of(context)?.canPop ?? false);
      final leadingExtent = hasLeading
          ? leadingWidth ?? appBarTheme.leadingWidth ?? kToolbarHeight
          : 0.0;
      final spacing =
          titleSpacing ??
          appBarTheme.titleSpacing ??
          NavigationToolbar.kMiddleSpacing;
      final painter =
          TextPainter(
            text: TextSpan(
              text: title,
              style:
                  appBarTheme.titleTextStyle ??
                  Theme.of(context).textTheme.titleLarge,
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(
            maxWidth:
                (MediaQuery.sizeOf(context).width -
                        MediaQuery.paddingOf(context).horizontal -
                        leadingExtent -
                        spacing * 2 -
                        actions.length * context.eyesLayout.minimumTapTarget)
                    .clamp(1, double.infinity),
          );
      toolbarHeight = (painter.height + 16).clamp(
        kToolbarHeight,
        double.infinity,
      );
      final lines = painter.computeLineMetrics();
      titleLines = lines.isEmpty ? 1 : lines.length;
      painter.dispose();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: titleLines, softWrap: adaptiveTitle),
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
