import 'package:flutter/material.dart';

final class EyesBrandMark extends StatelessWidget {
  const EyesBrandMark({this.size = 64, this.semanticLabel, super.key});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _EyesBrandPainter(
          outline: colors.primary,
          iris: colors.secondary,
          pupil: colors.onSecondary,
        ),
      ),
    );

    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: mark);
    return Semantics(
      container: true,
      excludeSemantics: true,
      image: true,
      label: label,
      child: mark,
    );
  }
}

final class _EyesBrandPainter extends CustomPainter {
  const _EyesBrandPainter({
    required this.outline,
    required this.iris,
    required this.pupil,
  });

  final Color outline;
  final Color iris;
  final Color pupil;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eye = Path()
      ..moveTo(size.width * 0.08, center.dy)
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.08,
        size.width * 0.92,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.92,
        size.width * 0.08,
        center.dy,
      )
      ..close();

    canvas.drawPath(
      eye,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = size.shortestSide * 0.075,
    );
    canvas.drawCircle(center, size.shortestSide * 0.22, Paint()..color = iris);
    canvas.drawCircle(center, size.shortestSide * 0.09, Paint()..color = pupil);
  }

  @override
  bool shouldRepaint(covariant _EyesBrandPainter oldDelegate) =>
      outline != oldDelegate.outline ||
      iris != oldDelegate.iris ||
      pupil != oldDelegate.pupil;
}
