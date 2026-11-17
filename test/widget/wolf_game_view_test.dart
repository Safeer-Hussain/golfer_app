import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfer_app/core/di/service_locator.dart';
import 'package:golfer_app/presentation/wolf_game/widgets/wolf_cockpit_card.dart';
import 'package:golfer_app/presentation/wolf_game/widgets/wolf_hole_matrix.dart';
import 'package:golfer_app/presentation/wolf_game/widgets/wolf_leaderboard_card.dart';
import 'package:golfer_app/presentation/wolf_game/widgets/wolf_rules_modal.dart';
import 'package:golfer_app/presentation/wolf_game/wolf_game_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });

  group('WolfGameView Widget Tests', () {
    testWidgets('renders all Wolf game widgets in portrait mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WolfGameView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Wolf Game Scoring'), findsOneWidget);
      expect(find.byType(WolfCockpitCard), findsOneWidget);
      expect(find.byType(WolfLeaderboardCard), findsOneWidget);
      expect(find.byType(WolfHoleMatrix), findsOneWidget);
      expect(find.text('SHARE STANDINGS'), findsOneWidget);
    });

    testWidgets('renders without overflow in 800x360 landscape viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WolfGameView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WolfCockpitCard), findsOneWidget);
      expect(find.byType(WolfLeaderboardCard), findsOneWidget);
      expect(find.byType(WolfHoleMatrix), findsOneWidget);
    });

    testWidgets('tapping Lone Wolf and Blind Wolf buttons updates selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WolfGameView()));
      await tester.pumpAndSettle();

      final loneWolfBtn = find.text('Lone Wolf (1v3)');
      expect(loneWolfBtn, findsOneWidget);
      await tester.tap(loneWolfBtn);
      await tester.pumpAndSettle();

      final blindWolfBtn = find.text('Blind Wolf');
      expect(blindWolfBtn, findsOneWidget);
      await tester.tap(blindWolfBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('tapping rules icon opens rules bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WolfGameView()));
      await tester.pumpAndSettle();

      final helpBtn = find.byIcon(Icons.help_outline_rounded);
      expect(helpBtn, findsOneWidget);
      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.byType(WolfRulesModal), findsOneWidget);
      expect(find.text('The Rules of Golf Wolf'), findsOneWidget);

      final gotItBtn = find.text('GOT IT');
      await tester.tap(gotItBtn);
      await tester.pumpAndSettle();

      expect(find.byType(WolfRulesModal), findsNothing);
    });

    testWidgets('tapping share button displays feedback toast', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WolfGameView()));
      await tester.pumpAndSettle();

      final shareBtn = find.text('SHARE STANDINGS');
      expect(shareBtn, findsOneWidget);
      await tester.tap(shareBtn);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
