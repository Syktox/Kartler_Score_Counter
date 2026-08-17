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
    final settingsFooter = find.byKey(const ValueKey('drawer-settings-footer'));

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
      'app_mode': 'counter',
      ...counterPrefs(),
    });
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);

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
      'app_mode': 'watten',
      'watten_table_mode': true,
      ...wattenPrefs(),
    });
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);

    expect(find.text('Ich'), findsWidgets);
    expect(find.text('Du'), findsWidgets);
    expect(find.text('+2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mulatschak landscape stacks the buttons beside the multiplier', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(
      mulatschakPrefs(lineup: {'p1': 21, 'p2': 21}),
    );
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);

    final minusFive = tester.getRect(
      find.ancestor(of: find.text('-5'), matching: find.byType(ElevatedButton)),
    );
    final plusFive = tester.getRect(
      find.ancestor(of: find.text('+5'), matching: find.byType(ElevatedButton)),
    );
    final multiplier = tester.getRect(
      find.byKey(const Key('mulatschakMultiplierButton')),
    );
    final firstCard = tester.getRect(
      find.byKey(const ValueKey('mulatschak-score-player-p1')),
    );
    final panelCenter = (62.0 + (360.0 - 6.0)) / 2;

    expect(
      multiplier.center.dx,
      greaterThan(400),
      reason: 'controls sit on the right half',
    );
    expect(
      minusFive.top,
      lessThan(plusFive.top),
      reason: '-5 sits above +5',
    );
    expect(
      minusFive.bottom,
      lessThan(plusFive.top),
      reason: 'buttons are stacked vertically',
    );
    expect(
      multiplier.right,
      lessThan(minusFive.left),
      reason: 'multiplier sits beside the buttons',
    );
    expect(
      (multiplier.center.dy - panelCenter).abs(),
      lessThan(40),
      reason: 'multiplier is vertically centered',
    );
    expect(
      plusFive.bottom,
      greaterThan(360 - 40),
      reason: 'buttons fill the height down to the bottom edge',
    );
    expect(
      minusFive.top,
      lessThan(56 + 40),
      reason: 'buttons start right below the app bar',
    );
    expect(
      plusFive.right,
      lessThan(tester.view.physicalSize.width - 10),
      reason: 'buttons stay inside the right safe area',
    );
    expect(
      firstCard.right,
      lessThan(multiplier.left),
      reason: 'player cards stay left of the controls',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('players page keeps the add button full width in landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(mulatschakPrefs());
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);

    await openDrawer(tester);
    await tester.drag(find.byType(ReorderableListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Spieler verwalten'));
    await tester.tap(find.text('Spieler verwalten'));
    await tester.pumpAndSettle();

    final addButton = find.widgetWithText(FilledButton, 'Spieler hinzufügen');
    expect(addButton, findsOneWidget);
    final rect = tester.getRect(addButton);
    expect(rect.width, greaterThan(700));
    expect(rect.bottom, greaterThanOrEqualTo(340));

    await tester.tap(addButton);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'player duplicate-name bubble appears just above the landscape keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(mulatschakPrefs());
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();
      await dismissStartScreen(tester);

      await openDrawer(tester);
      await tester.drag(
        find.byType(ReorderableListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Spieler verwalten'));
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Spieler hinzufügen'));
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();

      final bubble = find.text('Dieser Spielername ist bereits vergeben.');
      expect(bubble, findsOneWidget);
      final bubbleRect = tester.getRect(bubble);
      final keyboardTop = tester.view.physicalSize.height - 200;
      expect(
        bubbleRect.bottom,
        lessThanOrEqualTo(keyboardTop),
        reason: 'bubble must not be hidden behind the keyboard',
      );
      expect(
        bubbleRect.bottom,
        greaterThan(keyboardTop - 60),
        reason: 'bubble sits just above the keyboard',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mulatschak portrait centers fewer than three players', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(
      mulatschakPrefs(lineup: {'p1': 21, 'p2': 21}),
    );
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);

    final card = tester.getRect(
      find.byKey(const ValueKey('mulatschak-score-player-p1')),
    );
    final screenHeight = tester.view.physicalSize.height;
    final cardCenter = card.center.dy;

    expect(cardCenter, greaterThan(screenHeight * 0.30));
    expect(cardCenter, lessThan(screenHeight * 0.70));
    final wrap = tester.getRect(find.byType(Wrap).first);
    expect(
      (wrap.left - (tester.view.physicalSize.width - wrap.right)).abs(),
      lessThan(40),
      reason: 'cards are horizontally centered',
    );

    final plusFive = tester.getRect(
      find.ancestor(of: find.text('+5'), matching: find.byType(ElevatedButton)),
    );
    expect(plusFive.bottom, greaterThan(screenHeight - 40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('counter drawer has no extra navigation actions in portrait', (
    tester,
  ) async {
    await pumpApp(tester, prefs: counterPrefs());
    await openDrawer(tester);

    final extraActionsBlock = find.byKey(
      const ValueKey('drawer-extra-actions'),
    );
    final settingsFooter = find.byKey(const ValueKey('drawer-settings-footer'));

    expect(extraActionsBlock, findsNothing);
    expect(settingsFooter, findsOneWidget);
  });

  testWidgets('settings page lays out sections side by side in landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'app_mode': 'counter',
      ...counterPrefs(),
    });
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);

    await openSettings(tester);

    final modeHeader = find.text('Spielmodus');
    final historyHeader = find.text('Verlauf');
    expect(modeHeader, findsOneWidget);
    expect(historyHeader, findsOneWidget);
    expect(
      (tester.getTopLeft(modeHeader).dx - tester.getTopLeft(historyHeader).dx)
          .abs(),
      greaterThan(150),
    );
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
      'app_mode': 'counter',
      ...counterPrefs(),
    });
    await tester.pumpWidget(const KartlerApp());
    await tester.pumpAndSettle();
    await dismissStartScreen(tester);

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
