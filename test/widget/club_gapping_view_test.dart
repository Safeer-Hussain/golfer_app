import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfer_app/core/di/service_locator.dart';
import 'package:golfer_app/presentation/club_gapping/club_gapping_view.dart';
import 'package:golfer_app/presentation/club_gapping/widgets/club_gapping_table.dart';
import 'package:golfer_app/presentation/club_gapping/widgets/distance_dispersion_radar_card.dart';
import 'package:golfer_app/presentation/club_gapping/widgets/gapping_summary_cockpit_card.dart';
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

  group('ClubGappingView Widget Tests', () {
    testWidgets('renders all gapping components in portrait mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ClubGappingView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Club Gapping & Dispersion'), findsOneWidget);
      expect(find.byType(GappingSummaryCockpitCard), findsOneWidget);
      expect(find.byType(DistanceDispersionRadarCard), findsOneWidget);
      expect(find.byType(ClubGappingTable), findsOneWidget);
      expect(find.text('Export Gapping'), findsOneWidget);
    });

    testWidgets('renders without overflow in 800x360 landscape viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ClubGappingView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GappingSummaryCockpitCard), findsOneWidget);
      expect(find.byType(DistanceDispersionRadarCard), findsOneWidget);
      expect(find.byType(ClubGappingTable), findsOneWidget);
    });

    testWidgets('toggles between carry and total distance', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ClubGappingView()));
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsOneWidget);
      await tester.tap(find.text('Total'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('triggers export feedback when FAB is tapped', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ClubGappingView())),
      );
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.textContaining('Gapping Report Exported'), findsOneWidget);
    });

    testWidgets('opens gapping guide dialog when help icon is tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ClubGappingView()));
      await tester.pumpAndSettle();

      final helpBtn = find.byIcon(Icons.help_outline_rounded);
      expect(helpBtn, findsOneWidget);

      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Distance Gapping Guide'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(find.text('Distance Gapping Guide'), findsNothing);
    });
  });
}
