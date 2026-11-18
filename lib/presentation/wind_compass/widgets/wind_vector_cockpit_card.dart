import 'package:flutter/material.dart';

import '../../../domain/entities/wind_compass_entity.dart';

class WindVectorCockpitCard extends StatelessWidget {
  final WindVectorResolution resolution;
  final WindSpeedUnit unit;

  const WindVectorCockpitCard({
    super.key,
    required this.resolution,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.explore_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vector Breakdown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resolution.intensity.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              resolution.directionType.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Headwind / Tailwind Column
                Expanded(
                  child: _buildVectorMetric(
                    context,
                    title: resolution.isHeadwind
                        ? 'Headwind'
                        : (resolution.isTailwind ? 'Tailwind' : 'Longitudinal'),
                    icon: resolution.isHeadwind
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    iconColor: resolution.isHeadwind
                        ? colorScheme.error
                        : colorScheme.tertiary,
                    speedStr:
                        '${unit.fromKnots(resolution.absHeadwindKnots).toStringAsFixed(1)} ${unit.label}',
                    deltaStr: resolution.effectiveDistanceDeltaYards >= 0
                        ? '+${resolution.effectiveDistanceDeltaYards.toStringAsFixed(1)} yds'
                        : '${resolution.effectiveDistanceDeltaYards.toStringAsFixed(1)} yds',
                  ),
                ),
                const SizedBox(width: 12),
                // Crosswind Column
                Expanded(
                  child: _buildVectorMetric(
                    context,
                    title: 'Crosswind',
                    icon: resolution.crosswindKnots > 0
                        ? Icons.arrow_back_rounded
                        : (resolution.crosswindKnots < 0
                              ? Icons.arrow_forward_rounded
                              : Icons.remove_rounded),
                    iconColor: colorScheme.secondary,
                    speedStr:
                        '${unit.fromKnots(resolution.absCrosswindKnots).toStringAsFixed(1)} ${unit.label}',
                    deltaStr: resolution.lateralDriftYards.abs() < 0.5
                        ? 'Center Line'
                        : (resolution.lateralDriftYards > 0
                              ? 'Drift ${resolution.lateralDriftYards.toStringAsFixed(1)}y Left'
                              : 'Drift ${resolution.lateralDriftYards.abs().toStringAsFixed(1)}y Right'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Play As Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_golf_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'True Play-As Distance',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${resolution.shotDistanceYards.toStringAsFixed(0)}y  ->  ${resolution.playAsDistanceYards.toStringAsFixed(0)} yds',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (resolution.clubAdjustment != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: resolution.clubAdjustment > 0
                            ? colorScheme.errorContainer
                            : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resolution.clubAdjustment > 0
                            ? '+${resolution.clubAdjustment} Club'
                            : '${resolution.clubAdjustment} Club',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: resolution.clubAdjustment > 0
                              ? colorScheme.onErrorContainer
                              : colorScheme.onTertiaryContainer,
                        ),
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

  Widget _buildVectorMetric(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String speedStr,
    required String deltaStr,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            speedStr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            deltaStr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
