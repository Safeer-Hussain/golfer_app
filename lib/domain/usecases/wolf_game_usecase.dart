import 'dart:math' as math;

import '../../core/utils/handicap_calculator.dart';
import '../../data/models/player_model.dart';
import '../entities/hole_entity.dart';
import '../entities/wolf_game_entity.dart';

class WolfGameUseCase {
  WolfGameResult evaluateWolfGame({
    required List<HoleEntity> holes,
    required List<PlayerModel> players,
    required Map<String, List<int>> playerScores,
    required Map<String, int> playerCourseHandicaps,
    Map<int, WolfDecisionType>? holeDecisions,
    Map<int, String?>? holePartners,
    WolfScoringMode mode = WolfScoringMode.gross,
    double stakePerPoint = 2.0,
  }) {
    if (players.isEmpty || holes.isEmpty) {
      return WolfGameResult(
        mode: mode,
        stakePerPoint: stakePerPoint,
        totalHolesCount: holes.length,
        completedHolesCount: 0,
        holeResults: const [],
        standings: const [],
      );
    }

    final totalPointsByPlayer = <String, int>{};
    final holesAsWolfByPlayer = <String, int>{};
    final partnerWinsByPlayer = <String, int>{};
    final loneWolfWinsByPlayer = <String, int>{};
    final hunterWinsByPlayer = <String, int>{};

    for (final p in players) {
      totalPointsByPlayer[p.id] = 0;
      holesAsWolfByPlayer[p.id] = 0;
      partnerWinsByPlayer[p.id] = 0;
      loneWolfWinsByPlayer[p.id] = 0;
      hunterWinsByPlayer[p.id] = 0;
    }

    final resultsList = <HoleWolfResult>[];
    int completedCount = 0;

    for (var i = 0; i < holes.length; i++) {
      final hole = holes[i];
      final holeNum = hole.holeNumber;

      // Determine Rotational Wolf Honor
      final wolfPlayerIndex = (holeNum - 1) % players.length;
      final wolfPlayer = players[wolfPlayerIndex];
      holesAsWolfByPlayer[wolfPlayer.id] =
          (holesAsWolfByPlayer[wolfPlayer.id] ?? 0) + 1;

      // Decision and Partner on this hole
      final decision = holeDecisions?[holeNum] ?? WolfDecisionType.partner;
      String? partnerId;
      if (decision == WolfDecisionType.partner) {
        partnerId = holePartners?[holeNum];
        // Default partner fallback if unspecified: player with next index
        partnerId ??= players[(wolfPlayerIndex + 1) % players.length].id;
        if (partnerId == wolfPlayer.id) {
          partnerId = players[(wolfPlayerIndex + 2) % players.length].id;
        }
      }

      final partnerPlayer = partnerId != null
          ? players.firstWhere(
              (p) => p.id == partnerId,
              orElse: () => players.first,
            )
          : null;

      final hunterIds = players
          .where((p) => p.id != wolfPlayer.id && p.id != partnerId)
          .map((p) => p.id)
          .toList();

      final playerGross = <String, int>{};
      final playerNet = <String, int>{};
      final playerStrokes = <String, int>{};
      var holeHasAllScores = true;

      for (final p in players) {
        final scores = playerScores[p.id];
        final gross = (scores != null && i < scores.length) ? scores[i] : 0;
        if (gross <= 0) {
          holeHasAllScores = false;
        }

        final courseHandicap = playerCourseHandicaps[p.id] ?? 0;
        final strokesRec = HandicapCalculator.calculateStrokesReceived(
          holeStrokeIndex: hole.strokeIndex,
          courseHandicap: courseHandicap,
        );

        playerGross[p.id] = gross;
        playerNet[p.id] = gross - strokesRec;
        playerStrokes[p.id] = strokesRec;
      }

      if (!holeHasAllScores) {
        resultsList.add(
          HoleWolfResult(
            holeNumber: holeNum,
            par: hole.par,
            strokeIndex: hole.strokeIndex,
            wolfPlayerId: wolfPlayer.id,
            wolfPlayerName: wolfPlayer.name,
            decisionType: decision,
            partnerPlayerId: partnerId,
            partnerPlayerName: partnerPlayer?.name,
            hunterPlayerIds: hunterIds,
            playerGrossScores: playerGross,
            playerNetScores: playerNet,
            playerStrokesReceived: playerStrokes,
            pointsAwarded: {for (var p in players) p.id: 0},
            wolfSideBestScore: 0,
            hunterSideBestScore: 0,
            isTie: false,
            isPending: true,
            outcomeDescription: 'Pending Hole',
          ),
        );
        continue;
      }

      completedCount++;

      // Effective score map based on mode
      final effectiveScores = mode == WolfScoringMode.gross
          ? playerGross
          : playerNet;

      // Wolf Side Best Ball
      final wolfScores = <int>[effectiveScores[wolfPlayer.id]!];
      if (decision == WolfDecisionType.partner && partnerId != null) {
        wolfScores.add(effectiveScores[partnerId]!);
      }
      final wolfSideBest = wolfScores.reduce(math.min);

      // Hunters Side Best Ball
      final hunterScores = hunterIds.map((id) => effectiveScores[id]!).toList();
      final hunterSideBest = hunterScores.isNotEmpty
          ? hunterScores.reduce(math.min)
          : 999;

      final pointsMap = <String, int>{for (var p in players) p.id: 0};
      String outcomeText;
      bool isTie = false;

      if (wolfSideBest < hunterSideBest) {
        // Wolf Side Wins
        if (decision == WolfDecisionType.partner && partnerId != null) {
          pointsMap[wolfPlayer.id] = 2;
          pointsMap[partnerId] = 2;
          partnerWinsByPlayer[wolfPlayer.id] =
              (partnerWinsByPlayer[wolfPlayer.id] ?? 0) + 1;
          partnerWinsByPlayer[partnerId] =
              (partnerWinsByPlayer[partnerId] ?? 0) + 1;
          outcomeText =
              'Wolf & ${partnerPlayer?.name.split(' ').first} Win (2 pts each)';
        } else if (decision == WolfDecisionType.loneWolf) {
          pointsMap[wolfPlayer.id] = 4;
          loneWolfWinsByPlayer[wolfPlayer.id] =
              (loneWolfWinsByPlayer[wolfPlayer.id] ?? 0) + 1;
          outcomeText = 'Lone Wolf Victory (+4 pts)';
        } else {
          // Blind Wolf
          pointsMap[wolfPlayer.id] = 8;
          loneWolfWinsByPlayer[wolfPlayer.id] =
              (loneWolfWinsByPlayer[wolfPlayer.id] ?? 0) + 1;
          outcomeText = 'Blind Wolf Jackpot (+8 pts)';
        }
      } else if (hunterSideBest < wolfSideBest) {
        // Hunters Win
        if (decision == WolfDecisionType.partner) {
          for (final hId in hunterIds) {
            pointsMap[hId] = 3;
            hunterWinsByPlayer[hId] = (hunterWinsByPlayer[hId] ?? 0) + 1;
          }
          outcomeText = 'Hunters Defeated Wolf Pack (+3 pts each)';
        } else if (decision == WolfDecisionType.loneWolf) {
          for (final hId in hunterIds) {
            pointsMap[hId] = 1;
            hunterWinsByPlayer[hId] = (hunterWinsByPlayer[hId] ?? 0) + 1;
          }
          outcomeText = 'Hunters Caught Lone Wolf (+1 pt each)';
        } else {
          // Blind Wolf Hunters
          for (final hId in hunterIds) {
            pointsMap[hId] = 3;
            hunterWinsByPlayer[hId] = (hunterWinsByPlayer[hId] ?? 0) + 1;
          }
          outcomeText = 'Hunters Tamed Blind Wolf (+3 pts each)';
        }
      } else {
        // Tie / Halved
        isTie = true;
        outcomeText = 'Hole Halved (0 pts)';
      }

      // Add points to total
      for (final p in players) {
        totalPointsByPlayer[p.id] =
            (totalPointsByPlayer[p.id] ?? 0) + (pointsMap[p.id] ?? 0);
      }

      resultsList.add(
        HoleWolfResult(
          holeNumber: holeNum,
          par: hole.par,
          strokeIndex: hole.strokeIndex,
          wolfPlayerId: wolfPlayer.id,
          wolfPlayerName: wolfPlayer.name,
          decisionType: decision,
          partnerPlayerId: partnerId,
          partnerPlayerName: partnerPlayer?.name,
          hunterPlayerIds: hunterIds,
          playerGrossScores: playerGross,
          playerNetScores: playerNet,
          playerStrokesReceived: playerStrokes,
          pointsAwarded: pointsMap,
          wolfSideBestScore: wolfSideBest,
          hunterSideBestScore: hunterSideBest,
          isTie: isTie,
          isPending: false,
          outcomeDescription: outcomeText,
        ),
      );
    }

    // Zero-Sum Financial Ledger Calculation
    final totalPointsSum = totalPointsByPlayer.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final avgPoints = totalPointsSum / players.length;

    final standings = players.map((p) {
      final points = totalPointsByPlayer[p.id] ?? 0;
      final rawNet = (points - avgPoints) * stakePerPoint;
      final roundedNet = ((rawNet * 100).round() / 100.0);

      return PlayerWolfStanding(
        playerId: p.id,
        playerName: p.name,
        courseHandicap: playerCourseHandicaps[p.id] ?? 0,
        totalPoints: points,
        holesAsWolf: holesAsWolfByPlayer[p.id] ?? 0,
        partnerWins: partnerWinsByPlayer[p.id] ?? 0,
        loneWolfWins: loneWolfWinsByPlayer[p.id] ?? 0,
        hunterWins: hunterWinsByPlayer[p.id] ?? 0,
        netFinancialBalance: roundedNet,
      );
    }).toList();

    // Sort standings descending by total points
    standings.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    final leadingId = standings.isNotEmpty ? standings.first.playerId : null;

    return WolfGameResult(
      mode: mode,
      stakePerPoint: stakePerPoint,
      totalHolesCount: holes.length,
      completedHolesCount: completedCount,
      holeResults: resultsList,
      standings: standings,
      leadingPlayerId: leadingId,
    );
  }
}
