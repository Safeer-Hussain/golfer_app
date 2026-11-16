enum WolfDecisionType { partner, loneWolf, blindWolf }

enum WolfScoringMode { gross, net }

class HoleWolfResult {
  final int holeNumber;
  final int par;
  final int strokeIndex;
  final String wolfPlayerId;
  final String wolfPlayerName;
  final WolfDecisionType decisionType;
  final String? partnerPlayerId;
  final String? partnerPlayerName;
  final List<String> hunterPlayerIds;
  final Map<String, int> playerGrossScores;
  final Map<String, int> playerNetScores;
  final Map<String, int> playerStrokesReceived;
  final Map<String, int> pointsAwarded; // playerId -> points won on this hole
  final int wolfSideBestScore;
  final int hunterSideBestScore;
  final bool isTie;
  final bool isPending;
  final String outcomeDescription;

  const HoleWolfResult({
    required this.holeNumber,
    required this.par,
    required this.strokeIndex,
    required this.wolfPlayerId,
    required this.wolfPlayerName,
    required this.decisionType,
    this.partnerPlayerId,
    this.partnerPlayerName,
    required this.hunterPlayerIds,
    required this.playerGrossScores,
    required this.playerNetScores,
    required this.playerStrokesReceived,
    required this.pointsAwarded,
    required this.wolfSideBestScore,
    required this.hunterSideBestScore,
    required this.isTie,
    this.isPending = false,
    required this.outcomeDescription,
  });

  bool get isLoneWolf =>
      decisionType == WolfDecisionType.loneWolf ||
      decisionType == WolfDecisionType.blindWolf;

  bool get isBlindWolf => decisionType == WolfDecisionType.blindWolf;
}

class PlayerWolfStanding {
  final String playerId;
  final String playerName;
  final int courseHandicap;
  final int totalPoints;
  final int holesAsWolf;
  final int partnerWins;
  final int loneWolfWins;
  final int hunterWins;
  final double netFinancialBalance; // zero-sum balance

  const PlayerWolfStanding({
    required this.playerId,
    required this.playerName,
    required this.courseHandicap,
    required this.totalPoints,
    required this.holesAsWolf,
    required this.partnerWins,
    required this.loneWolfWins,
    required this.hunterWins,
    required this.netFinancialBalance,
  });
}

class WolfGameResult {
  final WolfScoringMode mode;
  final double stakePerPoint;
  final int totalHolesCount;
  final int completedHolesCount;
  final List<HoleWolfResult> holeResults;
  final List<PlayerWolfStanding> standings;
  final String? leadingPlayerId;

  const WolfGameResult({
    required this.mode,
    required this.stakePerPoint,
    required this.totalHolesCount,
    required this.completedHolesCount,
    required this.holeResults,
    required this.standings,
    this.leadingPlayerId,
  });

  PlayerWolfStanding? get leader {
    if (standings.isEmpty) return null;
    final sorted = List<PlayerWolfStanding>.from(standings)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return sorted.first;
  }
}
