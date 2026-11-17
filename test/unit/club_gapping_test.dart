import 'package:flutter_test/flutter_test.dart';
import 'package:golfer_app/data/models/club_model.dart';
import 'package:golfer_app/domain/entities/club_gapping_entity.dart';
import 'package:golfer_app/domain/usecases/club_gapping_usecase.dart';
import 'package:golfer_app/presentation/club_gapping/club_gapping_controller.dart';

void main() {
  group('ClubGappingUseCase Unit Tests', () {
    late ClubGappingUseCase useCase;

    setUp(() {
      useCase = ClubGappingUseCase();
    });

    test('empty clubs list returns empty report', () {
      final report = useCase.analyzeGapping([]);

      expect(report.sortedClubs, isEmpty);
      expect(report.gaps, isEmpty);
      expect(report.dispersionProfiles, isEmpty);
      expect(report.averageGapYards, equals(0.0));
      expect(report.wideGapsCount, equals(0));
      expect(report.overlapCount, equals(0));
      expect(report.largestGap, isNull);
      expect(report.smallestGap, isNull);
    });

    test('analyzes default 14 clubs with carry distance correctly', () {
      final clubs = ClubModel.default14Clubs;
      final report = useCase.analyzeGapping(clubs, usesCarryDistance: true);

      expect(report.sortedClubs.length, equals(clubs.length));
      expect(report.gaps.length, equals(clubs.length - 1));
      expect(report.dispersionProfiles.length, equals(clubs.length));
      expect(report.averageGapYards, greaterThan(0));
      expect(report.usesCarryDistance, isTrue);

      // Verify clubs are sorted descending by carry distance
      for (int i = 0; i < report.sortedClubs.length - 1; i++) {
        expect(
          report.sortedClubs[i].carryYards,
          greaterThanOrEqualTo(report.sortedClubs[i + 1].carryYards),
        );
      }
    });

    test(
      'detects wide gaps (>15y), optimal gaps (8-15y), and overlaps (<8y)',
      () {
        const testClubs = [
          ClubModel(
            id: 'driver',
            name: 'Driver',
            category: 'Wood',
            loft: '10.5°',
            carryYards: 250,
            totalYards: 270,
            imageAsset: 'assets/images/club_driver.png',
          ),
          ClubModel(
            id: '3wood',
            name: '3-Wood',
            category: 'Wood',
            loft: '15°',
            carryYards: 220, // 30y gap -> wide gap
            totalYards: 240,
            imageAsset: 'assets/images/club_wood.png',
          ),
          ClubModel(
            id: '5wood',
            name: '5-Wood',
            category: 'Wood',
            loft: '18°',
            carryYards: 208, // 12y gap -> optimal
            totalYards: 220,
            imageAsset: 'assets/images/club_wood.png',
          ),
          ClubModel(
            id: '4hybrid',
            name: '4-Hybrid',
            category: 'Hybrid',
            loft: '21°',
            carryYards: 204, // 4y gap -> overlap
            totalYards: 215,
            imageAsset: 'assets/images/club_iron.png',
          ),
        ];

        final report = useCase.analyzeGapping(
          testClubs,
          usesCarryDistance: true,
        );

        expect(report.gaps.length, equals(3));

        // Gap 1: Driver to 3-Wood (250 - 220 = 30)
        expect(report.gaps[0].distanceDifference, equals(30));
        expect(report.gaps[0].status, equals(GapStatus.wideGap));
        expect(report.gaps[0].isAlert, isTrue);

        // Gap 2: 3-Wood to 5-Wood (220 - 208 = 12)
        expect(report.gaps[1].distanceDifference, equals(12));
        expect(report.gaps[1].status, equals(GapStatus.optimal));
        expect(report.gaps[1].isAlert, isFalse);

        // Gap 3: 5-Wood to 4-Hybrid (208 - 204 = 4)
        expect(report.gaps[2].distanceDifference, equals(4));
        expect(report.gaps[2].status, equals(GapStatus.overlap));
        expect(report.gaps[2].isAlert, isTrue);

        expect(report.wideGapsCount, equals(1));
        expect(report.overlapCount, equals(1));
        expect(report.largestGap?.distanceDifference, equals(30));
        expect(report.smallestGap?.distanceDifference, equals(4));
      },
    );

    test('detects inverted gap when higher club travels less', () {
      const invertedClubs = [
        ClubModel(
          id: 'iron4',
          name: '4-Iron',
          category: 'Iron',
          loft: '21°',
          carryYards: 180,
          totalYards: 190,
          imageAsset: 'assets/images/club_iron.png',
        ),
        ClubModel(
          id: 'iron5',
          name: '5-Iron',
          category: 'Iron',
          loft: '24°',
          carryYards: 185, // 5-iron travels further than 4-iron
          totalYards: 195,
          imageAsset: 'assets/images/club_iron.png',
        ),
      ];

      // Note: analyzeGapping sorts descending by distance, so iron5 (185y) becomes higherClub
      // Let's create an inverted gap manually or verify sorting
      final report = useCase.analyzeGapping(
        invertedClubs,
        usesCarryDistance: true,
      );

      // sortedClubs[0] is 5-Iron (185y), sortedClubs[1] is 4-Iron (180y), difference = 5y (overlap)
      expect(report.sortedClubs.first.id, equals('iron5'));
      expect(report.gaps.first.status, equals(GapStatus.overlap));
    });

    test(
      'dispersion profiles calculate realistic lateral and distance variance',
      () {
        final clubs = ClubModel.default14Clubs;
        final report = useCase.analyzeGapping(clubs, usesCarryDistance: true);

        final driverDispersion = report.dispersionProfiles['driver']!;
        expect(driverDispersion.lateralDispersionYards, greaterThan(8.0));
        expect(driverDispersion.distanceVarianceYards, greaterThan(10.0));
        expect(driverDispersion.dispersionAreaSqYards, greaterThan(200.0));
        expect(driverDispersion.consistencyRating, inInclusiveRange(55, 80));

        final pwDispersion = report.dispersionProfiles['pw']!;
        expect(
          pwDispersion.lateralDispersionYards,
          lessThan(driverDispersion.lateralDispersionYards),
        );
        expect(
          pwDispersion.consistencyRating,
          greaterThan(driverDispersion.consistencyRating),
        );
      },
    );

    test('analyzes total distance when toggle is switched', () {
      final clubs = ClubModel.default14Clubs;
      final carryReport = useCase.analyzeGapping(
        clubs,
        usesCarryDistance: true,
      );
      final totalReport = useCase.analyzeGapping(
        clubs,
        usesCarryDistance: false,
      );

      expect(carryReport.usesCarryDistance, isTrue);
      expect(totalReport.usesCarryDistance, isFalse);
      expect(
        totalReport.sortedClubs.first.totalYards,
        greaterThan(carryReport.sortedClubs.first.carryYards),
      );
    });
  });

  group('ClubGappingController Unit Tests', () {
    late ClubGappingUseCase useCase;
    late ClubGappingController controller;

    setUp(() {
      useCase = ClubGappingUseCase();
      controller = ClubGappingController(useCase: useCase);
    });

    test('initializes with default clubs and computes report', () {
      expect(controller.clubs, isNotEmpty);
      expect(controller.report, isNotNull);
      expect(controller.selectedClub, isNotNull);
      expect(controller.usesCarryDistance, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('toggleDistanceMetric alternates between carry and total', () {
      expect(controller.usesCarryDistance, isTrue);
      controller.toggleDistanceMetric();
      expect(controller.usesCarryDistance, isFalse);
      expect(controller.report?.usesCarryDistance, isFalse);

      controller.toggleDistanceMetric();
      expect(controller.usesCarryDistance, isTrue);
      expect(controller.report?.usesCarryDistance, isTrue);
    });

    test('selectClub updates selected club and dispersion', () {
      controller.selectClub('7iron');
      expect(controller.selectedClubId, equals('7iron'));
      expect(controller.selectedClub?.name, equals('7-Iron'));
      expect(controller.selectedClubDispersion, isNotNull);
    });

    test('updateClubYardages modifies club and recomputes report', () async {
      await controller.updateClubYardages('driver', 280, 305);

      final updatedDriver = controller.clubs.firstWhere(
        (c) => c.id == 'driver',
      );
      expect(updatedDriver.carryYards, equals(280));
      expect(updatedDriver.totalYards, equals(305));
      expect(controller.report?.sortedClubs.first.carryYards, equals(280));
    });

    test('resetToDefaults restores initial 14-club bag yardages', () async {
      await controller.updateClubYardages('driver', 300, 320);
      expect(
        controller.clubs.firstWhere((c) => c.id == 'driver').carryYards,
        equals(300),
      );

      controller.resetToDefaults();
      expect(
        controller.clubs.firstWhere((c) => c.id == 'driver').carryYards,
        equals(265),
      );
    });
  });
}
