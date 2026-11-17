import 'dart:math' as math;

import '../../data/models/club_model.dart';
import '../entities/club_gapping_entity.dart';

class ClubGappingUseCase {
  static const int minOptimalGap = 8;
  static const int maxOptimalGap = 15;

  ClubGappingReport analyzeGapping(
    List<ClubModel> clubs, {
    bool usesCarryDistance = true,
  }) {
    if (clubs.isEmpty) {
      return const ClubGappingReport(
        sortedClubs: [],
        gaps: [],
        dispersionProfiles: {},
        averageGapYards: 0.0,
        wideGapsCount: 0,
        overlapCount: 0,
      );
    }

    // Sort clubs descending by distance (longest to shortest)
    final sortedClubs = List<ClubModel>.from(clubs)
      ..sort((a, b) {
        final distA = usesCarryDistance ? a.carryYards : a.totalYards;
        final distB = usesCarryDistance ? b.carryYards : b.totalYards;
        return distB.compareTo(distA);
      });

    final gaps = <ClubGapItem>[];
    int wideCount = 0;
    int overlapCount = 0;
    int totalDiff = 0;

    for (int i = 0; i < sortedClubs.length - 1; i++) {
      final higher = sortedClubs[i];
      final lower = sortedClubs[i + 1];
      final higherDist = usesCarryDistance
          ? higher.carryYards
          : higher.totalYards;
      final lowerDist = usesCarryDistance ? lower.carryYards : lower.totalYards;
      final diff = higherDist - lowerDist;
      totalDiff += diff;

      final GapStatus status;
      final String recommendation;

      if (diff < 0) {
        status = GapStatus.inverted;
        recommendation =
            'Inverted gap: ${higher.name} travels less than ${lower.name}. Loft calibration required.';
      } else if (diff < minOptimalGap) {
        status = GapStatus.overlap;
        recommendation =
            'Yardage overlap: ${diff}y gap between ${higher.name} and ${lower.name}. Club redundancy risk.';
        overlapCount++;
      } else if (diff > maxOptimalGap) {
        status = GapStatus.wideGap;
        recommendation =
            'Wide gap: ${diff}y gap between ${higher.name} and ${lower.name}. Potential distance blind spot.';
        wideCount++;
      } else {
        status = GapStatus.optimal;
        recommendation =
            'Optimal spacing: ${diff}y gap provides consistent course coverage.';
      }

      gaps.add(
        ClubGapItem(
          higherClub: higher,
          lowerClub: lower,
          distanceDifference: diff,
          status: status,
          statusRecommendation: recommendation,
        ),
      );
    }

    final double avgGap = gaps.isNotEmpty
        ? (totalDiff / gaps.length * 10).round() / 10.0
        : 0.0;

    ClubGapItem? largest;
    ClubGapItem? smallest;
    if (gaps.isNotEmpty) {
      largest = gaps.reduce(
        (curr, next) =>
            curr.distanceDifference > next.distanceDifference ? curr : next,
      );
      smallest = gaps.reduce(
        (curr, next) =>
            curr.distanceDifference < next.distanceDifference ? curr : next,
      );
    }

    final dispersionProfiles = <String, ClubDispersionProfile>{};
    for (final club in sortedClubs) {
      final dist = (usesCarryDistance ? club.carryYards : club.totalYards)
          .toDouble();
      final lateral = (dist * 0.045).clamp(3.0, 24.0);
      final variance = (dist * 0.055).clamp(4.0, 22.0);
      final area = math.pi * lateral * variance;

      final String tendency;
      if (club.category.toLowerCase().contains('wood') ||
          club.name.toLowerCase().contains('driver')) {
        tendency = 'Slight Push / Fade';
      } else if (club.category.toLowerCase().contains('iron')) {
        final distInt = dist.toInt();
        if (distInt > 180) {
          tendency = 'Push / Fade';
        } else if (distInt > 140) {
          tendency = 'Straight / Baby Draw';
        } else {
          tendency = 'Dead Straight';
        }
      } else if (club.category.toLowerCase().contains('wedge')) {
        tendency = 'Pin Seeker / High Spin';
      } else {
        tendency = 'Target Center';
      }

      final rating = (100 - (dist * 0.14)).round().clamp(58, 96);

      dispersionProfiles[club.id] = ClubDispersionProfile(
        club: club,
        lateralDispersionYards: (lateral * 10).round() / 10.0,
        distanceVarianceYards: (variance * 10).round() / 10.0,
        dispersionAreaSqYards: (area * 10).round() / 10.0,
        missTendency: tendency,
        consistencyRating: rating,
      );
    }

    return ClubGappingReport(
      sortedClubs: sortedClubs,
      gaps: gaps,
      dispersionProfiles: dispersionProfiles,
      averageGapYards: avgGap,
      wideGapsCount: wideCount,
      overlapCount: overlapCount,
      largestGap: largest,
      smallestGap: smallest,
      usesCarryDistance: usesCarryDistance,
    );
  }
}
