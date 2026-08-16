import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

/// Responsive + safe-area smoke matrix for the screens touched by the
/// landscape/centering/keyboard fixes (Mulatschak, player management dialog).
/// Covers the full phone viewport matrix in both orientations and the
/// cutout/notch/Dynamic-Island profiles required by AGENTS.md.

const _portraitSizes = <Size>[
  Size(320, 568),
  Size(360, 640),
  Size(360, 740),
  Size(375, 667),
  Size(375, 812),
  Size(390, 844),
  Size(393, 852),
  Size(412, 732),
  Size(412, 915),
  Size(414, 896),
  Size(430, 932),
  Size(480, 960),
];

const _portraitSafeAreas = <(double, double)>[
  (0, 0),
  (44, 34),
  (59, 34),
  (32, 24),
];

const _landscapeSafeAreas = <(double, double, double)>[
  (0, 0, 0),
  (59, 0, 21),
  (0, 59, 21),
  (44, 44, 21),
];

Future<void> _pumpMulatschak(
  WidgetTester tester,
  Size size, {
  Map<String, int>? lineup,
  EdgeInsets viewPadding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewPadding = FakeViewPadding(
    top: viewPadding.top,
    right: viewPadding.right,
    bottom: viewPadding.bottom,
    left: viewPadding.left,
  );
  tester.view.viewInsets = FakeViewPadding(bottom: viewInsets.bottom);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);

  SharedPreferences.setMockInitialValues(mulatschakPrefs(lineup: lineup));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(const KartlerApp());
  await tester.pumpAndSettle();
  await dismissStartScreen(tester);
}

Finder _minusFiveButton() =>
    find.ancestor(of: find.text('-5'), matching: find.byType(ElevatedButton));

Finder _plusFiveButton() =>
    find.ancestor(of: find.text('+5'), matching: find.byType(ElevatedButton));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mulatschak portrait: fewer than three players stay centered', (
    tester,
  ) async {
    for (final size in _portraitSizes) {
      for (final (top, bottom) in _portraitSafeAreas) {
        for (final count in const [2, 1]) {
          final lineup = {'p1': 21, if (count == 2) 'p2': 21};
          await _pumpMulatschak(
            tester,
            size,
            lineup: lineup,
            viewPadding: EdgeInsets.only(top: top, bottom: bottom),
          );

          final card = tester.getRect(
            find.byKey(const ValueKey('mulatschak-score-player-p1')),
          );
          final wrap = tester.getRect(find.byType(Wrap).first);
          final screenHeight = size.height;
          final center = card.center.dy;
          expect(
            center,
            greaterThan(screenHeight * 0.25),
            reason:
                '$size $top/$bottom: $count players must be vertically '
                'centered, not pinned to the top',
          );
          expect(center, lessThan(screenHeight * 0.75));
          expect(
            (wrap.left - (size.width - wrap.right)).abs(),
            lessThan(40),
            reason: '$size $top/$bottom: cards must be horizontally centered',
          );
          expect(_plusFiveButton(), findsOneWidget);
          expect(
            tester.getRect(_plusFiveButton()).bottom,
            greaterThan(size.height - 40),
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('mulatschak portrait: grids of three or more players stay safe', (
    tester,
  ) async {
    for (final size in _portraitSizes) {
      for (final (top, bottom) in _portraitSafeAreas) {
        await _pumpMulatschak(
          tester,
          size,
          lineup: const {'p1': 21, 'p2': 21, 'p3': 21},
          viewPadding: EdgeInsets.only(top: top, bottom: bottom),
        );

        expect(find.byType(GridView), findsOneWidget);
        expect(_plusFiveButton(), findsOneWidget);
        expect(
          find.byKey(const ValueKey('mulatschak-score-player-p1')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('mulatschak landscape: controls fill the page on every phone', (
    tester,
  ) async {
    for (final portrait in _portraitSizes) {
      final size = Size(portrait.height, portrait.width);
      for (final (left, right, bottom) in _landscapeSafeAreas) {
        await _pumpMulatschak(
          tester,
          size,
          lineup: const {'p1': 21, 'p2': 21},
          viewPadding: EdgeInsets.only(
            left: left,
            right: right,
            bottom: bottom,
          ),
        );
        final minusFive = tester.getRect(_minusFiveButton());
        final plusFive = tester.getRect(_plusFiveButton());
        final multiplier = tester.getRect(
          find.byKey(const Key('mulatschakMultiplierButton')),
        );
        final firstCard = tester.getRect(
          find.byKey(const ValueKey('mulatschak-score-player-p1')),
        );
        final screenHeight = size.height;
        final safeBottom = bottom;
        final bodyCenter = left + (size.width - left - right) / 2;

        expect(
          (minusFive.top - plusFive.top).abs(),
          lessThan(2),
          reason: '$size $left/$right/$bottom: buttons sit on one line',
        );
        expect(
          multiplier.bottom,
          lessThan(minusFive.top),
          reason:
              '$size $left/$right/$bottom: multiplier sits above the '
              'buttons',
        );
        expect(
          (multiplier.center.dx - bodyCenter).abs(),
          lessThan(60),
          reason:
              '$size $left/$right/$bottom: multiplier is horizontally '
              'centered',
        );
        expect(
          plusFive.bottom,
          greaterThan(screenHeight - safeBottom - 24),
          reason: '$size $left/$right/$bottom: buttons reach the bottom edge',
        );
        expect(minusFive.height, greaterThan(60));
        expect(plusFive.height, greaterThan(60));
        expect(
          firstCard.top,
          lessThan(multiplier.top),
          reason:
              '$size $left/$right/$bottom: player cards stay above the '
              'controls',
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
    'player duplicate-name bubble appears above the keyboard everywhere',
    (tester) async {
      final configurations = <Size>[
        for (final size in _portraitSizes)
          if (size == const Size(320, 568) ||
              size == const Size(390, 844) ||
              size == const Size(430, 932))
            size,
        for (final size in _portraitSizes)
          if (size == const Size(320, 568) ||
              size == const Size(390, 844) ||
              size == const Size(430, 932))
            Size(size.height, size.width),
      ];

      for (final size in configurations) {
        final isLandscape = size.width > size.height;
        final profiles = isLandscape
            ? _landscapeSafeAreas.toList()
            : [
                for (final profile in _portraitSafeAreas)
                  (profile.$1, 0.0, profile.$2),
              ];

        for (final (left, right, bottom) in profiles) {
          await _pumpMulatschak(
            tester,
            size,
            viewPadding: EdgeInsets.only(
              left: isLandscape ? left : 0,
              right: isLandscape ? right : 0,
              top: isLandscape ? 0 : left,
              bottom: bottom,
            ),
          );

          await openDrawer(tester);
          await tester.drag(
            find.byType(ReorderableListView),
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Spieler verwalten'));
          await tester.tap(find.text('Spieler verwalten'));
          await tester.pumpAndSettle();

          await tester.tap(
            find.widgetWithText(FilledButton, 'Spieler hinzufügen'),
          );
          await tester.pumpAndSettle();

          final keyboard = (size.height * 0.4).roundToDouble();
          tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(TextField), 'Anna');
          await tester.tap(find.widgetWithText(FilledButton, 'Hinzufügen'));
          await tester.pumpAndSettle();

          final bubble = find.text('Dieser Spielername ist bereits vergeben.');
          expect(
            bubble,
            findsOneWidget,
            reason:
                '$size ($left/$right/$bottom): duplicate-name message '
                'must be shown',
          );
          final bubbleRect = tester.getRect(bubble);
          expect(
            bubbleRect.bottom,
            lessThanOrEqualTo(size.height - keyboard + 12),
            reason:
                '$size ($left/$right/$bottom): bubble must sit above the '
                'keyboard',
          );
          expect(
            bubbleRect.bottom,
            greaterThan(size.height - keyboard - 70),
            reason:
                '$size ($left/$right/$bottom): bubble stays near the '
                'keyboard',
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
