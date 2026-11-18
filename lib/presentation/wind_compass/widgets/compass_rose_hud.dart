import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/wind_compass_entity.dart';

class CompassRoseHud extends StatelessWidget {
  final WindVectorResolution resolution;
  final double size;

  const CompassRoseHud({
    super.key,
    required this.resolution,
    this.size = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _CompassPainter(
                resolution: resolution,
                colorScheme: colorScheme,
              ),
            ),
            // Center Core Badge
            Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${resolution.windSpeedKnots.toStringAsFixed(0)} kts',
                    style: TextStyle(
                      fontSize: size * 0.058,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    resolution.compassHeadingLabel,
                    style: TextStyle(
                      fontSize: size * 0.045,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final WindVectorResolution resolution;
  final ColorScheme colorScheme;

  _CompassPainter({required this.resolution, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer dial ring
    final dialPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 8, dialPaint);

    final innerDialPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 26, innerDialPaint);

    // 2. Ticks & Cardinal labels
    final tickPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    final majorTickPaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = 2.0;

    for (int deg = 0; deg < 360; deg += 15) {
      final rad = (deg - 90) * (math.pi / 180.0);
      final isMajor = deg % 90 == 0;
      final isSubMajor = deg % 45 == 0;
      final tickLength = isMajor ? 10.0 : (isSubMajor ? 6.0 : 3.0);
      final outerPoint = Offset(
        center.dx + (radius - 8) * math.cos(rad),
        center.dy + (radius - 8) * math.sin(rad),
      );
      final innerPoint = Offset(
        center.dx + (radius - 8 - tickLength) * math.cos(rad),
        center.dy + (radius - 8 - tickLength) * math.sin(rad),
      );
      canvas.drawLine(
        outerPoint,
        innerPoint,
        isMajor ? majorTickPaint : tickPaint,
      );
    }

    _drawCardinals(canvas, center, radius - 20);

    // 3. Hole Target Line (Green vector pointing along hole heading)
    _drawHoleTargetLine(canvas, center, radius - 14);

    // 4. Wind Vector Arrow (Cyan/Blue arrow showing atmospheric wind vector)
    _drawWindVectorArrow(canvas, center, radius - 12);
  }

  void _drawCardinals(Canvas canvas, Offset center, double labelRadius) {
    const cardinals = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};

    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurfaceVariant,
    );

    for (final entry in cardinals.entries) {
      final deg = entry.key;
      final label = entry.value;
      final rad = (deg - 90) * (math.pi / 180.0);
      final pos = Offset(
        center.dx + labelRadius * math.cos(rad),
        center.dy + labelRadius * math.sin(rad),
      );

      final textSpan = TextSpan(
        text: label,
        style: deg == 0
            ? textStyle.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              )
            : textStyle,
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  void _drawHoleTargetLine(Canvas canvas, Offset center, double lineRadius) {
    final holeRad = (resolution.holeHeadingDegrees - 90) * (math.pi / 180.0);
    final targetEnd = Offset(
      center.dx + lineRadius * math.cos(holeRad),
      center.dy + lineRadius * math.sin(holeRad),
    );

    final linePaint = Paint()
      ..color = colorScheme.tertiary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, targetEnd, linePaint);

    // Draw arrowhead at targetEnd
    final arrowPaint = Paint()
      ..color = colorScheme.tertiary
      ..style = PaintingStyle.fill;
    final path = Path();
    final arrowLength = 12.0;
    final arrowWidth = 7.0;

    final tip = targetEnd;
    final left = Offset(
      tip.dx - arrowLength * math.cos(holeRad) + arrowWidth * math.sin(holeRad),
      tip.dy - arrowLength * math.sin(holeRad) - arrowWidth * math.cos(holeRad),
    );
    final right = Offset(
      tip.dx - arrowLength * math.cos(holeRad) - arrowWidth * math.sin(holeRad),
      tip.dy - arrowLength * math.sin(holeRad) + arrowWidth * math.cos(holeRad),
    );

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(left.dx, left.dy);
    path.lineTo(right.dx, right.dy);
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  void _drawWindVectorArrow(Canvas canvas, Offset center, double arrowRadius) {
    // Wind direction is where wind is coming from.
    // The arrow originates from wind direction edge and points toward the center.
    final windRad = (resolution.windDirectionDegrees - 90) * (math.pi / 180.0);
    final sourcePoint = Offset(
      center.dx + arrowRadius * math.cos(windRad),
      center.dy + arrowRadius * math.sin(windRad),
    );

    final windPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Line from source toward center (stopping at center badge edge)
    final inwardRatio = 0.42;
    final targetPoint = Offset(
      center.dx + (arrowRadius * inwardRatio) * math.cos(windRad),
      center.dy + (arrowRadius * inwardRatio) * math.sin(windRad),
    );

    canvas.drawLine(sourcePoint, targetPoint, windPaint);

    // Inward arrowhead pointing towards center
    final headPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    final path = Path();
    const arrowLength = 10.0;
    const arrowWidth = 6.0;

    final tip = targetPoint;
    final backAngle = windRad; // pointing toward center is opposite of windRad
    final left = Offset(
      tip.dx +
          arrowLength * math.cos(backAngle) -
          arrowWidth * math.sin(backAngle),
      tip.dy +
          arrowLength * math.sin(backAngle) +
          arrowWidth * math.cos(backAngle),
    );
    final right = Offset(
      tip.dx +
          arrowLength * math.cos(backAngle) +
          arrowWidth * math.sin(backAngle),
      tip.dy +
          arrowLength * math.sin(backAngle) -
          arrowWidth * math.cos(backAngle),
    );

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(left.dx, left.dy);
    path.lineTo(right.dx, right.dy);
    path.close();
    canvas.drawPath(path, headPaint);

    // Wind origin indicator dot
    final dotPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sourcePoint, 4.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.resolution != resolution ||
        oldDelegate.colorScheme != colorScheme;
  }
}
