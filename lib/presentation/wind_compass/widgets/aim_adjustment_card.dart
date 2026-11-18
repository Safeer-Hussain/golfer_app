import 'package:flutter/material.dart';

import '../../../domain/entities/wind_compass_entity.dart';

class AimAdjustmentCard extends StatelessWidget {
  final WindVectorResolution resolution;
  final WindSpeedUnit unit;

  const AimAdjustmentCard({
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
                  Icons.gps_fixed_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aim & Elevation Strategy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStrategyTile(
              context,
              icon: Icons.navigation_rounded,
              iconColor: colorScheme.primary,
              title: 'Aim Offset Recommendation',
              description: resolution.aimRecommendation,
            ),
            const SizedBox(height: 10),
            _buildStrategyTile(
              context,
              icon: Icons.speed_rounded,
              iconColor: colorScheme.tertiary,
              title: 'Distance & Trajectory Strategy',
              description: resolution.distanceRecommendation,
            ),
            if (resolution.gustKnots > resolution.windSpeedKnots) ...[
              const SizedBox(height: 10),
              _buildStrategyTile(
                context,
                icon: Icons.air_rounded,
                iconColor: colorScheme.error,
                title: 'Peak Gust Hazard Exposure',
                description:
                    'Gusts up to ${unit.fromKnots(resolution.gustKnots).toStringAsFixed(1)} ${unit.label}. Keep trajectory low to minimize dispersion.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
