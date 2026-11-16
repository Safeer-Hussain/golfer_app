import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/utils/app_feedback.dart';
import 'widgets/wolf_cockpit_card.dart';
import 'widgets/wolf_hole_matrix.dart';
import 'widgets/wolf_leaderboard_card.dart';
import 'widgets/wolf_rules_modal.dart';
import 'wolf_game_controller.dart';

class WolfGameView extends StatefulWidget {
  const WolfGameView({super.key});

  @override
  State<WolfGameView> createState() => _WolfGameViewState();
}

class _WolfGameViewState extends State<WolfGameView> {
  late final WolfGameController _controller;
  final ScrollController _portraitScrollController = ScrollController();
  final ScrollController _landscapeLeftController = ScrollController();
  final ScrollController _landscapeRightController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<WolfGameController>();
  }

  @override
  void dispose() {
    _portraitScrollController.dispose();
    _landscapeLeftController.dispose();
    _landscapeRightController.dispose();
    super.dispose();
  }

  void _showRulesModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WolfRulesModal(),
    );
  }

  void _shareStandings(BuildContext context) {
    final result = _controller.gameResult;
    final leader = result.leader;
    final leaderText = leader != null
        ? 'Leader: ${leader.playerName} (${leader.totalPoints} pts, +\$${leader.netFinancialBalance.toStringAsFixed(0)})'
        : 'Wolf Game in progress';

    AppFeedback.showSuccess(
      context,
      'Wolf Game Standings Exported: $leaderText across ${result.completedHolesCount} holes.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Wolf Game Scoring'),
        toolbarHeight: isLandscape ? 40 : kToolbarHeight,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Wolf Game Rules',
            onPressed: () => _showRulesModal(context),
          ),
          IconButton(
            icon: Icon(
              _controller.useSimulatedScores
                  ? Icons.casino_rounded
                  : Icons.casino_outlined,
            ),
            tooltip: 'Toggle Simulation Demo',
            onPressed: _controller.toggleSimulatedScores,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final result = _controller.gameResult;

          if (isLandscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Pane: Cockpit & Leaderboard
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    controller: _landscapeLeftController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WolfCockpitCard(
                          activeHole: _controller.activeHoleNumber,
                          currentWolf: _controller.currentWolfPlayer,
                          players: _controller.players,
                          decision: _controller.currentHoleDecision,
                          partnerId: _controller.currentHolePartnerId,
                          mode: _controller.mode,
                          stakePerPoint: _controller.stakePerPoint,
                          onHoleSelected: _controller.setActiveHole,
                          onDecisionChanged:
                              _controller.setDecisionForActiveHole,
                          onPartnerChanged: _controller.setPartnerForActiveHole,
                          onModeChanged: _controller.setMode,
                          onStakeChanged: _controller.setStakePerPoint,
                        ),
                        const SizedBox(height: 12),
                        WolfLeaderboardCard(
                          standings: result.standings,
                          stakePerPoint: result.stakePerPoint,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant),
                // Right Pane: 18-Hole Matrix
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    controller: _landscapeRightController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WolfHoleMatrix(
                          holeResults: result.holeResults,
                          players: _controller.players,
                          mode: _controller.mode,
                          onScoreChanged: _controller.updateSimulatedScore,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Portrait View
          return SingleChildScrollView(
            controller: _portraitScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WolfCockpitCard(
                  activeHole: _controller.activeHoleNumber,
                  currentWolf: _controller.currentWolfPlayer,
                  players: _controller.players,
                  decision: _controller.currentHoleDecision,
                  partnerId: _controller.currentHolePartnerId,
                  mode: _controller.mode,
                  stakePerPoint: _controller.stakePerPoint,
                  onHoleSelected: _controller.setActiveHole,
                  onDecisionChanged: _controller.setDecisionForActiveHole,
                  onPartnerChanged: _controller.setPartnerForActiveHole,
                  onModeChanged: _controller.setMode,
                  onStakeChanged: _controller.setStakePerPoint,
                ),
                const SizedBox(height: 14),
                WolfLeaderboardCard(
                  standings: result.standings,
                  stakePerPoint: result.stakePerPoint,
                ),
                const SizedBox(height: 14),
                WolfHoleMatrix(
                  holeResults: result.holeResults,
                  players: _controller.players,
                  mode: _controller.mode,
                  onScoreChanged: _controller.updateSimulatedScore,
                ),
                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_wolf_share',
        onPressed: () => _shareStandings(context),
        icon: const Icon(Icons.share_rounded, size: 18),
        label: const Text('SHARE STANDINGS'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}
