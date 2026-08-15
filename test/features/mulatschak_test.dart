import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/app/app.dart';
import 'package:kartler/models/mulatschak_history_entry.dart';
import 'package:kartler/widgets/mulatschak_history_drawer.dart';
import 'package:kartler/widgets/score_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

Map<String, Object> threePlayerMulatschakPrefs() {
  return {
    ...mulatschakPrefs(lineup: {'p1': 21, 'p2': 21, 'p3': 21}),
    'players': jsonEncode([
      {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p2', 'name': 'Ben', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p3', 'name': 'Carla', 'createdAt': '2024-01-01T00:00:00.000Z'},
    ]),
  };
}

Map<String, Object> mulatschakAutoCompleteProfilePrefs() {
  return {
    'rule_profile': jsonEncode({
      'wattenWinningScore': 11,
      'mulatschakStartingScore': 21,
      'hosnObeStartingLives': 4,
      'muleqackEnabled': false,
      'muleqackTriggerPoints': 100,
      'muleqackResetPoints': 50,
      'mulatschakAutoCompleteRound': true,
    }),
  };
}

Finder playerScore(String playerName, int score) {
  return find.descendant(
    of: find.widgetWithText(ScoreCard, playerName),
    matching: find.text('$score'),
  );
}

Future<void> tapScoreButton(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<List<MulatschakHistoryEntry>> storedMulatschakHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonDecode(prefs.getString('mulatschak_history')!) as List;
  return encoded
      .cast<String>()
      .map(MulatschakHistoryEntry.decode)
      .whereType<MulatschakHistoryEntry>()
      .toList(growable: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mulatschak mode', () {
    testWidgets('empty lineup offers the lineup picker when players exist', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs(lineup: {}));

      expect(find.text('Noch keine Spieler'), findsOneWidget);
      expect(find.text('Wer spielt mit?'), findsOneWidget);
      expect(find.text('Spieler verwalten'), findsOneWidget);

      await tester.tap(find.text('Wer spielt mit?'));
      await tester.pumpAndSettle();

      expect(find.text('0 von 2 Spielern spielen mit.'), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
    });

    for (final scenario in const [
      (button: '-1', expectedScore: 20),
      (button: '+1', expectedScore: 22),
      (button: '-5', expectedScore: 16),
      (button: '+5', expectedScore: 26),
    ]) {
      testWidgets(
        'applies ${scenario.button} without automatic detection safely',
        (tester) async {
          await pumpApp(tester, prefs: mulatschakPrefs());

          await tapScoreButton(tester, scenario.button);

          expect(playerScore('Anna', scenario.expectedScore), findsOneWidget);
          expect(await storedMulatschakHistory(), hasLength(1));
        },
      );
    }

    testWidgets('does not show a reset button on the score screen', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('supports multiplier-based scoring and winner display', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      expect(find.text('Anna'), findsWidgets);
      expect(find.text('21'), findsNWidgets(2));

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('22'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mulatschakMultiplierButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2x'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('24'), findsOneWidget);
    });

    testWidgets('reorders players directly on the score screen', (
      tester,
    ) async {
      await pumpApp(tester, prefs: threePlayerMulatschakPrefs());

      final annaCard = find.byKey(const ValueKey('mulatschak-score-player-p1'));
      final benCard = find.byKey(const ValueKey('mulatschak-score-player-p2'));
      final gesture = await tester.startGesture(tester.getCenter(annaCard));

      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(benCard));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final lineup =
          jsonDecode(prefs.getString('mulatschak_lineup')!)
              as Map<String, dynamic>;
      expect(lineup.keys.toList(), ['p2', 'p1', 'p3']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('drops a player at the end when released outside a card', (
      tester,
    ) async {
      await pumpApp(tester, prefs: threePlayerMulatschakPrefs());

      final annaCard = find.byKey(const ValueKey('mulatschak-score-player-p1'));
      final plusFiveButton = find.text('+5');
      final gesture = await tester.startGesture(tester.getCenter(annaCard));

      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(plusFiveButton));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final lineup =
          jsonDecode(prefs.getString('mulatschak_lineup')!)
              as Map<String, dynamic>;
      expect(lineup.keys.toList(), ['p2', 'p3', 'p1']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('marks the winner and losers on the player cards', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: mulatschakPrefs(lineup: {'p1': 1, 'p2': 21}),
      );

      expect(find.text('Anna gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsNothing);

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('Anna gewinnt!'), findsNothing);
      expect(find.text('Gewinner'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Gewinner')).style?.color, Colors.green);
      expect(find.text('X'), findsOneWidget);
      expect(tester.widget<Text>(find.text('X')).style?.color, Colors.red);
      final cardSize = tester.getSize(find.widgetWithText(ScoreCard, 'Anna'));
      expect(cardSize.width, 176);
      expect(cardSize.height, 204);
    });

    testWidgets('keeps the score below the winner label', (tester) async {
      await pumpApp(
        tester,
        prefs: mulatschakPrefs(lineup: {'p1': 1, 'p2': 21}),
      );

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(
        tester.getBottomLeft(find.text('Gewinner')).dy,
        lessThan(tester.getTopLeft(find.text('0')).dy),
      );
    });

    testWidgets('keeps the winner label above the name in the handset grid', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        ...threePlayerMulatschakPrefs(),
        'mulatschak_lineup': jsonEncode({'p1': 1, 'p2': 21, 'p3': 21}),
      });
      await tester.pumpWidget(const KartlerApp());
      await tester.pumpAndSettle();
      await dismissStartScreen(tester);

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(
        tester.getBottomLeft(find.text('Gewinner')).dy,
        lessThan(tester.getTopLeft(find.text('Anna')).dy),
      );
      expect(
        tester.getBottomLeft(find.text('Gewinner')).dy,
        lessThan(tester.getTopLeft(find.text('Ben')).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('applies muleqack reset settings to scoring', (tester) async {
      await pumpApp(
        tester,
        prefs: {
          ...mulatschakPrefs(lineup: {'p1': 9, 'p2': 21}),
          'rule_profile': jsonEncode({
            'wattenWinningScore': 11,
            'mulatschakStartingScore': 21,
            'hosnObeStartingLives': 4,
            'muleqackEnabled': true,
            'muleqackTriggerPoints': 10,
            'muleqackResetPoints': 5,
          }),
        },
      );

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('auto-completes a five-trick round from -5', (tester) async {
      await pumpApp(
        tester,
        prefs: {...mulatschakPrefs(), ...mulatschakAutoCompleteProfilePrefs()},
      );

      await tester.tap(find.text('-5'));
      await tester.pumpAndSettle();

      expect(find.text('16'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('counts tricks independently from the score multiplier', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {...mulatschakPrefs(), ...mulatschakAutoCompleteProfilePrefs()},
      );

      await tester.tap(find.byKey(const Key('mulatschakMultiplierButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2x'));
      await tester.pumpAndSettle();

      for (var index = 0; index < 3; index++) {
        await tapScoreButton(tester, '-1');
      }
      expect(playerScore('Anna', 15), findsOneWidget);
      expect(playerScore('Ben', 21), findsOneWidget);

      for (var index = 0; index < 2; index++) {
        await tapScoreButton(tester, '-1');
      }
      expect(playerScore('Anna', 11), findsOneWidget);
      expect(playerScore('Ben', 31), findsOneWidget);
    });

    testWidgets('+1 marks a passed player and excludes them from auto +5', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...threePlayerMulatschakPrefs(),
          ...mulatschakAutoCompleteProfilePrefs(),
        },
      );

      await tapScoreButton(tester, '+1');
      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '-5');

      expect(playerScore('Anna', 22), findsOneWidget);
      expect(playerScore('Ben', 16), findsOneWidget);
      expect(playerScore('Carla', 26), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('safely completes a round when trick input exceeds five', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {...mulatschakPrefs(), ...mulatschakAutoCompleteProfilePrefs()},
      );

      await tapScoreButton(tester, '-1');
      await tapScoreButton(tester, '-5');

      expect(playerScore('Anna', 15), findsOneWidget);
      expect(playerScore('Ben', 26), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('mulatschak_round_tricks')!), isEmpty);
    });

    testWidgets('restores partial automatic trick detection after a restart', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {...mulatschakPrefs(), ...mulatschakAutoCompleteProfilePrefs()},
      );

      await tapScoreButton(tester, '-1');
      await tapScoreButton(tester, '-1');

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('mulatschak_round_tricks')!), {
        'p1': 2,
      });
      final persistedValues = <String, Object>{
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      };

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await pumpApp(tester, prefs: persistedValues);

      for (var index = 0; index < 3; index++) {
        await tapScoreButton(tester, '-1');
      }
      expect(playerScore('Anna', 16), findsOneWidget);
      expect(playerScore('Ben', 26), findsOneWidget);
    });

    testWidgets('restores a suppressed automatic round after a restart', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...threePlayerMulatschakPrefs(),
          ...mulatschakAutoCompleteProfilePrefs(),
        },
      );

      await tapScoreButton(tester, '+5');
      final prefs = await SharedPreferences.getInstance();
      final persistedValues = <String, Object>{
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      };

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await pumpApp(tester, prefs: persistedValues);

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '-5');

      expect(playerScore('Anna', 26), findsOneWidget);
      expect(playerScore('Ben', 16), findsOneWidget);
      expect(playerScore('Carla', 21), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'mulatschak_round_auto_suppressed',
        ),
        isTrue,
      );
    });

    testWidgets('undo and redo restore an auto-completed round atomically', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {...mulatschakPrefs(), ...mulatschakAutoCompleteProfilePrefs()},
      );

      await tapScoreButton(tester, '-5');
      expect(playerScore('Anna', 16), findsOneWidget);
      expect(playerScore('Ben', 26), findsOneWidget);

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(playerScore('Anna', 21), findsOneWidget);
      expect(playerScore('Ben', 21), findsOneWidget);
      expect(await storedMulatschakHistory(), isEmpty);

      await tester.tap(find.byTooltip('Wiederholen'));
      await tester.pumpAndSettle();
      expect(playerScore('Anna', 16), findsOneWidget);
      expect(playerScore('Ben', 26), findsOneWidget);
      expect(await storedMulatschakHistory(), hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('undo followed by tricks elsewhere stays in the same round', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...threePlayerMulatschakPrefs(),
          ...mulatschakAutoCompleteProfilePrefs(),
        },
      );

      await tapScoreButton(tester, '-1');
      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '-1');

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(playerScore('Ben', 21), findsOneWidget);

      await tester.tap(find.text('Carla'));
      await tester.pumpAndSettle();
      for (var index = 0; index < 4; index++) {
        await tapScoreButton(tester, '-1');
      }

      expect(playerScore('Anna', 20), findsOneWidget);
      expect(playerScore('Ben', 26), findsOneWidget);
      expect(playerScore('Carla', 17), findsOneWidget);
      final storedHistory = await storedMulatschakHistory();
      expect(storedHistory, isNotEmpty);
      expect(storedHistory.every((entry) => entry.round == 1), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('mulatschak_history_round'), 2);
    });

    testWidgets('automatically completes a split five-trick round', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...threePlayerMulatschakPrefs(),
          ...mulatschakAutoCompleteProfilePrefs(),
        },
      );

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('19'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(find.text('Runde vervollständigen'), findsNothing);
    });

    testWidgets('+5 first suppresses auto tricks until the round is complete', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...threePlayerMulatschakPrefs(),
          ...mulatschakAutoCompleteProfilePrefs(),
        },
      );

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('-5'));
      await tester.pumpAndSettle();

      expect(playerScore('Anna', 26), findsOneWidget);
      expect(playerScore('Ben', 16), findsOneWidget);
      expect(playerScore('Carla', 21), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('mulatschak_round_auto_suppressed'), isTrue);

      await tester.tap(find.text('Carla'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '+1');
      expect(prefs.getBool('mulatschak_round_auto_suppressed'), isFalse);

      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '-5');

      expect(playerScore('Anna', 21), findsOneWidget);
      expect(playerScore('Ben', 21), findsOneWidget);
      expect(playerScore('Carla', 27), findsOneWidget);
    });

    testWidgets('always records history and only hides its presentation', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await tapScoreButton(tester, '+1');

      expect(find.byTooltip('Mulatschak-Verlauf'), findsNothing);
      final historyBeforeEnabling = await storedMulatschakHistory();
      expect(historyBeforeEnabling, hasLength(1));
      expect(historyBeforeEnabling.single.playerName, 'Anna');
      expect(historyBeforeEnabling.single.points, 1);

      await openSettings(tester);
      await tester.ensureVisible(find.text('Mulatschak-Verlauf anzeigen'));
      await tester.tap(find.text('Mulatschak-Verlauf anzeigen'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mulatschak-Verlauf'));
      await tester.pumpAndSettle();
      expect(find.text('Anna'), findsWidgets);
      expect(find.text('+1 Punkte'), findsOneWidget);
    });

    testWidgets('groups history after every player received new points', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: {
          ...threePlayerMulatschakPrefs(),
          'mulatschak_history_enabled': true,
        },
      );

      await tapScoreButton(tester, '+1');
      await tapScoreButton(tester, '+1');
      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '-1');
      await tester.tap(find.text('Carla'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '+5');

      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '-5');
      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '+1');
      await tester.tap(find.text('Carla'));
      await tester.pumpAndSettle();
      await tapScoreButton(tester, '-1');

      final history = await storedMulatschakHistory();
      expect(history.map((entry) => entry.round), [1, 1, 1, 1, 2, 2, 2]);

      await tester.tap(find.byTooltip('Mulatschak-Verlauf'));
      await tester.pumpAndSettle();

      expect(find.text('Runde 1'), findsOneWidget);
      expect(find.text('Runde 2'), findsOneWidget);
      final historyDrawer = find.byType(Drawer);
      expect(
        find.descendant(of: historyDrawer, matching: find.text('Anna')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: historyDrawer, matching: find.text('Ben')),
        findsNWidgets(2),
      );
      expect(
        find.descendant(of: historyDrawer, matching: find.text('Carla')),
        findsNWidgets(2),
      );
    });

    testWidgets('shows quick repeated history changes as one summed entry', (
      tester,
    ) async {
      final history = [
        const MulatschakHistoryEntry(
          round: 1,
          time: '12:00:00',
          playerName: 'Anna',
          points: -1,
        ).encode(),
        const MulatschakHistoryEntry(
          round: 1,
          time: '12:00:12',
          playerName: 'Anna',
          points: -1,
        ).encode(),
        const MulatschakHistoryEntry(
          round: 1,
          time: '12:00:24',
          playerName: 'Anna',
          points: -1,
        ).encode(),
        const MulatschakHistoryEntry(
          round: 1,
          time: '12:00:54',
          playerName: 'Anna',
          points: -1,
        ).encode(),
      ];

      await tester.pumpWidget(
        MaterialApp(home: MulatschakHistoryDrawer(history: history)),
      );

      expect(find.text('Anna'), findsNWidgets(2));
      expect(find.text('-3 Punkte'), findsOneWidget);
      expect(find.text('12:00:00 - 12:00:24'), findsOneWidget);
      expect(find.text('-1 Punkte'), findsOneWidget);
      expect(find.text('12:00:54'), findsOneWidget);
    });

    testWidgets('supports undo of score changes', (tester) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text('22'), findsOneWidget);

      await tester.tap(find.byTooltip('Rückgängig'));
      await tester.pumpAndSettle();
      expect(find.text('21'), findsNWidgets(2));
    });

    testWidgets('persists the multiplier across sessions', (tester) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await tester.tap(find.byKey(const Key('mulatschakMultiplierButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4x'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('mulatschak_multiplier'), 4);
    });

    testWidgets('new game records the finished game and restarts at the '
        'starting score', (tester) async {
      await pumpApp(
        tester,
        prefs: mulatschakPrefs(lineup: {'p1': 5, 'p2': 21}),
      );

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final matches = jsonDecode(prefs.getString('match_history')!) as List;
      expect(matches, hasLength(1));
      expect(matches.single['gameType'], 'mulatschak');
      expect(matches.single['winnerId'], isNull);
      expect(matches.single['standings'], {'Anna': 5, 'Ben': 21});

      expect(find.text('21'), findsNWidgets(2));
      expect(find.text('Partie aufgezeichnet!'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('new game records the winner when a player reached zero', (
      tester,
    ) async {
      await pumpApp(
        tester,
        prefs: mulatschakPrefs(lineup: {'p1': 0, 'p2': 21}),
      );

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final matches = jsonDecode(prefs.getString('match_history')!) as List;
      expect(matches.single['winnerId'], 'p1');
    });

    testWidgets('new game clears the score history', (tester) async {
      await pumpApp(
        tester,
        prefs: {...mulatschakPrefs(), 'mulatschak_history_enabled': true},
      );

      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('mulatschak_history')!), isEmpty);
      expect(prefs.getInt('mulatschak_history_round'), 1);
    });

    testWidgets('new game on a fresh board does not record anything', (
      tester,
    ) async {
      await pumpApp(tester, prefs: mulatschakPrefs());

      await openDrawer(tester);
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('match_history'), isNull);
    });
  });
}
