enum WindSpeedUnit {
  knots('kts', 1.0),
  mph('mph', 1.15078),
  mps('m/s', 0.51444),
  kph('km/h', 1.852);

  final String label;
  final double knotsMultiplier;

  const WindSpeedUnit(this.label, this.knotsMultiplier);

  double fromKnots(double knots) => knots * knotsMultiplier;
  double toKnots(double value) => value / knotsMultiplier;
}

enum WindDirectionType {
  calm('Calm / Negligible'),
  headwind('Pure Headwind'),
  tailwind('Pure Tailwind'),
  crosswindLeftToRight('Crosswind (L to R)'),
  crosswindRightToLeft('Crosswind (R to L)'),
  quarteringHeadwindLeft('Quartering Headwind (L)'),
  quarteringHeadwindRight('Quartering Headwind (R)'),
  quarteringTailwindLeft('Quartering Tailwind (L)'),
  quarteringTailwindRight('Quartering Tailwind (R)');

  final String displayName;
  const WindDirectionType(this.displayName);
}

enum WindIntensity {
  calm('Calm', 0, 3),
  light('Light Air', 4, 8),
  moderate('Moderate Breeze', 9, 15),
  fresh('Fresh Wind', 16, 22),
  strong('Strong Gale', 23, 32),
  storm('Severe Storm', 33, 99);

  final String label;
  final int minKnots;
  final int maxKnots;

  const WindIntensity(this.label, this.minKnots, this.maxKnots);

  static WindIntensity fromKnots(double speed) {
    if (speed <= 3) return WindIntensity.calm;
    if (speed <= 8) return WindIntensity.light;
    if (speed <= 15) return WindIntensity.moderate;
    if (speed <= 22) return WindIntensity.fresh;
    if (speed <= 32) return WindIntensity.strong;
    return WindIntensity.storm;
  }
}

class WindVectorResolution {
  final double holeHeadingDegrees;
  final double windDirectionDegrees;
  final double windSpeedKnots;
  final double gustKnots;
  final double shotDistanceYards;
  final double relativeAngleDegrees;
  final double headwindKnots;
  final double crosswindKnots;
  final double effectiveDistanceDeltaYards;
  final double playAsDistanceYards;
  final double lateralDriftYards;
  final int clubAdjustment;
  final String aimRecommendation;
  final String distanceRecommendation;
  final WindDirectionType directionType;
  final WindIntensity intensity;

  const WindVectorResolution({
    required this.holeHeadingDegrees,
    required this.windDirectionDegrees,
    required this.windSpeedKnots,
    required this.gustKnots,
    required this.shotDistanceYards,
    required this.relativeAngleDegrees,
    required this.headwindKnots,
    required this.crosswindKnots,
    required this.effectiveDistanceDeltaYards,
    required this.playAsDistanceYards,
    required this.lateralDriftYards,
    required this.clubAdjustment,
    required this.aimRecommendation,
    required this.distanceRecommendation,
    required this.directionType,
    required this.intensity,
  });

  bool get isHeadwind => headwindKnots > 0.5;
  bool get isTailwind => headwindKnots < -0.5;
  bool get hasSignificantCrosswind => crosswindKnots.abs() > 1.0;
  double get absCrosswindKnots => crosswindKnots.abs();
  double get absHeadwindKnots => headwindKnots.abs();
  double get absLateralDriftYards => lateralDriftYards.abs();

  String get compassHeadingLabel => headingToCompass(windDirectionDegrees);
  String get holeHeadingLabel => headingToCompass(holeHeadingDegrees);

  static String headingToCompass(double degrees) {
    final normalized = (degrees % 360 + 360) % 360;
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final index = ((normalized + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}

class WindPreset {
  final String id;
  final String name;
  final String description;
  final double windDirectionDegrees;
  final double windSpeedKnots;
  final double gustKnots;

  const WindPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.windDirectionDegrees,
    required this.windSpeedKnots,
    required this.gustKnots,
  });

  static const List<WindPreset> defaults = [
    WindPreset(
      id: 'links_headwind',
      name: 'Links Coastal Gale',
      description:
          'Heavy 22kt headwind with 30kt gusts typical of British Open links.',
      windDirectionDegrees: 0.0,
      windSpeedKnots: 22.0,
      gustKnots: 30.0,
    ),
    WindPreset(
      id: 'inland_crosswind',
      name: 'Inland Right Cross',
      description: 'Steady 12kt crosswind from 90 degrees pushing ball left across fairway.',
      windDirectionDegrees: 90.0,
      windSpeedKnots: 12.0,
      gustKnots: 16.0,
    ),
    WindPreset(
      id: 'downwind_assist',
      name: 'Downwind Tailwind Rush',
      description:
          '15kt tailwind aiding long drives with lower trajectory rollout.',
      windDirectionDegrees: 180.0,
      windSpeedKnots: 15.0,
      gustKnots: 20.0,
    ),
    WindPreset(
      id: 'calm_morning',
      name: 'Dawn Patrol Calm',
      description:
          'Tranquil 2kt breeze with near zero lateral or vertical impact.',
      windDirectionDegrees: 45.0,
      windSpeedKnots: 2.0,
      gustKnots: 4.0,
    ),
    WindPreset(
      id: 'quartering_hazard',
      name: 'Quartering Water Hazard',
      description: '14kt quartering headwind from left drifting approach shots towards water.',
      windDirectionDegrees: 315.0,
      windSpeedKnots: 14.0,
      gustKnots: 19.0,
    ),
  ];
}

class WindCompassLog {
  final String id;
  final DateTime timestamp;
  final double holeHeading;
  final double windDirection;
  final double windSpeedKnots;
  final double gustKnots;
  final double shotDistanceYards;
  final double headwindKnots;
  final double crosswindKnots;
  final double playAsYards;
  final double lateralDriftYards;
  final String recommendation;

  const WindCompassLog({
    required this.id,
    required this.timestamp,
    required this.holeHeading,
    required this.windDirection,
    required this.windSpeedKnots,
    required this.gustKnots,
    required this.shotDistanceYards,
    required this.headwindKnots,
    required this.crosswindKnots,
    required this.playAsYards,
    required this.lateralDriftYards,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'hole_heading': holeHeading,
    'wind_direction': windDirection,
    'wind_speed_knots': windSpeedKnots,
    'gust_knots': gustKnots,
    'shot_distance_yards': shotDistanceYards,
    'headwind_knots': headwindKnots,
    'crosswind_knots': crosswindKnots,
    'play_as_yards': playAsYards,
    'lateral_drift_yards': lateralDriftYards,
    'recommendation': recommendation,
  };

  factory WindCompassLog.fromJson(Map<String, dynamic> json) => WindCompassLog(
    id: json['id'] as String,
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    holeHeading: (json['hole_heading'] as num?)?.toDouble() ?? 0.0,
    windDirection: (json['wind_direction'] as num?)?.toDouble() ?? 0.0,
    windSpeedKnots: (json['wind_speed_knots'] as num?)?.toDouble() ?? 0.0,
    gustKnots: (json['gust_knots'] as num?)?.toDouble() ?? 0.0,
    shotDistanceYards:
        (json['shot_distance_yards'] as num?)?.toDouble() ?? 150.0,
    headwindKnots: (json['headwind_knots'] as num?)?.toDouble() ?? 0.0,
    crosswindKnots: (json['crosswind_knots'] as num?)?.toDouble() ?? 0.0,
    playAsYards: (json['play_as_yards'] as num?)?.toDouble() ?? 150.0,
    lateralDriftYards: (json['lateral_drift_yards'] as num?)?.toDouble() ?? 0.0,
    recommendation: json['recommendation'] as String? ?? '',
  );
}
