import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hub', () {
    testWidgets('separates modes from game sessions with section headers', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.text('Spielmodus'), findsOneWidget);
      expect(find.text('Spielabend'), findsOneWidget);
      expect(find.text('Watten'), findsOneWidget);
      expect(find.text('Spielabend starten'), findsOneWidget);
    });

    testWidgets('mode card switches the app mode', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mulatschak'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulatschak'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_mode'), 'mulatschak');
    });
  });
}
