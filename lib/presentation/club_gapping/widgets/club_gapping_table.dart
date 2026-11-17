import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/club_model.dart';
import '../../../domain/entities/club_gapping_entity.dart';
import 'club_edit_modal.dart';

class ClubGappingTable extends StatelessWidget {
  final ClubGappingReport report;
  final String? selectedClubId;
  final ValueChanged<String> onSelectClub;
  final Function(String clubId, int carryYards, int totalYards) onUpdateYardage;

  const ClubGappingTable({
    super.key,
    required this.report,
    required this.selectedClubId,
    required this.onSelectClub,
    required this.onUpdateYardage,
  });

  void _openEditModal(BuildContext context, ClubModel club) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClubEditModal(
        club: club,
        onSave: (carry, total) => onUpdateYardage(club.id, carry, total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clubs = report.sortedClubs;

    if (clubs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_golf_outlined,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No clubs available in bag',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxDistance = clubs.first.totalYards > 0
        ? (report.usesCarryDistance
              ? clubs.first.carryYards
              : clubs.first.totalYards)
        : 300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.table_rows_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Distance Progression Matrix',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${clubs.length} Clubs',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < clubs.length; i++) ...[
          _buildClubRow(
            context,
            club: clubs[i],
            isSelected: clubs[i].id == selectedClubId,
            maxDistance: maxDistance > 0 ? maxDistance : 300,
          ),
          if (i < report.gaps.length) ...[
            _buildGapIndicator(context, report.gaps[i]),
          ],
        ],
      ],
    );
  }

  Widget _buildClubRow(
    BuildContext context, {
    required ClubModel club,
    required bool isSelected,
    required int maxDistance,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final dist = report.usesCarryDistance ? club.carryYards : club.totalYards;
    final ratio = (dist / maxDistance).clamp(0.05, 1.0);

    return InkWell(
      onTap: () => onSelectClub(club.id),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.35)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _buildCategoryIcon(context, club.category),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          club.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          club.loft,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSelected
                            ? colorScheme.primary
                            : colorScheme.secondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${dist}y',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  report.usesCarryDistance
                      ? 'Total: ${club.totalYards}y'
                      : 'Carry: ${club.carryYards}y',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.tune_rounded, size: 18),
              tooltip: 'Calibrate ${club.name}',
              visualDensity: VisualDensity.compact,
              onPressed: () => _openEditModal(context, club),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context, String category) {
    final colorScheme = Theme.of(context).colorScheme;
    final lower = category.toLowerCase();

    final IconData icon;
    if (lower.contains('wood') || lower.contains('driver')) {
      icon = Icons.sports_golf_rounded;
    } else if (lower.contains('iron')) {
      icon = Icons.golf_course_rounded;
    } else if (lower.contains('wedge')) {
      icon = Icons.flag_circle_rounded;
    } else {
      icon = Icons.sports_baseball_outlined;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: colorScheme.primary),
    );
  }

  Widget _buildGapIndicator(BuildContext context, ClubGapItem gap) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color badgeBg;
    final Color badgeFg;
    final IconData statusIcon;
    final String label;

    switch (gap.status) {
      case GapStatus.optimal:
        badgeBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
        badgeFg = colorScheme.primary;
        statusIcon = Icons.check_circle_outline_rounded;
        label = '${gap.distanceDifference}y gap (Optimal)';
        break;
      case GapStatus.wideGap:
        badgeBg = colorScheme.errorContainer.withValues(alpha: 0.5);
        badgeFg = colorScheme.error;
        statusIcon = Icons.warning_amber_rounded;
        label = '${gap.distanceDifference}y gap (Wide Gap)';
        break;
      case GapStatus.overlap:
        badgeBg = colorScheme.errorContainer.withValues(alpha: 0.5);
        badgeFg = colorScheme.error;
        statusIcon = Icons.sync_problem_rounded;
        label = '${gap.distanceDifference}y gap (Overlap)';
        break;
      case GapStatus.inverted:
        badgeBg = colorScheme.error;
        badgeFg = colorScheme.onError;
        statusIcon = Icons.arrow_downward_rounded;
        label = '${gap.distanceDifference}y gap (Inverted)';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 42, right: 12, top: 2, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 18,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () =>
                AppFeedback.showInfo(context, gap.statusRecommendation),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: badgeFg.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: badgeFg),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeFg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
