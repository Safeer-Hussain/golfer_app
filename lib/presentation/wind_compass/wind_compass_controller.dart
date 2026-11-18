import 'package:flutter/foundation.dart';

import '../../data/repositories/wind_compass_repository.dart';
import '../../domain/entities/wind_compass_entity.dart';
import '../../domain/usecases/wind_compass_usecase.dart';

class WindCompassController extends ChangeNotifier {
  final WindCompassUseCase useCase;
  final WindCompassRepository repository;

  double _holeHeading = 0.0; // 0 degrees = North
  double _windDirection = 45.0; // 45 degrees = NE
  double _windSpeedKnots = 12.0;
  double _gustKnots = 16.0;
  double _shotDistanceYards = 150.0;
  WindSpeedUnit _speedUnit = WindSpeedUnit.knots;
  bool _isLoading = false;
  List<WindCompassLog> _history = [];

  late WindVectorResolution _currentResolution;

  WindCompassController({required this.useCase, required this.repository}) {
    _recalculate();
  }

  // Getters
  double get holeHeading => _holeHeading;
  double get windDirection => _windDirection;
  double get windSpeedKnots => _windSpeedKnots;
  double get gustKnots => _gustKnots;
  double get shotDistanceYards => _shotDistanceYards;
  WindSpeedUnit get speedUnit => _speedUnit;
  bool get isLoading => _isLoading;
  List<WindCompassLog> get history => _history;
  WindVectorResolution get currentResolution => _currentResolution;

  double get displayWindSpeed => _speedUnit.fromKnots(_windSpeedKnots);
  double get displayGustSpeed => _speedUnit.fromKnots(_gustKnots);

  void _recalculate() {
    _currentResolution = useCase.resolveWindVectors(
      holeHeadingDegrees: _holeHeading,
      windDirectionDegrees: _windDirection,
      windSpeedKnots: _windSpeedKnots,
      gustKnots: _gustKnots,
      shotDistanceYards: _shotDistanceYards,
    );
  }

  void updateHoleHeading(double heading) {
    _holeHeading = (heading % 360 + 360) % 360;
    _recalculate();
    notifyListeners();
  }

  void updateWindDirection(double direction) {
    _windDirection = (direction % 360 + 360) % 360;
    _recalculate();
    notifyListeners();
  }

  void updateWindSpeed(double speedInCurrentUnit) {
    _windSpeedKnots = _speedUnit.toKnots(speedInCurrentUnit).clamp(0.0, 60.0);
    if (_gustKnots < _windSpeedKnots) {
      _gustKnots = _windSpeedKnots;
    }
    _recalculate();
    notifyListeners();
  }

  void updateGustSpeed(double gustInCurrentUnit) {
    final knots = _speedUnit.toKnots(gustInCurrentUnit).clamp(0.0, 80.0);
    _gustKnots = knots < _windSpeedKnots ? _windSpeedKnots : knots;
    _recalculate();
    notifyListeners();
  }

  void updateShotDistance(double distanceYards) {
    _shotDistanceYards = distanceYards.clamp(30.0, 350.0);
    _recalculate();
    notifyListeners();
  }

  void setSpeedUnit(WindSpeedUnit unit) {
    if (_speedUnit == unit) return;
    _speedUnit = unit;
    notifyListeners();
  }

  void applyPreset(WindPreset preset) {
    _windDirection = preset.windDirectionDegrees;
    _windSpeedKnots = preset.windSpeedKnots;
    _gustKnots = preset.gustKnots;
    _recalculate();
    notifyListeners();
  }

  void resetToDefaults() {
    _holeHeading = 0.0;
    _windDirection = 45.0;
    _windSpeedKnots = 12.0;
    _gustKnots = 16.0;
    _shotDistanceYards = 150.0;
    _speedUnit = WindSpeedUnit.knots;
    _recalculate();
    notifyListeners();
  }

  Future<void> saveCurrentResolution() async {
    _isLoading = true;
    notifyListeners();
    try {
      await repository.logResolution(_currentResolution);
      await loadHistory();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    try {
      _history = await repository.getRecentLogs();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      await repository.clearLogs();
      _history = [];
      notifyListeners();
    } catch (_) {}
  }
}
