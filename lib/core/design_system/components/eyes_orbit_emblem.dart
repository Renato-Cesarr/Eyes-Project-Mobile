import 'dart:math' as math;

import 'package:eyes_mobile/core/design_system/components/eyes_brand_mark.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

/// Static brand illustration. It never communicates camera or model readiness.
final class EyesOrbitEmblem extends StatelessWidget {
  const EyesOrbitEmblem({this.height = 140, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Center(
          child: SizedBox(
            width: 188,
            height: height,
            child: CustomPaint(
              painter: _OrbitPainter(
                orbit: colors.outlineVariant,
                accent: colors.primary,
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -math.pi / 24,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      border: Border.all(color: colors.primary),
                      borderRadius: BorderRadius.circular(
                        context.eyesLayout.radiusLg,
                      ),
                    ),
                    child: const Center(child: EyesBrandMark(size: 36)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.orbit, required this.accent});

  final Color orbit;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = Paint()
      ..color = orbit
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final angle in [-math.pi / 7, math.pi / 5, -math.pi / 12]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .86,
          height: size.height * .64,
        ),
        stroke,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset(size.width * .17, size.height * .2),
      3,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.orbit != orbit || oldDelegate.accent != accent;
}
