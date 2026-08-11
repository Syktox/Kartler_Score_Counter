import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/main.dart';
import 'package:kartler/models/app_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deaktiviert die Haptik-Plattformkanäle: Im Widget-Test meldet die Flutter
/// Tester-Umgebung Android/iOS und HapticFeedback-Aufrufe würden sonst nie
/// abschließen (hängende Futures).
void mockPlatformChannel(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async => null,
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
}

/// Pumped die App mit Mock-Speicher und überspringt das Onboarding, das beim
/// ersten Start erscheint: Die Tests landen direkt im gewählten Modus.
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 2200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  mockPlatformChannel(tester);

  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(const KartlerApp());
  await tester.pumpAndSettle();
  await dismissOnboarding(tester);
}

/// Überspringt das Onboarding (falls sichtbar) und wählt den Modus aus den
/// Mock-Prefs (Standard: Watten).
Future<void> dismissOnboarding(WidgetTester tester) async {
  if (find.text('Was möchtest du spielen?').evaluate().isEmpty) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  final modeName = prefs.getString('app_mode') ?? 'watten';
  final label = AppMode.values
      .firstWhere((mode) => mode.name == modeName)
      .label;
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Map<String, Object> counterPrefs({String mode = 'counter'}) {
  return {
    'app_mode': mode,
    'counter_lineup': jsonEncode({'Punkte': 0}),
    'current_counter': 'Punkte',
  };
}

Map<String, Object> wattenPrefs() {
  return {
    'app_mode': 'watten',
    'watten_lineup': jsonEncode({
      'Spiel 1': {'me': 0, 'you': 0},
    }),
    'current_watten_game': 'Spiel 1',
  };
}

Map<String, Object> playerPrefs() {
  return {
    'players': jsonEncode([
      {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p2', 'name': 'Ben', 'createdAt': '2024-01-01T00:00:00.000Z'},
    ]),
  };
}

Map<String, Object> mulatschakPrefs({Map<String, int>? lineup}) {
  return {
    'app_mode': 'mulatschak',
    ...playerPrefs(),
    'mulatschak_lineup': jsonEncode(lineup ?? {'p1': 21, 'p2': 21}),
    'current_mulatschak_player': 'p1',
    'mulatschak_multiplier': 1,
  };
}

Map<String, Object> hosnObePrefs({Map<String, int>? lineup}) {
  return {
    'app_mode': 'hosnObe',
    ...playerPrefs(),
    'hosn_obe_lineup': jsonEncode(lineup ?? {'p1': 4, 'p2': 4}),
    'current_hosn_obe_player': 'p1',
  };
}

Future<void> openDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
  await tester.pumpAndSettle();
}

Future<void> closeDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
  await tester.pumpAndSettle();
}

Future<void> openSettings(WidgetTester tester) async {
  await openDrawer(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(Drawer),
      matching: find.widgetWithText(ListTile, 'Einstellungen'),
    ),
  );
  await tester.pumpAndSettle();
}

Finder drawerTileForItem(String itemName) {
  return find.ancestor(
    of: find
        .descendant(of: find.byType(Drawer), matching: find.text(itemName))
        .last,
    matching: find.byType(ListTile),
  );
}

Finder drawerActionForItem(String itemName, String tooltip) {
  return find.descendant(
    of: drawerTileForItem(itemName),
    matching: find.byTooltip(tooltip),
  );
}
