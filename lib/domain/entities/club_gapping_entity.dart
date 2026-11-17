import '../../data/models/club_model.dart';

enum GapStatus { optimal, wideGap, overlap, inverted }

class ClubGapItem {
  final ClubModel higherClub;
  final ClubModel lowerClub;
  final int distanceDifference;
  final GapStatus status;
  final String statusRecommendation;

  const ClubGapItem({
    required this.higherClub,
    required this.lowerClub,
    required this.distanceDifference,
    required this.status,
    required this.statusRecommendation,
  });

  bool get isAlert =>
      status == GapStatus.wideGap ||
      status == GapStatus.overlap ||
      status == GapStatus.inverted;
}

class ClubDispersionProfile {
  final ClubModel club;
  final double lateralDispersionYards;
  final double distanceVarianceYards;
  final double dispersionAreaSqYards;
  final String missTendency;
  final int consistencyRating; // 0 to 100

  const ClubDispersionProfile({
    required this.club,
    required this.lateralDispersionYards,
    required this.distanceVarianceYards,
    required this.dispersionAreaSqYards,
    required this.missTendency,
    required this.consistencyRating,
  });
}

class ClubGappingReport {
  final List<ClubModel> sortedClubs;
  final List<ClubGapItem> gaps;
  final Map<String, ClubDispersionProfile> dispersionProfiles;
  final double averageGapYards;
  final int wideGapsCount;
  final int overlapCount;
  final ClubGapItem? largestGap;
  final ClubGapItem? smallestGap;
  final bool usesCarryDistance;

  const ClubGappingReport({
    required this.sortedClubs,
    required this.gaps,
    required this.dispersionProfiles,
    required this.averageGapYards,
    required this.wideGapsCount,
    required this.overlapCount,
    this.largestGap,
    this.smallestGap,
    this.usesCarryDistance = true,
  });
}
