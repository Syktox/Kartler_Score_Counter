import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/persistence/migrations/v1_player_migration.dart';
import 'package:kartler/persistence/migrations/v2_rule_profile_migration.dart';
import 'package:kartler/persistence/schema.dart';
import 'package:kartler/persistence/storage_facade.dart';
import 'package:kartler/persistence/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageSchema', () {
    test('starts at version 2', () {
      expect(StorageSchema.current, 2);
    });

    test('migrations chain from 0 to the current version', () {
      var version = 0;
      for (final migration in AppStorage.orderedMigrations) {
        expect(migration.fromVersion, version);
        expect(migration.toVersion, version + 1);
        version = migration.toVersion;
      }
      expect(version, StorageSchema.current);
    });
  });

  group('V1 player migration', () {
    test('migrates mode-internal players into global players', () async {
      SharedPreferences.setMockInitialValues({
        'schema_version': 0,
        'counters': jsonEncode({'Punkte': 3}),
        'current_counter': 'Punkte',
        'watten_games': jsonEncode({
          'Spiel 1': {'me': 5, 'you': 2},
        }),
        'current_watten_game': 'Spiel 1',
        'mulatschak_players': jsonEncode({'Anna': 21, 'Ben': 14}),
        'current_mulatschak_player': 'Ben',
        'mulatschak_history_round': 2,
        'mulatschak_round_players': jsonEncode(['Anna']),
        'hosn_obe_players': jsonEncode({'Anna': 4, 'Carla': 2}),
        'current_hosn_obe_player': 'Carla',
        'muleqack_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await V1PlayerMigration().run(prefs);

      final players = jsonDecode(prefs.getString(StorageKeys.players)!) as List;
      expect(players, hasLength(3));
      final names = players.map((player) => (player as Map)['name']).toSet();
      expect(names, {'Anna', 'Ben', 'Carla'});
      final anna = players.cast<Map>().firstWhere(
        (player) => player['name'] == 'Anna',
      );
      expect(anna['id'], isNotEmpty);

      final idsByName = <String, String>{
        for (final player in players.cast<Map>())
          player['name'] as String: player['id'] as String,
      };

      final lineup = jsonDecode(
        prefs.getString(StorageKeys.mulatschakLineup)!,
      ) as Map<String, dynamic>;
      expect(
        lineup.keys.toSet(),
        {idsByName['Anna'], idsByName['Ben']},
      );
      expect(lineup[idsByName['Anna']], 21);
      expect(lineup[idsByName['Ben']], 14);

      final currentPlayerId = prefs.getString(
        StorageKeys.currentMulatschakPlayer,
      );
      expect(currentPlayerId, idsByName['Ben']);

      final hosnObeLineup = jsonDecode(
        prefs.getString(StorageKeys.hosnObeLineup)!,
      ) as Map<String, dynamic>;
      expect(
        hosnObeLineup.keys.toSet(),
        {idsByName['Anna'], idsByName['Carla']},
      );
      expect(hosnObeLineup[idsByName['Carla']], 2);

      final roundPlayers = jsonDecode(
        prefs.getString(StorageKeys.mulatschakRoundPlayers)!,
      ) as List;
      expect(roundPlayers, [idsByName['Anna']]);
      expect(prefs.getInt(StorageKeys.mulatschakHistoryRound), 2);

      final counters = jsonDecode(
        prefs.getString(StorageKeys.counterLineup)!,
      ) as Map<String, dynamic>;
      expect(counters, {'Punkte': 3});

      final wattenGames = jsonDecode(
        prefs.getString(StorageKeys.wattenLineup)!,
      ) as Map<String, dynamic>;
      expect((wattenGames['Spiel 1'] as Map)['me'], 5);

      // Legacy-Keys wurden entfernt.
      expect(prefs.containsKey('mulatschak_players'), isFalse);
      expect(prefs.containsKey('watten_games'), isFalse);
      expect(prefs.containsKey('muleqack_enabled'), isFalse);
    });
  });

  group('V2 rule profile migration', () {
    test('consolidates muleqack keys into the rule profile', () async {
      SharedPreferences.setMockInitialValues({
        'schema_version': 1,
        'muleqack_enabled': true,
        'muleqack_trigger_points': 120,
        'muleqack_reset_points': 40,
      });
      final prefs = await SharedPreferences.getInstance();

      await V2RuleProfileMigration().run(prefs);

      final profile = jsonDecode(
        prefs.getString(StorageKeys.ruleProfile)!,
      ) as Map<String, dynamic>;
      expect(profile['muleqackEnabled'], isTrue);
      expect(profile['muleqackTriggerPoints'], 120);
      expect(profile['muleqackResetPoints'], 40);
      expect(profile['wattenWinningScore'], 11);

      expect(prefs.containsKey('muleqack_enabled'), isFalse);
      expect(prefs.containsKey('muleqack_trigger_points'), isFalse);
      expect(prefs.containsKey('muleqack_reset_points'), isFalse);
    });
  });

  group('AppStorage.init', () {
    test('runs all migrations and writes the current schema version', () async {
      SharedPreferences.setMockInitialValues({
        'mulatschak_players': jsonEncode({'Anna': 21}),
        'current_mulatschak_player': 'Anna',
        'muleqack_enabled': true,
        'muleqack_trigger_points': 100,
        'muleqack_reset_points': 50,
      });
      final prefs = await SharedPreferences.getInstance();

      await AppStorage.init();

      expect(prefs.getInt(StorageKeys.schemaVersion), StorageSchema.current);
      expect(prefs.getString(StorageKeys.players), isNotNull);
      expect(prefs.getString(StorageKeys.ruleProfile), isNotNull);
      expect(prefs.containsKey('mulatschak_players'), isFalse);
    });

    test('does not touch data when the schema is already current', () async {
      SharedPreferences.setMockInitialValues({
        'schema_version': 2,
        'players': jsonEncode([
          {
            'id': 'p1',
            'name': 'Anna',
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
        ]),
      });
      final prefs = await SharedPreferences.getInstance();

      await AppStorage.init();

      expect(prefs.getString(StorageKeys.players), isNotNull);
      expect(prefs.getInt(StorageKeys.schemaVersion), 2);
    });
  });
}
