import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drawer reorder area stops above settings in landscape', (
    tester,
  ) async {
    await _pumpLandscapeApp(
      tester,
      sharedPreferences: {
        'counters': jsonEncode({'One': 0, 'Two': 0, 'Three': 0}),
        'current_counter': 'One',
      },
    );
    await _openDrawer(tester);

    final list = find.byType(ReorderableListView);
    final boundary = find.ancestor(
      of: list,
      matching: find.byType(DragBoundary),
    );
    final clip = find.ancestor(of: list, matching: find.byType(ClipRect));
    final settings = find.descendant(
      of: find.byType(Drawer),
      matching: find.widgetWithText(ListTile, 'Settings'),
    );
    final settingsFooter = find.byKey(const ValueKey('drawer-settings-footer'));

    expect(boundary, findsOneWidget);
    expect(clip, findsWidgets);
    expect(settingsFooter, findsOneWidget);
    expect(tester.widget<KeyedSubtree>(settingsFooter).child, isA<Material>());
    expect(
      tester.getBottomRight(boundary).dy,
      lessThanOrEqualTo(tester.getTopLeft(settings).dy),
    );
  });

  testWidgets('desktop reorder proxy cannot paint over settings', (
    tester,
  ) async {
    await _pumpLandscapeApp(
      tester,
      sharedPreferences: {
        'counters': jsonEncode({'One': 0, 'Two': 0, 'Three': 0}),
        'current_counter': 'One',
      },
    );
    await _openDrawer(tester);

    final dragHandle = find.byIcon(Icons.drag_handle).first;
    final settings = find.descendant(
      of: find.byType(Drawer),
      matching: find.widgetWithText(ListTile, 'Settings'),
    );
    final gesture = await tester.startGesture(tester.getCenter(dragHandle));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(settings));
    await tester.pump();

    final proxy = find.byKey(const ValueKey('drawer-reorder-proxy'));
    expect(proxy, findsOneWidget);
    expect(
      tester.getBottomRight(proxy).dy,
      lessThanOrEqualTo(tester.getTopLeft(settings).dy),
    );
    expect(
      tester
          .widget<Material>(
            find.byKey(const ValueKey('drawer-reorder-proxy-material')),
          )
          .elevation,
      0,
    );
    expect(
      tester.getBottomRight(proxy).dy,
      lessThanOrEqualTo(
        tester
            .getTopLeft(find.byKey(const ValueKey('drawer-settings-footer')))
            .dy,
      ),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('counter name field stays visible above landscape keyboard', (
    tester,
  ) async {
    await _pumpLandscapeApp(tester);
    await _openDrawer(tester);
    await tester.drag(find.byType(ReorderableListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Counter'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      tester.getBottomRight(field).dy,
      lessThanOrEqualTo(tester.view.physicalSize.height - 180),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLandscapeApp(
  WidgetTester tester, {
  Map<String, Object> sharedPreferences = const {},
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 360);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues(sharedPreferences);
  await tester.pumpWidget(const KartlerApp());
  await tester.pumpAndSettle();
}

Future<void> _openDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
  await tester.pumpAndSettle();
}
