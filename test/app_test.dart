import 'dart:convert';

import 'package:counter_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Counter mode', () {
    testWidgets('supports increment, reset and undo', (tester) async {
      await _pumpApp(tester);

      expect(find.text('Workout streak'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('supports adding, renaming and deleting counters', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _openDrawer(tester);
      await tester.tap(find.text('New Counter'));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'Reading streak');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Reading streak'), findsOneWidget);

      await _openDrawer(tester);
      await tester.tap(_drawerActionForItem('Reading streak', 'Rename item'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Reading days');
      await tester.tap(find.widgetWithText(TextButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Reading days'), findsWidgets);

      await _openDrawer(tester);
      await tester.tap(_drawerActionForItem('Reading days', 'Delete item'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      await _closeDrawer(tester);

      expect(find.text('Workout streak'), findsOneWidget);
      expect(find.text('Reading days'), findsNothing);
    });

    testWidgets('shows counter history when enabled', (tester) async {
      await _pumpApp(tester);

      await _openSettings(tester);
      await tester.tap(find.text('Counter history'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Counter history'));
      await tester.pumpAndSettle();

      expect(find.textContaining('increased.'), findsOneWidget);
      expect(find.textContaining('reseted.'), findsOneWidget);
      expect(find.textContaining('Workout streak increased.'), findsNothing);
    });

    testWidgets('keeps counter history scoped to the selected counter', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _openSettings(tester);
      await tester.tap(find.text('Counter history'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await _openDrawer(tester);
      await tester.tap(find.text('New Counter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Reading streak');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Counter history'));
      await tester.pumpAndSettle();

      expect(find.text('Reading streak'), findsWidgets);
      expect(find.textContaining('increased.'), findsOneWidget);
      expect(find.textContaining('Workout streak increased.'), findsNothing);
    });

    testWidgets('keeps add field focused for duplicate counter names', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _openDrawer(tester);
      await tester.tap(find.text('New Counter'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Workout streak');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AlertDialog, 'Add Counter'), findsOneWidget);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.enterText(find.byType(TextField), 'Reading streak');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Reading streak'), findsOneWidget);
    });

    testWidgets('keeps undo history separate per mode', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await _openSettings(tester);
      await tester.tap(find.text('Watten'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Me'), findsOneWidget);
      expect(tester.widget<IconButton>(_undoButton()).onPressed, isNull);

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);

      await _openSettings(tester);
      await tester.tap(find.text('Counter'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Workout streak'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Workout streak'), findsOneWidget);
    });
  });

  group('Watten mode', () {
    testWidgets('supports score updates and side reset', (tester) async {
      await _pumpApp(
        tester,
        sharedPreferences: {
          'app_mode': 'watten',
          'watten_games': jsonEncode({
            'Game 1': {'me': 4, 'you': 7},
          }),
          'current_watten_game': 'Game 1',
        },
      );

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);

      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+3'));
      await tester.pumpAndSettle();
      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('10'), findsNothing);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('supports winner display and game management', (tester) async {
      await _pumpApp(
        tester,
        sharedPreferences: {
          'app_mode': 'watten',
          'watten_games': jsonEncode({
            'Game 1': {'me': 9, 'you': 0},
          }),
          'current_watten_game': 'Game 1',
        },
      );

      await tester.tap(find.text('+2'));
      await tester.pumpAndSettle();
      expect(find.text('Me wins'), findsOneWidget);

      await _openDrawer(tester);
      await tester.tap(find.text('Add Game'));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'Finale');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await _openDrawer(tester);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Finale')),
        findsOneWidget,
      );
      await _closeDrawer(tester);

      await _openDrawer(tester);
      await tester.tap(_drawerActionForItem('Finale', 'Delete item'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Me wins'), findsOneWidget);

      await _openDrawer(tester);
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Game 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text('Finale')),
        findsNothing,
      );
    });
  });

  group('Mulatschak mode', () {
    testWidgets('supports multiplier-based scoring and winner display', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        sharedPreferences: {
          'app_mode': 'mulatschak',
          'mulatschak_players': jsonEncode({'Player 1': 1, 'Player 2': 21}),
          'current_mulatschak_player': 'Player 1',
        },
      );

      expect(
        find.descendant(
          of: find.byKey(const Key('mulatschakMultiplierButton')),
          matching: find.text('1x'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();
      expect(find.text('Player 1 wins'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mulatschakMultiplierButton')));
      await tester.pumpAndSettle();
      expect(find.text('128x'), findsOneWidget);
      await tester.tap(find.text('4x').last);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('mulatschakMultiplierButton')),
          matching: find.text('4x'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('clamps multiplier subtraction at zero', (tester) async {
      await _pumpApp(
        tester,
        sharedPreferences: {
          'app_mode': 'mulatschak',
          'mulatschak_players': jsonEncode({'Player 1': 4, 'Player 2': 21}),
          'current_mulatschak_player': 'Player 1',
          'mulatschak_multiplier': 8,
        },
      );

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('Player 1 wins'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows mulatschak history grouped by completed rounds', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        sharedPreferences: {
          'app_mode': 'mulatschak',
          'mulatschak_players': jsonEncode({'Player 1': 21, 'Player 2': 21}),
          'current_mulatschak_player': 'Player 1',
        },
      );

      await _openSettings(tester);
      await tester.tap(find.text('Mulatschak history'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Player 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Player 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Mulatschak history'));
      await tester.pumpAndSettle();

      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Player 1'), findsWidgets);
      expect(find.text('Player 2'), findsWidgets);
      expect(find.text('-1 points'), findsOneWidget);
      expect(find.text('+1 points'), findsNWidgets(2));
    });

    testWidgets('supports adding, renaming and deleting players', (
      tester,
    ) async {
      await _pumpApp(tester, sharedPreferences: {'app_mode': 'mulatschak'});

      await _openDrawer(tester);
      await tester.tap(find.text('Add Player'));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'Chris');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Chris'), findsWidgets);

      await tester.tap(_drawerActionForItem('Chris', 'Rename item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Alex');
      await tester.tap(find.widgetWithText(TextButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsWidgets);

      await tester.tap(_drawerActionForItem('Alex', 'Delete item'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      await _closeDrawer(tester);

      expect(find.text('Alex'), findsNothing);
      expect(find.text('Player 1'), findsOneWidget);
    });

    testWidgets('keeps add field focused for duplicate player names', (
      tester,
    ) async {
      await _pumpApp(tester, sharedPreferences: {'app_mode': 'mulatschak'});

      await _openDrawer(tester);
      await tester.tap(find.text('Add Player'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Player 1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AlertDialog, 'Add Player'), findsOneWidget);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.enterText(find.byType(TextField), 'Chris');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Chris'), findsWidgets);
    });

    testWidgets('applies muleqack reset settings to scoring', (tester) async {
      await _pumpApp(
        tester,
        sharedPreferences: {
          'app_mode': 'mulatschak',
          'mulatschak_players': jsonEncode({'Player 1': 95, 'Player 2': 21}),
          'current_mulatschak_player': 'Player 1',
        },
      );

      await _openSettings(tester);
      await tester.tap(find.text('Mulatschak'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SwitchListTile, 'Mulatschak reset'));
      await tester.pumpAndSettle();

      await tester.enterText(
        _textFieldWithLabel('Reset when score reaches'),
        '100',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.enterText(_textFieldWithLabel('Reset score to'), '50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();

      expect(find.text('50'), findsOneWidget);
      expect(find.text('100'), findsNothing);
    });
  });

  group('Hosn Obe mode', () {
    testWidgets('supports winner detection and reset to four lives', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        sharedPreferences: {
          'app_mode': 'hosnObe',
          'hosn_obe_players': jsonEncode({'Player 1': 1, 'Player 2': 1}),
          'current_hosn_obe_player': 'Player 1',
        },
      );

      expect(find.text('1'), findsNWidgets(2));

      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('Player 2 wins'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('4'), findsNWidgets(2));
      expect(find.text('Player 2 wins'), findsNothing);
    });

    testWidgets('supports adding, renaming and deleting players', (
      tester,
    ) async {
      await _pumpApp(tester, sharedPreferences: {'app_mode': 'hosnObe'});

      await _openDrawer(tester);
      await tester.tap(find.text('Add Player'));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'Chris');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Chris'), findsWidgets);

      await tester.tap(_drawerActionForItem('Chris', 'Rename item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Alex');
      await tester.tap(find.widgetWithText(TextButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsWidgets);

      await tester.tap(_drawerActionForItem('Alex', 'Delete item'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      await _closeDrawer(tester);

      expect(find.text('Alex'), findsNothing);
      expect(find.text('Player 1'), findsOneWidget);
    });
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> sharedPreferences = const {},
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 2200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues(sharedPreferences);
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

Future<void> _openDrawer(WidgetTester tester) async {
  final scaffoldState = tester.state<ScaffoldState>(
    find.byType(Scaffold).first,
  );
  scaffoldState.openDrawer();
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await _openDrawer(tester);
  await tester.tap(
    find.descendant(of: find.byType(Drawer), matching: find.text('Settings')),
  );
  await tester.pumpAndSettle();
}

Future<void> _closeDrawer(WidgetTester tester) async {
  final scaffoldState = tester.state<ScaffoldState>(
    find.byType(Scaffold).first,
  );
  scaffoldState.closeDrawer();
  await tester.pumpAndSettle();
}

Finder _drawerActionForItem(String itemName, String tooltip) {
  final itemTile = find.ancestor(
    of: find
        .descendant(of: find.byType(Drawer), matching: find.text(itemName))
        .last,
    matching: find.byType(ListTile),
  );

  return find.descendant(of: itemTile, matching: find.byTooltip(tooltip));
}

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

Finder _undoButton() {
  return find.ancestor(
    of: find.byTooltip('Undo'),
    matching: find.byType(IconButton),
  );
}
