import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/app/theme/app_theme.dart';
import 'package:kartler/widgets/score_card.dart';

void main() {
  AnimatedContainer scoreCardContainer(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ScoreCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
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

    final border =
        (scoreCardContainer(tester).foregroundDecoration! as BoxDecoration)
            .border! as Border;
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

    final container = scoreCardContainer(tester);
    final decoration = container.foregroundDecoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, theme.colorScheme.primary);
    expect(border.top.width, 2);
    expect((container.decoration! as BoxDecoration).color, isNot(Colors.transparent));
  });

  testWidgets('score text stays at the same position when the value changes', (
    tester,
  ) async {
    final theme = AppTheme.light();

    Future<Rect> rectFor(int score, {String title = 'Anna'}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 176,
                height: 240,
                child: ScoreCard(
                  title: title,
                  score: score,
                  isSelected: false,
                  onTap: () {},
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.text('$score'));
    }

    final base = await rectFor(21);
    final sameWidthDigit = await rectFor(22);
    expect(sameWidthDigit.center.dy, base.center.dy);
    expect(sameWidthDigit.height, base.height);
    expect(sameWidthDigit.center.dx, base.center.dx);
    expect(await rectFor(-21), isNot(base));

    final minus = await rectFor(-21);
    expect(minus.center.dy, base.center.dy);
    expect(minus.height, base.height);

    final wide = await rectFor(21000);
    expect(wide.center.dy, base.center.dy, reason: 'scaled score must not shift');
    expect(wide.center.dx, base.center.dx, reason: 'scaled score must stay centered');
    expect(tester.takeException(), isNull);
  });

  testWidgets('score text does not move when the name wraps to two lines', (
    tester,
  ) async {
    final theme = AppTheme.light();

    Future<Rect> rectFor(String title, WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 176,
                height: 240,
                child: ScoreCard(
                  title: title,
                  score: 21,
                  isSelected: false,
                  onTap: () {},
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.text('21'));
    }

    Future<Rect> nameRectFor(String title, WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 176,
                height: 240,
                child: ScoreCard(
                  title: title,
                  score: 21,
                  isSelected: false,
                  onTap: () {},
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.text(title));
    }

    final oneLineNameHeight = (await nameRectFor('Anna', tester)).height;
    final twoLineNameHeight = (await nameRectFor(
      'Schnapskartl Maria Theresia',
      tester,
    )).height;
    expect(twoLineNameHeight, greaterThan(oneLineNameHeight));

    final oneLineScore = await rectFor('Anna', tester);
    final twoLineScore = await rectFor('Schnapskartl Maria Theresia', tester);
    expect(
      twoLineScore,
      oneLineScore,
      reason: 'wrapped name must not move the score',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tight card keeps the score position when the value changes', (
    tester,
  ) async {
    final theme = AppTheme.light();

    Future<Rect> rectFor(int score) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 148,
                height: 172,
                child: ScoreCard(
                  title: 'Anna',
                  score: score,
                  isSelected: false,
                  onTap: () {},
                  padding: const EdgeInsets.fromLTRB(8, 44, 8, 12),
                  compact: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.text('$score'));
    }

    final base = await rectFor(21);
    final next = await rectFor(22);
    expect(next.center.dy, base.center.dy);
    expect(next.height, base.height);

    final wide = await rectFor(21000);
    expect(wide.center.dy, base.center.dy);
    expect(tester.takeException(), isNull);
  });
}
