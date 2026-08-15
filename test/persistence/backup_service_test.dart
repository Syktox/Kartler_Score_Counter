import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/persistence/backup_service.dart';
import 'package:kartler/persistence/schema.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _service = BackupService();

Map<String, Object> _populatedPrefs() {
  return {
    'players': jsonEncode([
      {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
      {'id': 'p2', 'name': 'Ben', 'createdAt': '2024-01-01T00:00:00.000Z'},
    ]),
    'game_sessions': jsonEncode([
      {
        'id': 's1',
        'startTime': '2026-01-05T20:00:00.000Z',
        'participants': ['p1', 'p2'],
        'matches': ['m1'],
      },
    ]),
    'match_history': jsonEncode([
      {
        'id': 'm1',
        'sessionId': 's1',
        'gameType': 'mulatschak',
        'participants': ['p1', 'p2'],
        'winnerId': 'p2',
        'startedAt': '2026-01-05T21:00:00.000Z',
        'endedAt': '2026-01-05T21:30:00.000Z',
        'standings': {'p1': 5, 'p2': 21},
      },
    ]),
    'theme_mode': 'dark',
    'app_mode': 'mulatschak',
    'player_delete_confirmation_enabled': false,
    'counter_lineup': jsonEncode({'Punkte': 12}),
    'current_counter': 'Punkte',
    'mulatschak_round_tricks': jsonEncode({'p1': 2}),
    'mulatschak_round_auto_suppressed': true,
    'rule_profile': jsonEncode({
      'wattenWinningScore': 15,
      'mulatschakStartingScore': 21,
      'hosnObeStartingLives': 4,
      'muleqackEnabled': false,
      'muleqackTriggerPoints': 100,
      'muleqackResetPoints': 50,
    }),
  };
}

Map<String, dynamic> _decode(String json) =>
    jsonDecode(json) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService export', () {
    test('exports all relevant data with a schema version', () async {
      SharedPreferences.setMockInitialValues(_populatedPrefs());

      final document = _decode(await _service.exportJson());

      expect(document[BackupService.formatKey], BackupService.formatVersion);
      expect(document[BackupService.schemaVersionKey], StorageSchema.current);
      expect(document[BackupService.exportedAtKey], isA<String>());
      final values = document[BackupService.valuesKey] as Map<String, dynamic>;
      expect(values['players'], isA<String>());
      expect(values['game_sessions'], isA<String>());
      expect(values['match_history'], isA<String>());
      expect(values['app_mode'], 'mulatschak');
      expect(values['player_delete_confirmation_enabled'], isFalse);
      expect(values['counter_lineup'], isA<String>());
      expect(values['mulatschak_round_tricks'], contains('"p1":2'));
      expect(values['mulatschak_round_auto_suppressed'], isTrue);
      expect(values.containsKey('schema_version'), isFalse);
    });
  });

  group('BackupService import', () {
    test('round trip: export then import restores all data', () async {
      SharedPreferences.setMockInitialValues(_populatedPrefs());
      final exported = await _service.exportJson();

      SharedPreferences.setMockInitialValues({'app_mode': 'counter'});
      await _service.importJson(exported);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_mode'), 'mulatschak');
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getBool('player_delete_confirmation_enabled'), isFalse);
      expect(prefs.getString('players'), contains('Anna'));
      expect(prefs.getString('game_sessions'), contains('s1'));
      expect(prefs.getString('match_history'), contains('m1'));
      expect(prefs.getString('counter_lineup'), contains('Punkte'));
      expect(prefs.getString('current_counter'), 'Punkte');
      expect(prefs.getString('mulatschak_round_tricks'), contains('"p1":2'));
      expect(prefs.getBool('mulatschak_round_auto_suppressed'), isTrue);
    });

    test(
      'accepts only the known keys and keeps schema version current',
      () async {
        SharedPreferences.setMockInitialValues(_populatedPrefs());
        final exported = await _service.exportJson();

        SharedPreferences.setMockInitialValues({});
        await _service.importJson(exported);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('schema_version'), StorageSchema.current);
      },
    );

    test('rejects a backup from a newer app version', () async {
      SharedPreferences.setMockInitialValues({});
      final json = jsonEncode({
        BackupService.formatKey: BackupService.formatVersion,
        BackupService.schemaVersionKey: StorageSchema.current + 1,
        BackupService.exportedAtKey: DateTime.now().toIso8601String(),
        BackupService.valuesKey: <String, dynamic>{},
      });

      await expectLater(
        _service.importJson(json),
        throwsA(isA<BackupException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('rejects invalid JSON', () async {
      SharedPreferences.setMockInitialValues({});

      await expectLater(
        _service.importJson('kein json {'),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a document without data', () async {
      SharedPreferences.setMockInitialValues({});
      final json = jsonEncode({
        BackupService.formatKey: BackupService.formatVersion,
        BackupService.schemaVersionKey: StorageSchema.current,
        BackupService.exportedAtKey: DateTime.now().toIso8601String(),
      });

      await expectLater(
        _service.importJson(json),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects corrupt player entries', () async {
      SharedPreferences.setMockInitialValues({});
      final json = jsonEncode({
        BackupService.formatKey: BackupService.formatVersion,
        BackupService.schemaVersionKey: StorageSchema.current,
        BackupService.exportedAtKey: DateTime.now().toIso8601String(),
        BackupService.valuesKey: {
          'players': jsonEncode([
            {'id': 'p1'},
          ]),
        },
      });

      await expectLater(
        _service.importJson(json),
        throwsA(isA<BackupException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('players'), isNull);
    });

    test('rejects corrupt match entries', () async {
      SharedPreferences.setMockInitialValues({});
      final json = jsonEncode({
        BackupService.formatKey: BackupService.formatVersion,
        BackupService.schemaVersionKey: StorageSchema.current,
        BackupService.exportedAtKey: DateTime.now().toIso8601String(),
        BackupService.valuesKey: {
          'match_history': jsonEncode([
            {
              'id': 'm1',
              'gameType': 'unbekannt',
              'standings': <String, dynamic>{},
            },
          ]),
        },
      });

      await expectLater(
        _service.importJson(json),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a document with an unknown backup format', () async {
      SharedPreferences.setMockInitialValues({});
      final json = jsonEncode({
        BackupService.formatKey: 99,
        BackupService.schemaVersionKey: StorageSchema.current,
        BackupService.valuesKey: <String, dynamic>{},
      });

      await expectLater(
        _service.importJson(json),
        throwsA(isA<BackupException>()),
      );
    });

    test('does not touch existing data when the import is invalid', () async {
      SharedPreferences.setMockInitialValues({
        'app_mode': 'watten',
        'players': jsonEncode([
          {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
        ]),
      });

      final json = jsonEncode({
        BackupService.formatKey: BackupService.formatVersion,
        BackupService.schemaVersionKey: StorageSchema.current,
        BackupService.exportedAtKey: DateTime.now().toIso8601String(),
        BackupService.valuesKey: {'players': 'korrupt'},
      });

      await expectLater(
        _service.importJson(json),
        throwsA(isA<BackupException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_mode'), 'watten');
      expect(prefs.getString('players'), contains('Anna'));
    });
  });
}
