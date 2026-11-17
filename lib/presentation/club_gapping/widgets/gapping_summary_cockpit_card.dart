import 'package:flutter/material.dart';

import '../../../domain/entities/club_gapping_entity.dart';

class GappingSummaryCockpitCard extends StatelessWidget {
  final ClubGappingReport report;
  final bool usesCarryDistance;
  final VoidCallback onToggleMetric;
  final VoidCallback? onResetDefaults;

  const GappingSummaryCockpitCard({
    super.key,
    required this.report,
    required this.usesCarryDistance,
    required this.onToggleMetric,
    this.onResetDefaults,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAlerts = report.wideGapsCount > 0 || report.overlapCount > 0;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_graph_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '14-Club Gapping Cockpit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                // Carry vs Total Toggle Segment
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Carry', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Total', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {usesCarryDistance},
                  onSelectionChanged: (selected) {
                    if (selected.first != usesCarryDistance) {
                      onToggleMetric();
                    }
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Avg Gap',
                    value: '${report.averageGapYards}y',
                    subtitle: 'Target: 10-14y',
                    icon: Icons.straighten_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Wide Gaps',
                    value: '${report.wideGapsCount}',
                    subtitle: '> 15y spread',
                    icon: Icons.warning_amber_rounded,
                    color: report.wideGapsCount > 0
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'Overlaps',
                    value: '${report.overlapCount}',
                    subtitle: '< 8y gap',
                    icon: Icons.sync_problem_rounded,
                    color: report.overlapCount > 0
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                ),
              ],
            ),
            if (hasAlerts) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.wideGapsCount > 0 && report.overlapCount > 0
                            ? 'Detected ${report.wideGapsCount} wide distance blind spots and ${report.overlapCount} yardage overlaps.'
                            : report.wideGapsCount > 0
                            ? 'Detected ${report.wideGapsCount} wide gaps (>15y). Consider adjusting club lofts or adding a gap wedge/hybrid.'
                            : 'Detected ${report.overlapCount} overlaps (<8y). Multiple clubs cover the same distance interval.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
