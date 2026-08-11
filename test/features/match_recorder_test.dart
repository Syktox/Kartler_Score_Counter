import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/core/haptics_service.dart';
import 'package:kartler/features/counter/counter_controller.dart';
import 'package:kartler/features/game_session/session_controller.dart';
import 'package:kartler/features/home/match_recorder.dart';
import 'package:kartler/features/hosn_obe/hosn_obe_controller.dart';
import 'package:kartler/features/mulatschak/mulatschak_controller.dart';
import 'package:kartler/features/players/players_controller.dart';
import 'package:kartler/features/settings/settings_controller.dart';
import 'package:kartler/features/watten/watten_controller.dart';
import 'package:kartler/models/app_mode.dart';
import 'package:kartler/persistence/repositories/counter_repository.dart';
import 'package:kartler/persistence/repositories/hosn_obe_repository.dart';
import 'package:kartler/persistence/repositories/match_history_repository.dart';
import 'package:kartler/persistence/repositories/mulatschak_repository.dart';
import 'package:kartler/persistence/repositories/player_repository.dart';
import 'package:kartler/persistence/repositories/session_repository.dart';
import 'package:kartler/persistence/repositories/settings_repository.dart';
import 'package:kartler/persistence/repositories/watten_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsController settings;
  late PlayersController players;
  late CounterController counter;
  late WattenController watten;
  late MulatschakController mulatschak;
  late HosnObeController hosnObe;
  late SessionController sessions;
  late MatchRecorder recorder;

  Future<void> setUpControllers(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    settings = SettingsController(repository: const SettingsRepository());
    players = PlayersController(
      repository: const PlayerRepository(),
      haptics: HapticsService(isEnabled: () => false),
    );
    counter = CounterController(
      repository: const CounterRepository(),
      settings: settings,
      haptics: HapticsService(isEnabled: () => false),
    );
    watten = WattenController(
      repository: const WattenRepository(),
      settings: settings,
      haptics: HapticsService(isEnabled: () => false),
    );
    mulatschak = MulatschakController(
      repository: const MulatschakRepository(),
      settings: settings,
      players: players,
      haptics: HapticsService(isEnabled: () => false),
    );
    hosnObe = HosnObeController(
      repository: const HosnObeRepository(),
      settings: settings,
      players: players,
      haptics: HapticsService(isEnabled: () => false),
    );
    sessions = SessionController(
      sessionRepository: const SessionRepository(),
      matchRepository: const MatchHistoryRepository(),
      haptics: HapticsService(isEnabled: () => false),
    );
    recorder = MatchRecorder(
      counter: counter,
      watten: watten,
      mulatschak: mulatschak,
      hosnObe: hosnObe,
      players: players,
      sessions: sessions,
    );
    await Future.wait([
      settings.load(),
      players.load(),
      counter.load(),
      watten.load(),
      mulatschak.load(),
      hosnObe.load(),
      sessions.load(),
    ]);
  }

  Map<String, Object> playersPrefs() {
    return {
      'players': jsonEncode([
        {'id': 'p1', 'name': 'Anna', 'createdAt': '2024-01-01T00:00:00.000Z'},
        {'id': 'p2', 'name': 'Ben', 'createdAt': '2024-01-01T00:00:00.000Z'},
      ]),
    };
  }

  test('records a mulatschak match with winner and resets the board', () async {
    await setUpControllers({
      ...playersPrefs(),
      'mulatschak_lineup': jsonEncode({'p1': 0, 'p2': 21}),
      'current_mulatschak_player': 'p1',
      'mulatschak_multiplier': 1,
    });

    final match = await recorder.record(AppMode.mulatschak, resetBoard: true);

    expect(sessions.matches.single.id, match.id);
    expect(match.winnerId, 'p1');
    expect(match.finalStandings, {'Anna': 0, 'Ben': 21});
    expect(match.participantIds, ['p1', 'p2']);

    final startingScore = settings.ruleProfile.mulatschakStartingScore;
    expect(mulatschak.lineup, {'p1': startingScore, 'p2': startingScore});
  });

  test(
    'records a watten match with side labels and resets the board',
    () async {
      await setUpControllers({
        'watten_lineup': jsonEncode({
          'Spiel 1': {'me': 11, 'you': 7},
        }),
        'current_watten_game': 'Spiel 1',
      });

      final match = await recorder.record(AppMode.watten, resetBoard: false);

      expect(match.winnerId, isNull);
      expect(match.winnerLabel, 'Wir');
      expect(match.finalStandings, {'Wir': 11, 'Die': 7});
      expect(watten.games[watten.currentGame]!.me, 11);
    },
  );

  test('records a counter match without participants or winner', () async {
    await setUpControllers({
      'counter_lineup': jsonEncode({'Punkte': 12}),
      'current_counter': 'Punkte',
    });

    final match = await recorder.record(AppMode.counter, resetBoard: true);

    expect(match.winnerId, isNull);
    expect(match.winnerLabel, isNull);
    expect(match.participantIds, isEmpty);
    expect(match.finalStandings, {'Punkte': 12});
    expect(counter.counters['Punkte'], 0);
  });

  test('previewFor shows the current standings without recording', () async {
    await setUpControllers({
      ...playersPrefs(),
      'hosn_obe_lineup': jsonEncode({'p1': 0, 'p2': 4}),
      'current_hosn_obe_player': 'p1',
    });

    final preview = recorder.previewFor(AppMode.hosnObe);

    expect(preview.winnerId, 'p2');
    expect(preview.standings, [
      (name: 'Anna', score: 0),
      (name: 'Ben', score: 4),
    ]);
    expect(sessions.matches, isEmpty);
  });

  test('records against the active session and attaches the match', () async {
    await setUpControllers({
      ...playersPrefs(),
      'mulatschak_lineup': jsonEncode({'p1': 5, 'p2': 21}),
      'current_mulatschak_player': 'p1',
      'mulatschak_multiplier': 1,
    });
    await sessions.startSession(['p1', 'p2']);

    await recorder.record(AppMode.mulatschak, resetBoard: false);

    expect(sessions.matches.single.sessionId, sessions.activeSession!.id);
    expect(sessions.activeSession!.matchIds, [sessions.matches.single.id]);
  });
}
