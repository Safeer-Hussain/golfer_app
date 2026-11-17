import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/club_model.dart';
import '../../../domain/entities/club_gapping_entity.dart';

class DistanceDispersionRadarCard extends StatelessWidget {
  final ClubGappingReport report;
  final ClubModel? selectedClub;
  final ClubDispersionProfile? selectedProfile;
  final ValueChanged<String> onSelectClub;

  const DistanceDispersionRadarCard({
    super.key,
    required this.report,
    required this.selectedClub,
    required this.selectedProfile,
    required this.onSelectClub,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.radar_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Shot Dispersion Radar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (selectedClub != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedClub!.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Custom Painted Radar Viewport
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _RadarPainter(
                    report: report,
                    selectedClub: selectedClub,
                    colorScheme: colorScheme,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Selected Club Metrics Cockpit
            if (selectedClub != null && selectedProfile != null) ...[
              _buildMetricsCockpit(context, selectedClub!, selectedProfile!),
            ] else ...[
              Center(
                child: Text(
                  'Select a club to inspect dispersion metrics',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCockpit(
    BuildContext context,
    ClubModel club,
    ClubDispersionProfile profile,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                label: 'Lateral Spread',
                value: '±${profile.lateralDispersionYards}y',
                icon: Icons.swap_horiz_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricItem(
                context,
                label: 'Distance Var.',
                value: '±${profile.distanceVarianceYards}y',
                icon: Icons.height_rounded,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricItem(
                context,
                label: 'Target Area',
                value: '${profile.dispersionAreaSqYards.round()}y²',
                icon: Icons.circle_outlined,
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Tendency: ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  profile.missTendency,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${profile.consistencyRating}% Acc.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final ClubGappingReport report;
  final ClubModel? selectedClub;
  final ColorScheme colorScheme;

  _RadarPainter({
    required this.report,
    required this.selectedClub,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height - 12);
    final maxRangeYards = 310.0;
    final availableHeight = size.height - 24;

    // Grid lines / Target Arcs
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Center target line
    canvas.drawLine(origin, Offset(size.width / 2, 8), gridPaint);

    // 50y, 100y, 150y, 200y, 250y, 300y arcs
    const yardMarkers = [50, 100, 150, 200, 250, 300];
    for (final yds in yardMarkers) {
      final radius = (yds / maxRangeYards) * availableHeight;
      final rect = Rect.fromCircle(center: origin, radius: radius);
      canvas.drawArc(rect, math.pi * 1.15, math.pi * 0.70, false, gridPaint);

      // Label
      textPainter.text = TextSpan(
        text: '${yds}y',
        style: TextStyle(
          fontSize: 9,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 + 4, origin.dy - radius - 5),
      );
    }

    // Paint non-selected club points
    final unselectedDotPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (final club in report.sortedClubs) {
      if (club.id == selectedClub?.id) continue;

      final dist =
          (report.usesCarryDistance ? club.carryYards : club.totalYards)
              .toDouble();
      final radius = (dist / maxRangeYards) * availableHeight;
      final clubY = origin.dy - radius;
      final clubX = size.width / 2;

      canvas.drawCircle(Offset(clubX, clubY), 3.5, unselectedDotPaint);
    }

    // Paint selected club dispersion ellipse & highlighted dot
    if (selectedClub != null) {
      final dist =
          (report.usesCarryDistance
                  ? selectedClub!.carryYards
                  : selectedClub!.totalYards)
              .toDouble();
      final radius = (dist / maxRangeYards) * availableHeight;
      final centerPoint = Offset(size.width / 2, origin.dy - radius);

      final profile = report.dispersionProfiles[selectedClub!.id];
      if (profile != null) {
        // Convert yards to pixels
        final pxPerYard = availableHeight / maxRangeYards;
        final lateralPx = profile.lateralDispersionYards * pxPerYard * 1.8;
        final variancePx = profile.distanceVarianceYards * pxPerYard * 1.5;

        // Dispersion Ellipse Fill
        final ellipseFill = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill;

        final ellipseRect = Rect.fromCenter(
          center: centerPoint,
          width: lateralPx * 2,
          height: variancePx * 2,
        );
        canvas.drawOval(ellipseRect, ellipseFill);

        // Dispersion Ellipse Stroke
        final ellipseStroke = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawOval(ellipseRect, ellipseStroke);

        // Center dot
        final centerDot = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(centerPoint, 5.0, centerDot);

        // Label above selected club
        textPainter.text = TextSpan(
          text: '${selectedClub!.name} (${dist.toInt()}y)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            centerPoint.dx - textPainter.width / 2,
            centerPoint.dy - variancePx - 14,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.selectedClub?.id != selectedClub?.id ||
        oldDelegate.report != report ||
        oldDelegate.colorScheme != colorScheme;
  }
}
