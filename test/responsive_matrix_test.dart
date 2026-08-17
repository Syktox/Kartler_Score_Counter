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
  tester.view.padding = FakeViewPadding(
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
  addTearDown(tester.view.resetPadding);

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
            greaterThanOrEqualTo(size.height - bottom - 40),
            reason:
                '$size $top/$bottom: controls stay near the bottom safe edge',
          );
          expect(
            tester.getRect(_plusFiveButton()).bottom,
            lessThanOrEqualTo(size.height - bottom),
            reason:
                '$size $top/$bottom: controls stay above the gesture safe '
                'area',
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

  testWidgets('mulatschak landscape: buttons fill the right side on every phone', (
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
        final safeLeft = left;
        final safeRight = size.width - right;
        final safeBottom = screenHeight - bottom;
        final bodyCenter = left + (size.width - left - right) / 2;
        final contentCenter = (62.0 + (safeBottom - 6.0)) / 2;

        expect(
          minusFive.center.dx,
          greaterThan(bodyCenter),
          reason: '$size $left/$right/$bottom: controls sit on the right',
        );
        expect(
          minusFive.top,
          lessThan(plusFive.top),
          reason: '$size $left/$right/$bottom: -5 sits above +5',
        );
        expect(
          minusFive.bottom,
          lessThan(plusFive.top),
          reason:
              '$size $left/$right/$bottom: buttons are stacked vertically',
        );
        expect(
          multiplier.right,
          lessThan(minusFive.left),
          reason:
              '$size $left/$right/$bottom: multiplier sits beside the '
              'buttons',
        );
        expect(
          (multiplier.center.dy - contentCenter).abs(),
          lessThan(40),
          reason:
              '$size $left/$right/$bottom: multiplier is vertically '
              'centered',
        );
        expect(
          plusFive.bottom,
          lessThanOrEqualTo(safeBottom),
          reason:
              '$size $left/$right/$bottom: buttons stay above the bottom '
              'safe area',
        );
        expect(
          plusFive.bottom,
          greaterThan(safeBottom - 20),
          reason:
              '$size $left/$right/$bottom: buttons fill the height down to '
              'the bottom edge',
        );
        expect(
          minusFive.top,
          lessThanOrEqualTo(56 + 40),
          reason:
              '$size $left/$right/$bottom: buttons start right below the '
              'app bar',
        );
        expect(
          plusFive.right,
          lessThanOrEqualTo(safeRight - 10),
          reason:
              '$size $left/$right/$bottom: buttons stay inside the right '
              'safe area',
        );
        expect(
          multiplier.left,
          greaterThanOrEqualTo(safeLeft + 10),
          reason:
              '$size $left/$right/$bottom: multiplier stays inside the left '
              'safe area',
        );
        expect(
          firstCard.right,
          lessThan(multiplier.left),
          reason:
              '$size $left/$right/$bottom: player cards stay left of the '
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
