import 'package:flutter_test/flutter_test.dart';
import 'package:golfer_app/core/storage/database_helper.dart';
import 'package:golfer_app/data/repositories/wind_compass_repository.dart';
import 'package:golfer_app/domain/entities/wind_compass_entity.dart';
import 'package:golfer_app/domain/usecases/wind_compass_usecase.dart';
import 'package:golfer_app/presentation/wind_compass/wind_compass_controller.dart';

void main() {
  group('WindCompassUseCase Unit Tests', () {
    late WindCompassUseCase useCase;

    setUp(() {
      useCase = WindCompassUseCase();
    });

    test(
      'pure headwind resolves full longitudinal resistance and zero crosswind',
      () {
        final res = useCase.resolveWindVectors(
          holeHeadingDegrees: 0.0,
          windDirectionDegrees: 0.0,
          windSpeedKnots: 20.0,
          shotDistanceYards: 150.0,
        );

        expect(res.relativeAngleDegrees, closeTo(0.0, 0.01));
        expect(res.headwindKnots, closeTo(20.0, 0.1));
        expect(res.crosswindKnots, closeTo(0.0, 0.1));
        expect(res.isHeadwind, isTrue);
        expect(res.isTailwind, isFalse);
        expect(res.effectiveDistanceDeltaYards, greaterThan(0.0));
        expect(res.playAsDistanceYards, greaterThan(150.0));
        expect(res.lateralDriftYards.abs(), closeTo(0.0, 0.1));
        expect(res.directionType, equals(WindDirectionType.headwind));
        expect(res.clubAdjustment, greaterThanOrEqualTo(1));
      },
    );

    test(
      'pure tailwind resolves full longitudinal assist and zero crosswind',
      () {
        final res = useCase.resolveWindVectors(
          holeHeadingDegrees: 0.0,
          windDirectionDegrees: 180.0,
          windSpeedKnots: 15.0,
          shotDistanceYards: 150.0,
        );

        expect(res.relativeAngleDegrees.abs(), closeTo(180.0, 0.01));
        expect(res.headwindKnots, closeTo(-15.0, 0.1));
        expect(res.crosswindKnots.abs(), closeTo(0.0, 0.1));
        expect(res.isHeadwind, isFalse);
        expect(res.isTailwind, isTrue);
        expect(res.effectiveDistanceDeltaYards, lessThan(0.0));
        expect(res.playAsDistanceYards, lessThan(150.0));
        expect(res.directionType, equals(WindDirectionType.tailwind));
        expect(res.clubAdjustment, lessThanOrEqualTo(0));
      },
    );

    test(
      'pure crosswind from 90 deg drifts ball to left and advises right aim',
      () {
        final res = useCase.resolveWindVectors(
          holeHeadingDegrees: 0.0,
          windDirectionDegrees: 90.0,
          windSpeedKnots: 14.0,
          shotDistanceYards: 150.0,
        );

        expect(res.relativeAngleDegrees, closeTo(90.0, 0.01));
        expect(res.headwindKnots.abs(), closeTo(0.0, 0.1));
        expect(res.crosswindKnots, closeTo(14.0, 0.1));
        expect(res.lateralDriftYards, greaterThan(0.0)); // drifts left
        expect(res.aimRecommendation.contains('Right of Pin'), isTrue);
        expect(
          res.directionType,
          equals(WindDirectionType.crosswindRightToLeft),
        );
      },
    );

    test(
      'pure crosswind from 270 deg drifts ball to right and advises left aim',
      () {
        final res = useCase.resolveWindVectors(
          holeHeadingDegrees: 0.0,
          windDirectionDegrees: 270.0,
          windSpeedKnots: 14.0,
          shotDistanceYards: 150.0,
        );

        expect(res.relativeAngleDegrees, closeTo(-90.0, 0.01));
        expect(res.crosswindKnots, closeTo(-14.0, 0.1));
        expect(res.lateralDriftYards, lessThan(0.0)); // drifts right
        expect(res.aimRecommendation.contains('Left of Pin'), isTrue);
        expect(
          res.directionType,
          equals(WindDirectionType.crosswindLeftToRight),
        );
      },
    );

    test('quartering headwind at 45 deg decomposes into both vectors', () {
      final res = useCase.resolveWindVectors(
        holeHeadingDegrees: 0.0,
        windDirectionDegrees: 45.0,
        windSpeedKnots: 20.0,
        shotDistanceYards: 150.0,
      );

      expect(res.headwindKnots, greaterThan(10.0));
      expect(res.crosswindKnots, greaterThan(10.0));
      expect(res.effectiveDistanceDeltaYards, greaterThan(0.0));
      expect(res.lateralDriftYards, greaterThan(0.0));
      expect(
        res.directionType,
        equals(WindDirectionType.quarteringHeadwindRight),
      );
    });

    test(
      'calm conditions under 2 knots are classified as calm with zero drift',
      () {
        final res = useCase.resolveWindVectors(
          holeHeadingDegrees: 180.0,
          windDirectionDegrees: 45.0,
          windSpeedKnots: 1.0,
          shotDistanceYards: 150.0,
        );

        expect(res.directionType, equals(WindDirectionType.calm));
        expect(res.intensity, equals(WindIntensity.calm));
        expect(res.aimRecommendation.contains('negligible'), isTrue);
      },
    );

    test('longer shot distance scales lateral drift and yardage penalty', () {
      final shortShot = useCase.resolveWindVectors(
        holeHeadingDegrees: 0.0,
        windDirectionDegrees: 90.0,
        windSpeedKnots: 15.0,
        shotDistanceYards: 100.0,
      );

      final longShot = useCase.resolveWindVectors(
        holeHeadingDegrees: 0.0,
        windDirectionDegrees: 90.0,
        windSpeedKnots: 15.0,
        shotDistanceYards: 250.0,
      );

      expect(
        longShot.absLateralDriftYards,
        greaterThan(shortShot.absLateralDriftYards),
      );
    });
  });

  group('WindSpeedUnit Conversions', () {
    test('converts knots to and from various units accurately', () {
      const knots = 20.0;
      expect(WindSpeedUnit.mph.fromKnots(knots), closeTo(23.01, 0.1));
      expect(WindSpeedUnit.mps.fromKnots(knots), closeTo(10.28, 0.1));
      expect(WindSpeedUnit.kph.fromKnots(knots), closeTo(37.04, 0.1));

      expect(WindSpeedUnit.mph.toKnots(23.0156), closeTo(knots, 0.1));
    });
  });

  group('WindCompassController Unit Tests', () {
    late WindCompassUseCase useCase;
    late WindCompassRepository repository;
    late WindCompassController controller;

    setUp(() {
      useCase = WindCompassUseCase();
      repository = WindCompassRepository(DatabaseHelper.instance);
      controller = WindCompassController(
        useCase: useCase,
        repository: repository,
      );
    });

    test('initializes with default calibrated state', () {
      expect(controller.holeHeading, equals(0.0));
      expect(controller.windDirection, equals(45.0));
      expect(controller.windSpeedKnots, equals(12.0));
      expect(controller.shotDistanceYards, equals(150.0));
      expect(controller.currentResolution, isNotNull);
    });

    test('updateHoleHeading and updateWindDirection recompute resolution', () {
      controller.updateHoleHeading(180.0);
      expect(controller.holeHeading, equals(180.0));

      controller.updateWindDirection(180.0);
      expect(controller.windDirection, equals(180.0));
      expect(
        controller.currentResolution.directionType,
        equals(WindDirectionType.headwind),
      );
    });

    test('updateWindSpeed updates knots and clamps bounds', () {
      controller.updateWindSpeed(25.0);
      expect(controller.windSpeedKnots, equals(25.0));
      expect(controller.displayWindSpeed, equals(25.0));
    });

    test('unit switching changes displayed speed value', () {
      controller.updateWindSpeed(10.0); // 10 knots
      controller.setSpeedUnit(WindSpeedUnit.mph);

      expect(controller.speedUnit, equals(WindSpeedUnit.mph));
      expect(controller.displayWindSpeed, closeTo(11.5, 0.1));
    });

    test('applyPreset updates atmospheric parameters', () {
      final preset = WindPreset.defaults.first; // Links Coastal Gale
      controller.applyPreset(preset);

      expect(controller.windSpeedKnots, equals(preset.windSpeedKnots));
      expect(controller.windDirection, equals(preset.windDirectionDegrees));
      expect(controller.gustKnots, equals(preset.gustKnots));
    });

    test('resetToDefaults restores initial state', () {
      controller.updateHoleHeading(250.0);
      controller.updateWindSpeed(40.0);
      controller.resetToDefaults();

      expect(controller.holeHeading, equals(0.0));
      expect(controller.windSpeedKnots, equals(12.0));
    });

    test('saveCurrentResolution and history methods operate without unhandled exceptions', () async {
      await controller.saveCurrentResolution();
      expect(controller.isLoading, isFalse);

      await controller.loadHistory();
      await controller.clearHistory();
      expect(controller.history, isEmpty);
    });
  });
}
