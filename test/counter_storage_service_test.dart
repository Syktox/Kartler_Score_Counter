import 'dart:convert';

import 'package:kartler/models/app_mode.dart';
import 'package:kartler/models/watten_game.dart';
import 'package:kartler/services/counter_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CounterStorageService', () {
    test('loads defaults when no values are stored', () async {
      SharedPreferences.setMockInitialValues({});

      final data = await CounterStorageService.load();

      expect(data.counters, CounterStorageService.defaultCounters);
      expect(data.currentCounter, CounterStorageService.defaultCurrentCounter);
      expect(
        data.wattenGames.keys,
        CounterStorageService.defaultWattenGames.keys,
      );
      expect(
        data.currentMulatschakPlayer,
        CounterStorageService.defaultCurrentMulatschakPlayer,
      );
      expect(data.hosnObePlayers, CounterStorageService.defaultHosnObePlayers);
      expect(
        data.currentHosnObePlayer,
        CounterStorageService.defaultCurrentHosnObePlayer,
      );
      expect(
        data.counterHistoryEnabled,
        CounterStorageService.defaultCounterHistoryEnabled,
      );
      expect(
        data.counterNegativeEnabled,
        CounterStorageService.defaultCounterNegativeEnabled,
      );
      expect(data.counterHistory, isEmpty);
      expect(
        data.mulatschakHistoryEnabled,
        CounterStorageService.defaultMulatschakHistoryEnabled,
      );
      expect(data.mulatschakHistory, isEmpty);
      expect(
        data.mulatschakHistoryRound,
        CounterStorageService.defaultMulatschakHistoryRound,
      );
      expect(data.mulatschakRoundPlayers, isEmpty);
      expect(data.appMode, AppMode.counter);
    });

    test('saves and loads a complete state roundtrip', () async {
      SharedPreferences.setMockInitialValues({});

      await CounterStorageService.save(
        counters: const {'Focus': 3},
        currentCounter: 'Focus',
        wattenGames: const {'Final': WattenGame(me: 11, you: 9)},
        currentWattenGame: 'Final',
        mulatschakPlayers: const {'Anna': 12, 'Ben': 8},
        currentMulatschakPlayer: 'Ben',
        hosnObePlayers: const {'Anna': 4, 'Ben': 2},
        currentHosnObePlayer: 'Anna',
        mulatschakMultiplier: 4,
        muleqackEnabled: true,
        muleqackTriggerPoints: 100,
        muleqackResetPoints: 50,
        counterHistoryEnabled: true,
        counterNegativeEnabled: true,
        counterHistory: const {
          'Focus': ['14:30:21 - increased.'],
        },
        mulatschakHistoryEnabled: true,
        mulatschakHistory: const [
          '{"round":1,"time":"14:31:00","player":"Anna","points":-4}',
        ],
        mulatschakHistoryRound: 2,
        mulatschakRoundPlayers: const ['Ben'],
        appMode: AppMode.mulatschak,
      );

      final data = await CounterStorageService.load();

      expect(data.counters, {'Focus': 3});
      expect(data.currentCounter, 'Focus');
      expect(data.wattenGames['Final']?.me, 11);
      expect(data.wattenGames['Final']?.you, 9);
      expect(data.currentWattenGame, 'Final');
      expect(data.mulatschakPlayers, {'Anna': 12, 'Ben': 8});
      expect(data.currentMulatschakPlayer, 'Ben');
      expect(data.hosnObePlayers, {'Anna': 4, 'Ben': 2});
      expect(data.currentHosnObePlayer, 'Anna');
      expect(data.mulatschakMultiplier, 4);
      expect(data.muleqackEnabled, isTrue);
      expect(data.muleqackTriggerPoints, 100);
      expect(data.muleqackResetPoints, 50);
      expect(data.counterHistoryEnabled, isTrue);
      expect(data.counterNegativeEnabled, isTrue);
      expect(data.counterHistory, {
        'Focus': ['14:30:21 - increased.'],
      });
      expect(data.mulatschakHistoryEnabled, isTrue);
      expect(data.mulatschakHistory, [
        '{"round":1,"time":"14:31:00","player":"Anna","points":-4}',
      ]);
      expect(data.mulatschakHistoryRound, 2);
      expect(data.mulatschakRoundPlayers, ['Ben']);
      expect(data.appMode, AppMode.mulatschak);
    });

    test('falls back safely for malformed and legacy stored data', () async {
      SharedPreferences.setMockInitialValues({
        'counters': 'not-json',
        'current_counter': 'Missing',
        'watten_games': jsonEncode({
          'Spiel 1': {'me': 2, 'you': 1},
        }),
        'current_watten_game': 'Spiel 1',
        'mulatschak_players': jsonEncode(<String, dynamic>{}),
        'current_mulatschak_player': 'Nobody',
        'hosn_obe_players': jsonEncode(<String, dynamic>{}),
        'current_hosn_obe_player': 'Nobody',
        'mulatschak_multiplier': -2,
        'muleqack_enabled': true,
        'muleqack_trigger_points': 0,
        'muleqack_reset_points': -5,
        'counter_history_enabled': true,
        'counter_history': jsonEncode({
          'Counter': ['14:30:21 - Counter increased.'],
        }),
        'mulatschak_history_enabled': true,
        'mulatschak_history': jsonEncode([
          '{"round":1,"time":"14:31:00","player":"Player 1","points":-1}',
        ]),
        'mulatschak_history_round': 3,
        'mulatschak_round_players': jsonEncode(['Player 1', 'Nobody']),
        'app_mode': 'unknown-mode',
      });

      final data = await CounterStorageService.load();

      expect(data.counters, CounterStorageService.defaultCounters);
      expect(data.currentCounter, CounterStorageService.defaultCurrentCounter);
      expect(data.wattenGames.containsKey('Game 1'), isTrue);
      expect(data.wattenGames['Game 1']?.me, 2);
      expect(data.wattenGames['Game 1']?.you, 1);
      expect(data.currentWattenGame, 'Game 1');
      expect(
        data.mulatschakPlayers,
        CounterStorageService.defaultMulatschakPlayers,
      );
      expect(
        data.currentMulatschakPlayer,
        CounterStorageService.defaultCurrentMulatschakPlayer,
      );
      expect(data.hosnObePlayers, CounterStorageService.defaultHosnObePlayers);
      expect(
        data.currentHosnObePlayer,
        CounterStorageService.defaultCurrentHosnObePlayer,
      );
      expect(
        data.mulatschakMultiplier,
        CounterStorageService.defaultMulatschakMultiplier,
      );
      expect(data.muleqackEnabled, isTrue);
      expect(
        data.muleqackTriggerPoints,
        CounterStorageService.defaultMuleqackTriggerPoints,
      );
      expect(
        data.muleqackResetPoints,
        CounterStorageService.defaultMuleqackResetPoints,
      );
      expect(data.counterHistoryEnabled, isTrue);
      expect(data.counterHistory, {
        'Counter': ['14:30:21 - Counter increased.'],
      });
      expect(data.mulatschakHistoryEnabled, isTrue);
      expect(data.mulatschakHistory, [
        '{"round":1,"time":"14:31:00","player":"Player 1","points":-1}',
      ]);
      expect(data.mulatschakHistoryRound, 3);
      expect(data.mulatschakRoundPlayers, ['Player 1']);
      expect(data.appMode, CounterStorageService.defaultAppMode);
    });

    test('migrates legacy flat counter history lists', () async {
      SharedPreferences.setMockInitialValues({
        'counters': jsonEncode({'Focus': 3}),
        'current_counter': 'Focus',
        'counter_history_enabled': true,
        'counter_history': <String>[
          '14:30:21 - Focus increased.',
          '14:29:10 - Focus decreased.',
        ],
      });

      final data = await CounterStorageService.load();

      expect(data.counterHistoryEnabled, isTrue);
      expect(data.counterHistory, {
        'Focus': ['14:30:21 - Focus increased.', '14:29:10 - Focus decreased.'],
      });
    });

    test('ignores malformed counter history safely', () async {
      SharedPreferences.setMockInitialValues({
        'counter_history_enabled': true,
        'counter_history': 'not-json',
      });

      final data = await CounterStorageService.load();

      expect(data.counterHistoryEnabled, isTrue);
      expect(data.counterHistory, isEmpty);
    });
  });
}
