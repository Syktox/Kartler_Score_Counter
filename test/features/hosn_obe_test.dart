import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hosn Obe mode', () {
    testWidgets('empty lineup offers the lineup picker when players exist', (
      tester,
    ) async {
      await pumpApp(tester, prefs: hosnObePrefs(lineup: {}));

      expect(find.text('Noch keine Spieler'), findsOneWidget);
      expect(find.text('Wer spielt mit?'), findsOneWidget);
      expect(find.text('Spieler verwalten'), findsOneWidget);

      await tester.tap(find.text('Wer spielt mit?'));
      await tester.pumpAndSettle();

      expect(find.text('0 von 2 Spielern spielen mit.'), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
    });

    testWidgets('supports winner detection and reset to starting lives', (
      tester,
    ) async {
      await pumpApp(tester, prefs: hosnObePrefs(lineup: {'p1': 1, 'p2': 1}));

      expect(find.text('Ben gewinnt!'), findsNothing);

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('Ben gewinnt!'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('4'), findsNWidgets(2));
      expect(find.text('Ben gewinnt!'), findsNothing);
    });

    testWidgets('supports undo after losing a life', (tester) async {
      await pumpApp(tester, prefs: hosnObePrefs());

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsNWidgets(2));
    });

    testWidgets('keeps the selected player highlighted', (tester) async {
      await pumpApp(tester, prefs: hosnObePrefs());

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Ben'), findsWidgets);
    });
  });
}
