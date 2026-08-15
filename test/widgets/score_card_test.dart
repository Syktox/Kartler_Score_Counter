import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/app/theme/app_theme.dart';
import 'package:kartler/widgets/score_card.dart';

void main() {
  BoxDecoration scoreCardDecoration(WidgetTester tester) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ScoreCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets('unselected player card has a visible light-mode border', (
    tester,
  ) async {
    final theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ScoreCard(
            title: 'Anna',
            score: 21,
            isSelected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    final border = scoreCardDecoration(tester).border! as Border;
    expect(border.top.color, theme.colorScheme.outline);
    expect(border.top.width, greaterThan(1));
    expect(border.top.color, isNot(theme.colorScheme.surface));
  });

  testWidgets('selected player card uses the primary light-mode outline', (
    tester,
  ) async {
    final theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ScoreCard(
            title: 'Anna',
            score: 21,
            isSelected: true,
            onTap: () {},
          ),
        ),
      ),
    );

    final decoration = scoreCardDecoration(tester);
    final border = decoration.border! as Border;
    expect(border.top.color, theme.colorScheme.primary);
    expect(border.top.width, 2);
    expect(decoration.color, isNot(Colors.transparent));
  });
}
