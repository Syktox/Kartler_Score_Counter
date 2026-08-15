import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
import 'package:kartler/persistence/backup_service.dart';
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

    testWidgets('reflects toggled switches in the settings UI', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openSettings(tester);
      final switchFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Haptisches Feedback'),
          matching: find.byType(SwitchListTile),
        ),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      await tester.tap(find.text('Haptisches Feedback'));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });

    testWidgets('switching the theme persists the selection', (tester) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openSettings(tester);
      await tester.tap(find.text('Dunkel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    testWidgets('toggles the counter history and negative counters', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openSettings(tester);
      await tester.tap(find.text('Zähler-Verlauf anzeigen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Negative Zähler erlauben'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('counter_history_enabled'), isTrue);
      expect(prefs.getBool('counter_negative_enabled'), isTrue);
    });

    testWidgets('offers Watten history separately from counter settings', (
      tester,
    ) async {
      await pumpApp(tester, prefs: counterPrefs());

      await openSettings(tester);
      expect(find.text('Verlauf'), findsOneWidget);
      expect(find.text('Watten-Verlauf anzeigen'), findsOneWidget);
      expect(find.text('Zähler'), findsAtLeastNWidgets(2));

      await tester.tap(find.text('Watten-Verlauf anzeigen'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('watten_history_enabled'), isTrue);
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
      final profile =
          jsonDecode(prefs.getString('rule_profile')!) as Map<String, dynamic>;
      expect(profile['wattenWinningScore'], 15);
    });

    testWidgets(
      'toggles mulatschak round auto-completion in the rule profile',
      (tester) async {
        await pumpApp(tester, prefs: mulatschakPrefs());

        await openSettings(tester);
        await tester.ensureVisible(
          find.text('Mulatschak-Stiche automatisch erkennen'),
        );
        await tester.tap(find.text('Mulatschak-Stiche automatisch erkennen'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        final profile =
            jsonDecode(prefs.getString('rule_profile')!)
                as Map<String, dynamic>;
        expect(profile['mulatschakAutoCompleteRound'], isTrue);
      },
    );

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
      final profile =
          jsonDecode(prefs.getString('rule_profile')!) as Map<String, dynamic>;
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

  group('Backup', () {
    testWidgets('export copies a valid backup to the clipboard', (
      tester,
    ) async {
      await pumpApp(tester, prefs: playerPrefs());

      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await openSettings(tester);
      await tester.ensureVisible(find.text('Backup exportieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup exportieren'));
      await tester.pumpAndSettle();

      expect(
        find.text('Backup in die Zwischenablage kopiert.'),
        findsOneWidget,
      );
      expect(clipboardText, isNotNull);
      final document = jsonDecode(clipboardText!) as Map<String, dynamic>;
      expect(document[BackupService.formatKey], BackupService.formatVersion);
      final values = document[BackupService.valuesKey] as Map<String, dynamic>;
      expect(values['players'], contains('Anna'));
    });

    testWidgets('import restores players from a pasted backup', (tester) async {
      SharedPreferences.setMockInitialValues(playerPrefs());
      mockPlatformChannel(tester);
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();
      await dismissStartScreen(tester);

      final backup = await const BackupService().exportJson();

      await openSettings(tester);
      await tester.ensureVisible(find.text('Backup wiederherstellen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup wiederherstellen'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, backup);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.text('Daten ersetzen?'), findsOneWidget);
      await tester.tap(find.text('Importieren'));
      await tester.pumpAndSettle();

      expect(
        find.text('Backup erfolgreich wiederhergestellt.'),
        findsOneWidget,
      );
      expect(find.text('Einstellungen'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('players'), contains('Anna'));
    });
  });

  group('StartScreen', () {
    testWidgets(
      'shows the mode selection on every start, even with saved settings',
      (tester) async {
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
      },
    );

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

    testWidgets('tap on default mode (Watten) dismisses the start screen', (
      tester,
    ) async {
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
