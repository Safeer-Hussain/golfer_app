import 'package:flutter/material.dart';

import '../../../data/models/player_model.dart';
import '../../../domain/entities/wolf_game_entity.dart';

class WolfCockpitCard extends StatelessWidget {
  final int activeHole;
  final PlayerModel currentWolf;
  final List<PlayerModel> players;
  final WolfDecisionType decision;
  final String? partnerId;
  final WolfScoringMode mode;
  final double stakePerPoint;
  final ValueChanged<int> onHoleSelected;
  final ValueChanged<WolfDecisionType> onDecisionChanged;
  final ValueChanged<String?> onPartnerChanged;
  final ValueChanged<WolfScoringMode> onModeChanged;
  final ValueChanged<double> onStakeChanged;

  const WolfCockpitCard({
    super.key,
    required this.activeHole,
    required this.currentWolf,
    required this.players,
    required this.decision,
    required this.partnerId,
    required this.mode,
    required this.stakePerPoint,
    required this.onHoleSelected,
    required this.onDecisionChanged,
    required this.onPartnerChanged,
    required this.onModeChanged,
    required this.onStakeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Wolf Honor & Active Hole
          Row(
            children: [
              Icon(Icons.pets_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hole #$activeHole Wolf Strategy',
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'Wolf: ${currentWolf.name.split(' ').first}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal 18-Hole Carousel/Stepper
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(18, (index) {
                final holeNum = index + 1;
                final isSelected = holeNum == activeHole;
                final isWolfHere =
                    ((holeNum - 1) % players.length) ==
                    players.indexOf(currentWolf);

                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () => onHoleSelected(holeNum),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : (isWolfHere
                                  ? colorScheme.primary.withValues(alpha: 0.08)
                                  : colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                      child: Text(
                        '#$holeNum',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Decision Type Selector
          Text(
            'Wolf Call Strategy',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildDecisionButton(
                context,
                type: WolfDecisionType.partner,
                label: 'Partner (2v2)',
                pointsText: '2 pts',
                isSelected: decision == WolfDecisionType.partner,
              ),
              const SizedBox(width: 6),
              _buildDecisionButton(
                context,
                type: WolfDecisionType.loneWolf,
                label: 'Lone Wolf (1v3)',
                pointsText: '4 pts',
                isSelected: decision == WolfDecisionType.loneWolf,
              ),
              const SizedBox(width: 6),
              _buildDecisionButton(
                context,
                type: WolfDecisionType.blindWolf,
                label: 'Blind Wolf',
                pointsText: '8 pts',
                isSelected: decision == WolfDecisionType.blindWolf,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Partner Picker (Shown if decision == partner)
          if (decision == WolfDecisionType.partner) ...[
            Text(
              'Select Wolf Partner:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: players.where((p) => p.id != currentWolf.id).map((p) {
                final isPartner = partnerId == p.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => onPartnerChanged(p.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isPartner
                              ? colorScheme.secondary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPartner
                                ? colorScheme.secondary
                                : colorScheme.outlineVariant,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isPartner
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isPartner
                                ? colorScheme.onSecondary
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Scoring Mode & Stake Selector Row
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    _buildModeButton(
                      context,
                      label: 'Gross',
                      isSelected: mode == WolfScoringMode.gross,
                      onTap: () => onModeChanged(WolfScoringMode.gross),
                    ),
                    const SizedBox(width: 6),
                    _buildModeButton(
                      context,
                      label: 'Net (Handicap)',
                      isSelected: mode == WolfScoringMode.net,
                      onTap: () => onModeChanged(WolfScoringMode.net),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [1.0, 2.0, 5.0, 10.0].map((stake) {
                      final isSelected = (stakePerPoint - stake).abs() < 0.1;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: InkWell(
                          onTap: () => onStakeChanged(stake),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              '\$${stake.toInt()}/pt',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionButton(
    BuildContext context, {
    required WolfDecisionType type,
    required String label,
    required String pointsText,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () => onDecisionChanged(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                pointsText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.8)
                      : colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
