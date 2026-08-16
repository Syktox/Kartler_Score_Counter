import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Player management', () {
    testWidgets('adds, renames and deletes a global player', (tester) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Spieler hinzufügen'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Carla');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();

      expect(find.text('Carla'), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Carla'),
          matching: find.byIcon(Icons.edit_outlined),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Carla Maria',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Carla Maria'), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Carla Maria'),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
      await tester.pumpAndSettle();

      expect(find.text('Carla Maria'), findsNothing);
    });

    testWidgets('rejects duplicate player names', (tester) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Spieler hinzufügen'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();

      expect(
        find.text('Dieser Spielername ist bereits vergeben.'),
        findsOneWidget,
      );
    });

    testWidgets('adds new players to the Mulatschak lineup automatically', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Spieler hinzufügen'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Carla');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('21'), findsNWidgets(3));

      final prefs = await SharedPreferences.getInstance();
      final players = jsonDecode(prefs.getString('players')!) as List;
      final carla = players.cast<Map<String, dynamic>>().singleWhere(
        (player) => player['name'] == 'Carla',
      );
      final lineup =
          jsonDecode(prefs.getString('mulatschak_lineup')!)
              as Map<String, dynamic>;
      expect(lineup.keys, contains(carla['id']));
    });

    testWidgets('adds new players to the Hosn Obe lineup automatically', (
      tester,
    ) async {
      await pumpApp(tester, prefs: hosnObePrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Spieler hinzufügen'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Carla');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(3));

      final prefs = await SharedPreferences.getInstance();
      final players = jsonDecode(prefs.getString('players')!) as List;
      final carla = players.cast<Map<String, dynamic>>().singleWhere(
        (player) => player['name'] == 'Carla',
      );
      final lineup =
          jsonDecode(prefs.getString('hosn_obe_lineup')!)
              as Map<String, dynamic>;
      expect(lineup.keys, contains(carla['id']));
    });

    testWidgets('deletes a player without confirmation when disabled', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...mulatschakPrefs(),
          'player_delete_confirmation_enabled': false,
        },
      );

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Ben'),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spieler löschen'), findsNothing);
      expect(find.text('Ben'), findsNothing);
    });

    testWidgets('empty lineup button follows player add and delete changes', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      for (final playerName in ['Anna', 'Ben']) {
        await tester.tap(
          find.descendant(
            of: find.widgetWithText(ListTile, playerName),
            matching: find.byIcon(Icons.delete_outline),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
        await tester.pumpAndSettle();
      }

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Noch keine Spieler'), findsOneWidget);
      expect(find.text('Wer spielt mit?'), findsNothing);
      expect(find.text('Spieler verwalten'), findsOneWidget);

      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Spieler hinzufügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Carla');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Noch keine Spieler'), findsNothing);
      expect(find.text('Wer spielt mit?'), findsNothing);
      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
    });
  });
}
