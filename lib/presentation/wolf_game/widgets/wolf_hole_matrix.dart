import 'package:flutter/material.dart';

import '../../../data/models/player_model.dart';
import '../../../domain/entities/wolf_game_entity.dart';

class WolfHoleMatrix extends StatelessWidget {
  final List<HoleWolfResult> holeResults;
  final List<PlayerModel> players;
  final WolfScoringMode mode;
  final void Function(String playerId, int holeIndex, int strokes)?
  onScoreChanged;

  const WolfHoleMatrix({
    super.key,
    required this.holeResults,
    required this.players,
    required this.mode,
    this.onScoreChanged,
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
          // Matrix Title
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '18-Hole Wolf Match Ledger',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mode == WolfScoringMode.gross
                    ? 'Gross Best Ball'
                    : 'Net Best Ball',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Hole Cards List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: holeResults.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final hole = holeResults[index];
              return _buildHoleCard(context, index, hole);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHoleCard(
    BuildContext context,
    int holeIndex,
    HoleWolfResult hole,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    Color badgeBg;
    Color badgeBorder;
    Color badgeFg;
    String decisionLabel;

    switch (hole.decisionType) {
      case WolfDecisionType.partner:
        badgeBg = colorScheme.secondary.withValues(alpha: 0.12);
        badgeBorder = colorScheme.secondary.withValues(alpha: 0.35);
        badgeFg = colorScheme.secondary;
        final partnerFirst =
            hole.partnerPlayerName?.split(' ').first ?? 'Partner';
        decisionLabel = 'w/ $partnerFirst';
        break;
      case WolfDecisionType.loneWolf:
        badgeBg = colorScheme.primary.withValues(alpha: 0.15);
        badgeBorder = colorScheme.primary.withValues(alpha: 0.4);
        badgeFg = colorScheme.primary;
        decisionLabel = 'Lone Wolf (4x)';
        break;
      case WolfDecisionType.blindWolf:
        badgeBg = colorScheme.error.withValues(alpha: 0.15);
        badgeBorder = colorScheme.error.withValues(alpha: 0.4);
        badgeFg = colorScheme.error;
        decisionLabel = 'Blind Wolf (8x)';
        break;
    }

    final wolfFirstName = hole.wolfPlayerName.split(' ').first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hole.isPending
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hole Meta Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${hole.holeNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'P${hole.par} • SI${hole.strokeIndex}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Wolf: $wolfFirstName',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Text(
                      decisionLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeFg,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Scores & Outcome Row
          Row(
            children: [
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: players.map((player) {
                      final gross = hole.playerGrossScores[player.id] ?? 0;
                      final net = hole.playerNetScores[player.id] ?? gross;
                      final strokesRec =
                          hole.playerStrokesReceived[player.id] ?? 0;
                      final points = hole.pointsAwarded[player.id] ?? 0;

                      final isWolf = hole.wolfPlayerId == player.id;
                      final isPartner = hole.partnerPlayerId == player.id;
                      final displayScore = mode == WolfScoringMode.gross
                          ? '$gross'
                          : '$net';

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: onScoreChanged != null
                              ? () => onScoreChanged!(
                                  player.id,
                                  holeIndex,
                                  gross >= 9
                                      ? hole.par
                                      : (gross <= 0 ? hole.par : gross + 1),
                                )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: points > 0
                                  ? colorScheme.primary.withValues(alpha: 0.15)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (isWolf || isPartner)
                                    ? colorScheme.primary.withValues(alpha: 0.4)
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  player.name.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: (isWolf || isPartner)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: (isWolf || isPartner)
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayScore,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: points > 0
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (mode == WolfScoringMode.net &&
                                    strokesRec > 0) ...[
                                  Text(
                                    '(-$strokesRec)',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Outcome Text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: hole.isTie
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hole.outcomeDescription,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hole.isTie
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
