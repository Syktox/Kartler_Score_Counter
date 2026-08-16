import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/models/app_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Counter mode', () {
    testWidgets('supports increment, reset and undo', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      expect(find.text('Punkte'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('supports adding, renaming and deleting counters', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Neuer Zähler'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Lese-Tage');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Lese-Tage'), findsOneWidget);

      await openDrawer(tester);
      await tester.tap(drawerActionForItem('Lese-Tage', 'Umbenennen'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Lese-Wochen');
      await tester.tap(find.widgetWithText(TextButton, 'Umbenennen'));
      await tester.pumpAndSettle();

      expect(find.text('Lese-Wochen'), findsWidgets);

      await openDrawer(tester);
      await tester.tap(drawerActionForItem('Lese-Wochen', 'Löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();
      await closeDrawer(tester);

      expect(find.text('Punkte'), findsOneWidget);
      expect(find.text('Lese-Wochen'), findsNothing);
    });

    testWidgets('shows counter history entries when enabled', (tester) async {
      await pumpApp(
        tester,
        prefs: {...counterPrefs(), 'counter_history_enabled': true},
      );

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zähler-Verlauf'));
      await tester.pumpAndSettle();

      expect(find.textContaining('erhöht'), findsOneWidget);
      expect(find.textContaining('zurückgesetzt'), findsOneWidget);
    });

    testWidgets('records counter history while its presentation is hidden', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Zähler-Verlauf'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      final history =
          jsonDecode(prefs.getString('counter_history')!)
              as Map<String, dynamic>;
      expect(history['Punkte'], hasLength(1));
      expect((history['Punkte'] as List).single, contains('erhöht'));
    });

    testWidgets('keeps counter history scoped to the selected counter', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...counterPrefs(),
          'counter_history_enabled': true,
          'counter_lineup': jsonEncode({'Punkte': 0, 'Runden': 0}),
          'current_counter': 'Punkte',
        },
      );

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await openDrawer(tester);
      await tester.tap(find.text('Runden'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zähler-Verlauf'));
      await tester.pumpAndSettle();

      expect(find.textContaining('erhöht'), findsNothing);
    });

    testWidgets('keeps undo history separate per mode', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await openDrawer(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.widgetWithText(ListTile, 'Einstellungen'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watten'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      final undoButton = find.ancestor(
        of: find.byTooltip('Rückgängig'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(undoButton).onPressed, isNull);

      await openDrawer(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.widgetWithText(ListTile, 'Einstellungen'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<AppMode>, 'Zähler'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(undoButton).onPressed, isNotNull);
    });

    testWidgets('normalizes counter names before saving', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Neuer Zähler'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        '  Doppelte  Leerzeichen ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Doppelte Leerzeichen'), findsOneWidget);
    });

    testWidgets('blocks decrement below zero when negatives are disabled', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await tester.tap(find.text('-'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('-1'), findsNothing);
    });

    testWidgets('allows negative scores when enabled', (tester) async {
      await pumpApp(
        tester,
        prefs: {...counterPrefs(), 'counter_negative_enabled': true},
      );

      await tester.tap(find.text('-'));
      await tester.pumpAndSettle();
      expect(find.text('-1'), findsOneWidget);

      await tester.tap(find.text('-'));
      await tester.pumpAndSettle();
      expect(find.text('-2'), findsOneWidget);
    });

    testWidgets('undo restores the score and history of a deleted counter', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          'app_mode': 'counter',
          'counter_lineup': jsonEncode({'Punkte': 3, 'Runden': 0}),
          'current_counter': 'Punkte',
        },
      );

      await openDrawer(tester);
      await tester.tap(drawerActionForItem('Punkte', 'Löschen'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();
      await closeDrawer(tester);

      expect(find.text('Punkte'), findsNothing);

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();

      expect(find.text('Punkte'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('keeps the score text large and buttons tappable', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      final scoreText = tester.widget<Text>(find.text('0'));
      expect(scoreText.style?.fontSize, greaterThanOrEqualTo(100));

      for (final label in ['+', '-', 'Reset']) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byType(ElevatedButton),
        );
        final size = tester.getSize(button.first);
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
    });
  });
}
