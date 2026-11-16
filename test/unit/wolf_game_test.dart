import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfer_app/core/constants/golf_courses.dart';
import 'package:golfer_app/core/di/service_locator.dart';
import 'package:golfer_app/data/models/player_model.dart';
import 'package:golfer_app/domain/entities/wolf_game_entity.dart';
import 'package:golfer_app/domain/usecases/wolf_game_usecase.dart';
import 'package:golfer_app/presentation/wolf_game/wolf_game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WolfGameUseCase useCase;

  final holes = GolfCourses.lahoreGarrison.holes;

  const players = [
    PlayerModel(
      id: 'p1',
      name: 'Safeer Hussain',
      handicapIndex: 0.0,
      avatarAsset: 'assets/images/avatar_safeer.png',
      teeBox: 'Black',
    ),
    PlayerModel(
      id: 'p2',
      name: 'Hamza Khan',
      handicapIndex: 5.0,
      avatarAsset: 'assets/images/avatar_player2.png',
      teeBox: 'Blue',
    ),
    PlayerModel(
      id: 'p3',
      name: 'Bilal Tariq',
      handicapIndex: 10.0,
      avatarAsset: 'assets/images/avatar_player3.png',
      teeBox: 'Blue',
    ),
    PlayerModel(
      id: 'p4',
      name: 'Usman Malik',
      handicapIndex: 18.0,
      avatarAsset: 'assets/images/avatar_player4.png',
      teeBox: 'White',
    ),
  ];

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'check') {
              return ['wifi'];
            }
            return null;
          },
        );
  });

  setUp(() {
    useCase = WolfGameUseCase();
  });

  group('WolfGameUseCase - Partner Mode (2 vs 2)', () {
    test('Wolf and partner win gives 2 points each', () {
      // Hole 1: Wolf is P1. Partner is P2. Hunters are P3 & P4.
      // P1=3, P2=4 (Wolf best = 3). P3=4, P4=5 (Hunter best = 4).
      final scores = {
        'p1': [3],
        'p2': [4],
        'p3': [4],
        'p4': [5],
      };

      final result = useCase.evaluateWolfGame(
        holes: holes.take(1).toList(),
        players: players,
        playerScores: scores,
        playerCourseHandicaps: {'p1': 0, 'p2': 5, 'p3': 10, 'p4': 18},
        holeDecisions: {1: WolfDecisionType.partner},
        holePartners: {1: 'p2'},
      );

      final hole1 = result.holeResults.first;
      expect(hole1.wolfPlayerId, equals('p1'));
      expect(hole1.partnerPlayerId, equals('p2'));
      expect(hole1.pointsAwarded['p1'], equals(2));
      expect(hole1.pointsAwarded['p2'], equals(2));
      expect(hole1.pointsAwarded['p3'], equals(0));
      expect(hole1.pointsAwarded['p4'], equals(0));
    });

    test('Hunters defeat Wolf pack gives 3 points each to Hunters', () {
      // Hole 1: Wolf is P1, Partner is P2. P1=5, P2=5. P3=4, P4=4 (Hunters best = 4).
      final scores = {
        'p1': [5],
        'p2': [5],
        'p3': [4],
        'p4': [4],
      };

      final result = useCase.evaluateWolfGame(
        holes: holes.take(1).toList(),
        players: players,
        playerScores: scores,
        playerCourseHandicaps: {'p1': 0, 'p2': 5, 'p3': 10, 'p4': 18},
        holeDecisions: {1: WolfDecisionType.partner},
        holePartners: {1: 'p2'},
      );

      final hole1 = result.holeResults.first;
      expect(hole1.pointsAwarded['p1'], equals(0));
      expect(hole1.pointsAwarded['p2'], equals(0));
      expect(hole1.pointsAwarded['p3'], equals(3));
      expect(hole1.pointsAwarded['p4'], equals(3));
    });
  });

  group('WolfGameUseCase - Lone Wolf Mode (1 vs 3)', () {
    test('Lone Wolf win awards 4 points to Wolf alone', () {
      // Hole 1: P1 goes Lone Wolf. P1=3. Hunters P2=4, P3=4, P4=5.
      final scores = {
        'p1': [3],
        'p2': [4],
        'p3': [4],
        'p4': [5],
      };

      final result = useCase.evaluateWolfGame(
        holes: holes.take(1).toList(),
        players: players,
        playerScores: scores,
        playerCourseHandicaps: {'p1': 0, 'p2': 5, 'p3': 10, 'p4': 18},
        holeDecisions: {1: WolfDecisionType.loneWolf},
      );

      final hole1 = result.holeResults.first;
      expect(hole1.isLoneWolf, isTrue);
      expect(hole1.pointsAwarded['p1'], equals(4));
      expect(hole1.pointsAwarded['p2'], equals(0));
      expect(hole1.pointsAwarded['p3'], equals(0));
      expect(hole1.pointsAwarded['p4'], equals(0));
    });

    test('Hunters catching Lone Wolf awards 1 point each to Hunters', () {
      final scores = {
        'p1': [5],
        'p2': [4],
        'p3': [5],
        'p4': [5],
      };

      final result = useCase.evaluateWolfGame(
        holes: holes.take(1).toList(),
        players: players,
        playerScores: scores,
        playerCourseHandicaps: {'p1': 0, 'p2': 5, 'p3': 10, 'p4': 18},
        holeDecisions: {1: WolfDecisionType.loneWolf},
      );

      final hole1 = result.holeResults.first;
      expect(hole1.pointsAwarded['p1'], equals(0));
      expect(hole1.pointsAwarded['p2'], equals(1));
      expect(hole1.pointsAwarded['p3'], equals(1));
      expect(hole1.pointsAwarded['p4'], equals(1));
    });
  });

  group('WolfGameUseCase - Blind Wolf Mode (1 vs 3 Jackpot)', () {
    test('Blind Wolf win awards 8 points to Wolf', () {
      final scores = {
        'p1': [3],
        'p2': [4],
        'p3': [4],
        'p4': [5],
      };

      final result = useCase.evaluateWolfGame(
        holes: holes.take(1).toList(),
        players: players,
        playerScores: scores,
        playerCourseHandicaps: {'p1': 0, 'p2': 5, 'p3': 10, 'p4': 18},
        holeDecisions: {1: WolfDecisionType.blindWolf},
      );

      final hole1 = result.holeResults.first;
      expect(hole1.isBlindWolf, isTrue);
      expect(hole1.pointsAwarded['p1'], equals(8));
      expect(hole1.pointsAwarded['p2'], equals(0));
    });

    test('Hunters defeat Blind Wolf awards 3 points each to Hunters', () {
      final scores = {
        'p1': [5],
        'p2': [4],
        'p3': [4],
        'p4': [5],
      };

      final result = useCase.evaluateWolfGame(
        holes: holes.take(1).toList(),
        players: players,
        playerScores: scores,
        playerCourseHandicaps: {'p1': 0, 'p2': 5, 'p3': 10, 'p4': 18},
        holeDecisions: {1: WolfDecisionType.blindWolf},
      );

      final hole1 = result.holeResults.first;
      expect(hole1.pointsAwarded['p1'], equals(0));
      expect(hole1.pointsAwarded['p2'], equals(3));
      expect(hole1.pointsAwarded['p3'], equals(3));
      expect(hole1.pointsAwarded['p4'], equals(3));
    });
  });

  group('WolfGameUseCase - Zero-Sum Financial Ledger', () {
    test('Guarantees 100% zero-sum financial balance across all 4 players', () {
      final scores = {
        'p1': [4, 5, 3, 4, 4, 3, 5, 4, 4, 4, 5, 3, 4, 4, 3, 5, 4, 4],
        'p2': [4, 5, 3, 5, 4, 4, 5, 4, 5, 4, 6, 3, 4, 5, 3, 5, 4, 5],
        'p3': [5, 6, 4, 5, 5, 3, 6, 5, 5, 5, 6, 4, 5, 5, 4, 6, 5, 5],
        'p4': [5, 6, 4, 6, 5, 4, 6, 5, 6, 5, 7, 4, 5, 6, 4, 6, 5, 6],
      };

      final result = useCase.evaluateWolfGame(
        holes: holes,
        players: players,
        playerScores: scores,
        playerCourseHandicaps: {'p1': 0, 'p2': 5, 'p3': 10, 'p4': 18},
        stakePerPoint: 2.0,
      );

      final sumBalances = result.standings.fold<double>(
        0.0,
        (acc, s) => acc + s.netFinancialBalance,
      );
      expect(sumBalances.abs(), lessThan(0.01));
    });
  });

  group('WolfGameController Tests', () {
    late WolfGameController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await setupServiceLocator();
      controller = sl<WolfGameController>();
    });

    test('Initializes with 4 tournament flight players and hole 1 active', () {
      expect(controller.players.length, equals(4));
      expect(controller.activeHoleNumber, equals(1));
      expect(controller.currentWolfPlayer.id, equals('p1'));
    });

    test('setActiveHole updates Wolf honor rotation across players', () {
      controller.setActiveHole(2);
      expect(controller.currentWolfPlayer.id, equals('p2'));

      controller.setActiveHole(3);
      expect(controller.currentWolfPlayer.id, equals('p3'));

      controller.setActiveHole(4);
      expect(controller.currentWolfPlayer.id, equals('p4'));

      controller.setActiveHole(5);
      expect(controller.currentWolfPlayer.id, equals('p1'));
    });

    test('Decision changes notify listeners and recalculate points', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setDecisionForActiveHole(WolfDecisionType.loneWolf);
      expect(notified, isTrue);
      expect(controller.currentHoleDecision, equals(WolfDecisionType.loneWolf));
      expect(controller.currentHolePartnerId, isNull);
    });

    test(
      'setPartnerForActiveHole selects partner and sets decision to partner',
      () {
        controller.setPartnerForActiveHole('p3');
        expect(
          controller.currentHoleDecision,
          equals(WolfDecisionType.partner),
        );
        expect(controller.currentHolePartnerId, equals('p3'));
      },
    );

    test('Mode switching and stake updating work smoothly', () {
      controller.setMode(WolfScoringMode.net);
      expect(controller.mode, equals(WolfScoringMode.net));

      controller.setStakePerPoint(5.0);
      expect(controller.stakePerPoint, equals(5.0));
    });
  });
}
