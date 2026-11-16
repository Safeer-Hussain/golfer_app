import 'package:flutter/material.dart';

import '../../data/models/player_model.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/wolf_game_entity.dart';
import '../../domain/usecases/wolf_game_usecase.dart';
import '../scorecard/scorecard_controller.dart';

class WolfGameController extends ChangeNotifier {
  final WolfGameUseCase _useCase;
  final ScorecardController _scorecardController;

  WolfScoringMode _mode = WolfScoringMode.gross;
  double _stakePerPoint = 2.0;
  int _activeHoleNumber = 1;
  bool _useSimulatedScores = false;

  final Map<int, WolfDecisionType> _holeDecisions = {};
  final Map<int, String?> _holePartners = {};

  late CourseEntity _course;
  late List<PlayerModel> _players;
  late Map<String, List<int>> _simulatedScores;

  WolfGameController(this._useCase, this._scorecardController) {
    _course = _scorecardController.course;
    _players = _resolveFlightPlayers();
    _seedSimulatedScores();
    _seedDecisions();
  }

  WolfScoringMode get mode => _mode;
  double get stakePerPoint => _stakePerPoint;
  int get activeHoleNumber => _activeHoleNumber;
  bool get useSimulatedScores => _useSimulatedScores;
  CourseEntity get course => _course;
  List<PlayerModel> get players => _players;

  List<PlayerModel> _resolveFlightPlayers() {
    final active = _scorecardController.players;
    if (active.length == 4) return active;

    return const [
      PlayerModel(
        id: 'p1',
        name: 'Safeer Hussain',
        handicapIndex: 4.2,
        avatarAsset: 'assets/images/avatar_safeer.png',
        teeBox: 'Black',
      ),
      PlayerModel(
        id: 'p2',
        name: 'Hamza Khan',
        handicapIndex: 8.6,
        avatarAsset: 'assets/images/avatar_player2.png',
        teeBox: 'Blue',
      ),
      PlayerModel(
        id: 'p3',
        name: 'Bilal Tariq',
        handicapIndex: 12.4,
        avatarAsset: 'assets/images/avatar_player3.png',
        teeBox: 'Blue',
      ),
      PlayerModel(
        id: 'p4',
        name: 'Usman Malik',
        handicapIndex: 16.8,
        avatarAsset: 'assets/images/avatar_player4.png',
        teeBox: 'White',
      ),
    ];
  }

  void _seedSimulatedScores() {
    _simulatedScores = {
      'p1': [4, 5, 3, 4, 4, 3, 5, 4, 4, 4, 5, 3, 4, 4, 3, 5, 4, 4],
      'p2': [4, 5, 3, 5, 4, 4, 5, 4, 5, 4, 6, 3, 4, 5, 3, 5, 4, 5],
      'p3': [5, 6, 4, 5, 5, 3, 6, 5, 5, 5, 6, 4, 5, 5, 4, 6, 5, 5],
      'p4': [5, 6, 4, 6, 5, 4, 6, 5, 6, 5, 7, 4, 5, 6, 4, 6, 5, 6],
    };
  }

  void _seedDecisions() {
    // Seed varied realistic decisions across 18 holes
    for (var i = 1; i <= 18; i++) {
      if (i == 4 || i == 12) {
        _holeDecisions[i] = WolfDecisionType.loneWolf;
        _holePartners[i] = null;
      } else if (i == 9 || i == 18) {
        _holeDecisions[i] = WolfDecisionType.blindWolf;
        _holePartners[i] = null;
      } else {
        _holeDecisions[i] = WolfDecisionType.partner;
        final wolfIdx = (i - 1) % _players.length;
        final partnerIdx = (wolfIdx + 1) % _players.length;
        _holePartners[i] = _players[partnerIdx].id;
      }
    }
  }

  Map<String, int> get playerCourseHandicaps {
    final map = <String, int>{};
    final slope = _course.slope;
    final rating = _course.rating;
    final par = _course.par;

    for (final player in _players) {
      final slopeFactor = slope / 113.0;
      final ch = (player.handicapIndex * slopeFactor + (rating - par)).round();
      map[player.id] = ch;
    }
    return map;
  }

  Map<String, List<int>> get activeScores {
    if (_useSimulatedScores) {
      return _simulatedScores;
    }

    final result = <String, List<int>>{};
    for (final player in _players) {
      final scores = <int>[];
      for (var i = 1; i <= 18; i++) {
        final holeScore = _scorecardController.getScoreForPlayer(player.id, i);
        scores.add(holeScore.strokes);
      }
      result[player.id] = scores;
    }

    final totalStrokes = result.values.fold<int>(
      0,
      (acc, list) => acc + list.fold(0, (a, b) => a + b),
    );
    if (totalStrokes == 0) {
      return _simulatedScores;
    }

    return result;
  }

  PlayerModel get currentWolfPlayer {
    final wolfIndex = (_activeHoleNumber - 1) % _players.length;
    return _players[wolfIndex];
  }

  WolfDecisionType get currentHoleDecision =>
      _holeDecisions[_activeHoleNumber] ?? WolfDecisionType.partner;

  String? get currentHolePartnerId => _holePartners[_activeHoleNumber];

  WolfGameResult get gameResult {
    return _useCase.evaluateWolfGame(
      holes: _course.holes,
      players: _players,
      playerScores: activeScores,
      playerCourseHandicaps: playerCourseHandicaps,
      holeDecisions: _holeDecisions,
      holePartners: _holePartners,
      mode: _mode,
      stakePerPoint: _stakePerPoint,
    );
  }

  void setMode(WolfScoringMode mode) {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  void setStakePerPoint(double stake) {
    if (_stakePerPoint != stake) {
      _stakePerPoint = stake;
      notifyListeners();
    }
  }

  void setActiveHole(int holeNumber) {
    if (holeNumber >= 1 &&
        holeNumber <= 18 &&
        _activeHoleNumber != holeNumber) {
      _activeHoleNumber = holeNumber;
      notifyListeners();
    }
  }

  void setDecisionForActiveHole(WolfDecisionType decision) {
    _holeDecisions[_activeHoleNumber] = decision;
    if (decision != WolfDecisionType.partner) {
      _holePartners[_activeHoleNumber] = null;
    } else if (_holePartners[_activeHoleNumber] == null) {
      // Pick first eligible player as partner
      final wolfId = currentWolfPlayer.id;
      final partner = _players.firstWhere((p) => p.id != wolfId);
      _holePartners[_activeHoleNumber] = partner.id;
    }
    notifyListeners();
  }

  void setPartnerForActiveHole(String? partnerId) {
    _holeDecisions[_activeHoleNumber] = WolfDecisionType.partner;
    _holePartners[_activeHoleNumber] = partnerId;
    notifyListeners();
  }

  void toggleSimulatedScores() {
    _useSimulatedScores = !_useSimulatedScores;
    notifyListeners();
  }

  void updateSimulatedScore(String playerId, int holeIndex, int strokes) {
    if (_simulatedScores.containsKey(playerId) &&
        holeIndex >= 0 &&
        holeIndex < 18) {
      _simulatedScores[playerId]![holeIndex] = strokes.clamp(1, 15);
      _useSimulatedScores = true;
      notifyListeners();
    }
  }
}
