import 'package:uuid/uuid.dart';

import '../../core/storage/database_helper.dart';
import '../../domain/entities/wind_compass_entity.dart';

class WindCompassRepository {
  final DatabaseHelper _db;
  final _uuid = const Uuid();

  WindCompassRepository(this._db);

  Future<void> logResolution(WindVectorResolution resolution) async {
    try {
      final log = WindCompassLog(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        holeHeading: resolution.holeHeadingDegrees,
        windDirection: resolution.windDirectionDegrees,
        windSpeedKnots: resolution.windSpeedKnots,
        gustKnots: resolution.gustKnots,
        shotDistanceYards: resolution.shotDistanceYards,
        headwindKnots: resolution.headwindKnots,
        crosswindKnots: resolution.crosswindKnots,
        playAsYards: resolution.playAsDistanceYards,
        lateralDriftYards: resolution.lateralDriftYards,
        recommendation:
            '${resolution.distanceRecommendation} | ${resolution.aimRecommendation}',
      );
      await _db.insertWindLog(log.toJson());
    } catch (_) {
      // In-memory or testing fallback resilience
    }
  }

  Future<List<WindCompassLog>> getRecentLogs() async {
    try {
      final maps = await _db.getWindLogs();
      return maps.map((m) => WindCompassLog.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearLogs() async {
    try {
      await _db.clearWindLogs();
    } catch (_) {
      // Resilience fallback
    }
  }
}
