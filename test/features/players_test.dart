import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Carla');
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
        find.widgetWithText(TextField, 'Name'),
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

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Anna');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();

      expect(
        find.text('Dieser Spielername ist bereits vergeben.'),
        findsOneWidget,
      );
    });

    testWidgets('does not add new players to the lineups automatically', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Spieler verwalten'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Spieler hinzufügen'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Carla');
      await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Carla'), findsNothing);
      expect(find.text('21'), findsNWidgets(2));
    });
  });
}
