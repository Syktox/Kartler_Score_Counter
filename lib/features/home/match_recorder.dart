import 'dart:convert';

import '../../models/app_mode.dart';
import '../../models/completed_match.dart';
import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../counter/counter_controller.dart';
import '../game_session/finish_match_sheet.dart';
import '../game_session/session_controller.dart';
import '../hosn_obe/hosn_obe_controller.dart';
import '../mulatschak/mulatschak_controller.dart';
import '../players/players_controller.dart';
import '../watten/watten_controller.dart';

/// Koordiniert das Aufzeichnen abgeschlossener Partien über alle Spielmodi.
///
/// Erstellt aus dem aktuellen Spielstand eines Modus eine Vorschau
/// ([previewFor]) und speichert die Partie über den [SessionController]
/// in der Match-History. Danach kann das Board zurückgesetzt werden.
class MatchRecorder {
  MatchRecorder({
    required CounterController counter,
    required WattenController watten,
    required MulatschakController mulatschak,
    required HosnObeController hosnObe,
    required PlayersController players,
    required SessionController sessions,
  }) : _counter = counter,
       _watten = watten,
       _mulatschak = mulatschak,
       _hosnObe = hosnObe,
       _players = players,
       _sessions = sessions;

  final CounterController _counter;
  final WattenController _watten;
  final MulatschakController _mulatschak;
  final HosnObeController _hosnObe;
  final PlayersController _players;
  final SessionController _sessions;

  /// Erkennungsschlüssel der zuletzt aufgezeichneten Partie: verhindert,
  /// dass dieselbe Runde doppelt gespeichert wird (z. B. durch schnelles
  /// Doppeltippen im Abschluss-Sheet oder im Drawer).
  ({AppMode mode, DateTime round, String standings})? _lastRecordKey;

  /// Vorschau des aktuellen Spielstands für das Abschluss-Sheet.
  MatchPreview previewFor(AppMode mode) {
    switch (mode) {
      case AppMode.counter:
        return MatchPreview(
          winnerId: null,
          winnerLabel: null,
          standings: [
            for (final entry in _counter.counters.entries)
              (name: entry.key, score: entry.value),
          ],
        );
      case AppMode.watten:
        final game =
            _watten.games[_watten.currentGame] ??
            const WattenGame(me: 0, you: 0);
        return MatchPreview(
          winnerId: null,
          winnerLabel: _wattenWinnerName(),
          standings: [
            (name: WattenSide.me.label, score: game.me),
            (name: WattenSide.you.label, score: game.you),
          ],
        );
      case AppMode.mulatschak:
        return MatchPreview(
          winnerId: _mulatschak.winner(),
          winnerLabel: null,
          standings: [
            for (final entry in _mulatschak.lineup.entries)
              (name: _players.displayName(entry.key), score: entry.value),
          ],
        );
      case AppMode.hosnObe:
        return MatchPreview(
          winnerId: _hosnObe.winner(),
          winnerLabel: null,
          standings: [
            for (final entry in _hosnObe.lineup.entries)
              (name: _players.displayName(entry.key), score: entry.value),
          ],
        );
    }
  }

  /// Anzeigename der Gewinnerseite: Spielernamen, falls Teams eingeteilt
  /// wurden, sonst die Seitenbezeichnung („Ich“/„Du“).
  String? _wattenWinnerName() {
    final winnerLabel = _watten.winner();
    if (winnerLabel == null) {
      return null;
    }
    final side = winnerLabel == WattenSide.me.label
        ? WattenSide.me
        : WattenSide.you;
    final teamIds = side == WattenSide.me ? _watten.meTeam : _watten.youTeam;
    if (teamIds.isEmpty) {
      return winnerLabel;
    }
    return teamIds.map(_players.displayName).join(' & ');
  }

  /// Zeichnet die Partie des Modus auf und setzt – falls gewünscht – das
  /// Board zurück. Rückgabe ist der gespeicherte [CompletedMatch]; wird
  /// dieselbe Runde ein zweites Mal aufgezeichnet, kommt `null` zurück.
  Future<CompletedMatch?> record(
    AppMode mode, {
    required bool resetBoard,
  }) async {
    final preview = previewFor(mode);

    final round = switch (mode) {
      AppMode.counter => _counter.roundStartedAt,
      AppMode.watten => _watten.roundStartedAt,
      AppMode.mulatschak => _mulatschak.roundStartedAt,
      AppMode.hosnObe => _hosnObe.roundStartedAt,
    };

    final standings = {
      for (final entry in preview.standings) entry.name: entry.score,
    };

    final key = (mode: mode, round: round, standings: jsonEncode(standings));
    if (_lastRecordKey == key) {
      return null;
    }
    _lastRecordKey = key;

    final participantIds = switch (mode) {
      AppMode.mulatschak => _mulatschak.lineup.keys.toList(),
      AppMode.hosnObe => _hosnObe.lineup.keys.toList(),
      _ => const <String>[],
    };

    final match = await _sessions.recordMatch(
      gameType: mode,
      participantIds: participantIds,
      winnerId: preview.winnerId,
      winnerLabel: preview.winnerLabel,
      startedAt: round,
      endedAt: DateTime.now(),
      finalStandings: standings,
    );

    if (resetBoard) {
      this.resetBoard(mode);
    }
    return match;
  }

  /// Setzt das Board des Modus auf den Ausgangszustand zurück.
  void resetBoard(AppMode mode) {
    switch (mode) {
      case AppMode.counter:
        _counter.resetBoard(clearHistory: true);
      case AppMode.watten:
        _watten.resetBoard(clearHistory: true);
      case AppMode.mulatschak:
        _mulatschak.resetPlayers(clearHistory: true);
      case AppMode.hosnObe:
        _hosnObe.resetPlayers();
    }
  }
}
