import 'dart:math' as math;

import '../entities/wind_compass_entity.dart';

class WindCompassUseCase {
  WindVectorResolution resolveWindVectors({
    required double holeHeadingDegrees,
    required double windDirectionDegrees,
    required double windSpeedKnots,
    double? gustKnots,
    double? shotDistanceYards,
  }) {
    final normHole = (holeHeadingDegrees % 360 + 360) % 360;
    final normWind = (windDirectionDegrees % 360 + 360) % 360;
    final distance = shotDistanceYards ?? 150.0;
    final speed = math.max(0.0, windSpeedKnots);
    final gust = math.max(speed, gustKnots ?? (speed * 1.25));

    // Calculate relative wind angle [-180, 180]
    final angleDiff = (normWind - normHole + 360) % 360;
    final relativeAngle = angleDiff > 180 ? angleDiff - 360 : angleDiff;

    final rad = relativeAngle * (math.pi / 180.0);
    // Longitudinal: positive = headwind against shot, negative = tailwind pushing shot
    final headwindKnots = speed * math.cos(rad);
    // Lateral: positive = from right (drifts left), negative = from left (drifts right)
    final crosswindKnots = speed * math.sin(rad);

    // Distance scaling relative to 150y standard reference
    final distanceRatio = distance / 150.0;

    // Aerodynamic yardage delta
    final double distanceDelta;
    if (headwindKnots >= 0) {
      // Headwind increases effective distance (lift penalty / drag)
      distanceDelta = headwindKnots * 1.05 * distanceRatio;
    } else {
      // Tailwind decreases effective distance (~55% as effective as headwind)
      distanceDelta = headwindKnots * 0.58 * distanceRatio;
    }

    final playAsDistance = math.max(10.0, distance + distanceDelta);

    // Lateral drift in yards
    final lateralDrift = crosswindKnots * 0.65 * math.pow(distanceRatio, 1.2);

    // Club steps adjustment (+1, +2, -1, etc.)
    final clubAdjustment = (distanceDelta / 10.0).round();

    // Direction classification
    final WindDirectionType directionType;
    if (speed < 2.0) {
      directionType = WindDirectionType.calm;
    } else if (relativeAngle.abs() <= 22.5) {
      directionType = WindDirectionType.headwind;
    } else if (relativeAngle.abs() >= 157.5) {
      directionType = WindDirectionType.tailwind;
    } else if (relativeAngle > 22.5 && relativeAngle < 67.5) {
      directionType = WindDirectionType.quarteringHeadwindRight;
    } else if (relativeAngle >= 67.5 && relativeAngle <= 112.5) {
      directionType = WindDirectionType.crosswindRightToLeft;
    } else if (relativeAngle > 112.5 && relativeAngle < 157.5) {
      directionType = WindDirectionType.quarteringTailwindRight;
    } else if (relativeAngle < -22.5 && relativeAngle > -67.5) {
      directionType = WindDirectionType.quarteringHeadwindLeft;
    } else if (relativeAngle <= -67.5 && relativeAngle >= -112.5) {
      directionType = WindDirectionType.crosswindLeftToRight;
    } else {
      directionType = WindDirectionType.quarteringTailwindLeft;
    }

    final intensity = WindIntensity.fromKnots(speed);

    // Formulate recommendations
    final String aimRec;
    if (lateralDrift.abs() < 1.0) {
      aimRec = 'Target direct pin line (negligible drift)';
    } else if (lateralDrift > 0) {
      aimRec =
          'Aim ${lateralDrift.abs().toStringAsFixed(1)}y Right of Pin into crosswind';
    } else {
      aimRec =
          'Aim ${lateralDrift.abs().toStringAsFixed(1)}y Left of Pin into crosswind';
    }

    final String distRec;
    if (distanceDelta.abs() < 1.5) {
      distRec = 'Plays true to flat yardage';
    } else if (distanceDelta > 0) {
      final clubStr = clubAdjustment > 0 ? ' (Club up +$clubAdjustment)' : '';
      distRec = 'Plays +${distanceDelta.round()}y longer$clubStr';
    } else {
      final clubStr = clubAdjustment < 0
          ? ' (Club down ${clubAdjustment.abs()})'
          : '';
      distRec = 'Plays -${distanceDelta.abs().round()}y shorter$clubStr';
    }

    return WindVectorResolution(
      holeHeadingDegrees: normHole,
      windDirectionDegrees: normWind,
      windSpeedKnots: speed,
      gustKnots: gust,
      shotDistanceYards: distance,
      relativeAngleDegrees: relativeAngle,
      headwindKnots: headwindKnots,
      crosswindKnots: crosswindKnots,
      effectiveDistanceDeltaYards: distanceDelta,
      playAsDistanceYards: playAsDistance,
      lateralDriftYards: lateralDrift,
      clubAdjustment: clubAdjustment,
      aimRecommendation: aimRec,
      distanceRecommendation: distRec,
      directionType: directionType,
      intensity: intensity,
    );
  }
}
