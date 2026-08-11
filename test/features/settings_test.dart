import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings', () {
    testWidgets('toggles haptic feedback and persists it', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openSettings(tester);
      await tester.tap(find.text('Haptisches Feedback'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('haptics_enabled'), isFalse);
    });

    testWidgets('toggles the counter history and negative counters', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openSettings(tester);
      await tester.tap(find.text('Zähler-Verlauf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Negative Zähler erlauben'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('counter_history_enabled'), isTrue);
      expect(prefs.getBool('counter_negative_enabled'), isTrue);
    });

    testWidgets('allows negative counters when enabled', (tester) async {
      await pumpApp(
        tester,
        prefs: {...counterPrefs(), 'counter_negative_enabled': true},
      );

      await tester.tap(find.text('-'));
      await tester.pumpAndSettle();

      expect(find.text('-1'), findsOneWidget);
    });

    testWidgets('blocks negative counters by default', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await tester.tap(find.text('-'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('-1'), findsNothing);
    });

    testWidgets('updates the watten winning score via the rule profile', (
      tester,
    ) async {
      await pumpApp(tester, prefs: wattenPrefs());

      await openSettings(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Watten: Siegpunktzahl'),
        '15',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final profile = jsonDecode(
        prefs.getString('rule_profile')!,
      ) as Map<String, dynamic>;
      expect(profile['wattenWinningScore'], 15);
    });

    testWidgets('resets the rule profile to defaults', (tester) async {
      await pumpApp(
        tester,
        prefs: {
          ...wattenPrefs(),
          'rule_profile': jsonEncode({
            'wattenWinningScore': 15,
            'mulatschakStartingScore': 21,
            'hosnObeStartingLives': 4,
            'muleqackEnabled': false,
            'muleqackTriggerPoints': 100,
            'muleqackResetPoints': 50,
          }),
        },
      );

      await openSettings(tester);
      await tester.tap(find.text('Regeln zurücksetzen'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final profile = jsonDecode(
        prefs.getString('rule_profile')!,
      ) as Map<String, dynamic>;
      expect(profile['wattenWinningScore'], 11);
    });

    testWidgets('opens privacy, donation and bug report pages', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openSettings(tester);
      await tester.tap(find.text('Datenschutz'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spenden'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Support Kartler'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(AppBar, 'Support Kartler'),
          matching: find.byType(BackButton),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fehler melden'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Onboarding', () {
    testWidgets('shows the mode selection on every start, even with saved '
        'settings', (tester) async {
      SharedPreferences.setMockInitialValues({'app_mode': 'counter'});
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();

      expect(find.text('Was möchtest du spielen?'), findsOneWidget);
      expect(find.text('Watten'), findsOneWidget);

      await tester.tap(find.text('Mulatschak'));
      await tester.pumpAndSettle();

      expect(find.text('Was möchtest du spielen?'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_mode'), 'mulatschak');
    });

    testWidgets('can be skipped', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Überspringen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();

      expect(find.text('Was möchtest du spielen?'), findsNothing);
    });

    testWidgets('tap on default mode (Watten) dismisses onboarding',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Watten'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watten'));
      await tester.pumpAndSettle();

      expect(find.text('Was möchtest du spielen?'), findsNothing);
    });
  });
}
