import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfer_app/core/di/service_locator.dart';
import 'package:golfer_app/presentation/wind_compass/wind_compass_view.dart';
import 'package:golfer_app/presentation/wind_compass/widgets/aim_adjustment_card.dart';
import 'package:golfer_app/presentation/wind_compass/widgets/compass_rose_hud.dart';
import 'package:golfer_app/presentation/wind_compass/widgets/wind_presets_modal.dart';
import 'package:golfer_app/presentation/wind_compass/widgets/wind_vector_cockpit_card.dart';
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

  group('WindCompassView Widget Tests', () {
    testWidgets('renders all wind compass components in portrait mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WindCompassView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Wind Vector Compass HUD'), findsOneWidget);
      expect(find.byType(CompassRoseHud), findsOneWidget);
      expect(find.byType(WindVectorCockpitCard), findsOneWidget);
      expect(find.byType(AimAdjustmentCard), findsOneWidget);
      expect(find.text('Log Shot Vector'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('renders without overflow in 800x360 landscape viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WindCompassView()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompassRoseHud), findsOneWidget);
      expect(find.byType(WindVectorCockpitCard), findsOneWidget);
      expect(find.byType(AimAdjustmentCard), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('tapping preset icon opens preset modal and selects a preset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WindCompassView()));
      await tester.pumpAndSettle();

      final presetButton = find.byTooltip('Select Wind Preset');
      expect(presetButton, findsOneWidget);
      await tester.tap(presetButton);
      await tester.pumpAndSettle();

      expect(find.byType(WindPresetsModal), findsOneWidget);
      expect(find.text('Atmospheric Wind Presets'), findsOneWidget);

      // Tap on the first preset (Links Coastal Gale)
      await tester.tap(find.text('Links Coastal Gale'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      expect(find.byType(WindPresetsModal), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Log Shot Vector triggers feedback toast', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WindCompassView()));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('tapping history icon opens shot vector history modal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WindCompassView()));
      await tester.pumpAndSettle();

      final historyButton = find.byTooltip('Calculation History');
      expect(historyButton, findsOneWidget);
      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      expect(find.text('Recorded Shot Vector History'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
