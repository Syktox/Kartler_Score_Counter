import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drawer reorder area stops above the settings footer', (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {
        ...counterPrefs(),
        'counter_lineup': jsonEncode({'Eins': 0, 'Zwei': 0, 'Drei': 0}),
        'current_counter': 'Eins',
      },
    );
    await openDrawer(tester);

    final list = find.byType(ReorderableListView);
    final boundary = find.ancestor(
      of: list,
      matching: find.byType(DragBoundary),
    );
    final settingsFooter = find.byKey(
      const ValueKey('drawer-settings-footer'),
    );

    expect(boundary, findsOneWidget);
    expect(settingsFooter, findsOneWidget);
    expect(tester.widget<KeyedSubtree>(settingsFooter).child, isA<Material>());
    expect(
      tester.getBottomRight(boundary).dy,
      lessThanOrEqualTo(tester.getTopLeft(settingsFooter).dy),
    );
  });

  testWidgets('landscape counter layout keeps controls compact and visible', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'app_mode': 'counter',
      ...counterPrefs(),
    });
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();

    expect(find.text('Punkte'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('watten table mode renders two opposing sides in landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'app_mode': 'watten',
      'watten_table_mode': true,
      ...wattenPrefs(),
    });
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();

    expect(find.text('Wir'), findsWidgets);
    expect(find.text('Die'), findsWidgets);
    expect(find.text('+2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('counter add field stays visible above the landscape keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'app_mode': 'counter',
      ...counterPrefs(),
    });
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.text('Neuer Zähler'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      tester.getBottomRight(field).dy,
      lessThanOrEqualTo(tester.view.physicalSize.height - 180),
    );
    expect(tester.takeException(), isNull);
  });
}
