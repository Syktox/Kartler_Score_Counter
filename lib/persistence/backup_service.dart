import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/completed_match.dart';
import 'json_codec.dart';
import 'schema.dart';
import 'storage_facade.dart';
import 'storage_keys.dart';

/// Fehler beim Import eines Backups. [message] ist für Nutzer formuliert.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lokales Backup-System: Exportiert alle Nutzerdaten als JSON und stellt
/// sie über [importJson] wieder her.
///
/// Der Export enthält Spieler, Spielabende, Match-History, Einstellungen,
/// Regelprofil, Lineups und Verläufe – also alles, was außerhalb des
/// Undo-Verlaufs persistent ist. Das Format trägt eine Schema-Version;
/// Backups aus neueren App-Versionen werden abgelehnt, ältere werden über
/// die bestehende Migrationskette auf den aktuellen Stand gebracht.
class BackupService {
  const BackupService();

  /// Format-Version des Backup-Dokuments selbst (unabhängig vom
  /// Daten-Schema der App).
  static const int formatVersion = 1;

  static const String formatKey = 'kartler_backup';
  static const String schemaVersionKey = 'schemaVersion';
  static const String exportedAtKey = 'exportedAt';
  static const String valuesKey = 'values';

  static const Set<String> _settingsKeys = {
    StorageKeys.themeMode,
    StorageKeys.hapticsEnabled,
    StorageKeys.wattenTableMode,
    StorageKeys.appMode,
    StorageKeys.counterHistoryEnabled,
    StorageKeys.counterNegativeEnabled,
    StorageKeys.mulatschakHistoryEnabled,
    StorageKeys.ruleProfile,
    StorageKeys.onboardingCompleted,
  };

  static const Set<String> _gameStateKeys = {
    StorageKeys.counterLineup,
    StorageKeys.currentCounter,
    StorageKeys.counterHistory,
    StorageKeys.wattenLineup,
    StorageKeys.currentWattenGame,
    StorageKeys.mulatschakLineup,
    StorageKeys.currentMulatschakPlayer,
    StorageKeys.mulatschakMultiplier,
    StorageKeys.mulatschakHistory,
    StorageKeys.mulatschakHistoryRound,
    StorageKeys.mulatschakRoundPlayers,
    StorageKeys.hosnObeLineup,
    StorageKeys.currentHosnObePlayer,
  };

  /// Keys, deren Wert ein JSON-Dokument ist und daher dekodierbar sein muss.
  static const Set<String> _jsonKeys = {
    StorageKeys.players,
    StorageKeys.gameSessions,
    StorageKeys.matchHistory,
    StorageKeys.ruleProfile,
    StorageKeys.counterLineup,
    StorageKeys.counterHistory,
    StorageKeys.wattenLineup,
    StorageKeys.mulatschakLineup,
    StorageKeys.mulatschakHistory,
    StorageKeys.mulatschakHistoryRound,
    StorageKeys.mulatschakRoundPlayers,
    StorageKeys.hosnObeLineup,
  };

  static const Set<String> _knownKeys = {
    ..._settingsKeys,
    StorageKeys.players,
    StorageKeys.gameSessions,
    StorageKeys.matchHistory,
    ..._gameStateKeys,
  };

  /// Erzeugt das Backup-JSON aus den aktuell gespeicherten Daten.
  Future<String> exportJson() async {
    final prefs = await SharedPreferences.getInstance();
    final values = <String, Object>{};
    for (final key in _knownKeys) {
      switch (prefs.get(key)) {
        case final String text:
          values[key] = text;
        case final bool flag:
          values[key] = flag;
        case final int number:
          values[key] = number;
        default:
          break;
      }
    }
    return jsonEncode({
      formatKey: formatVersion,
      schemaVersionKey: StorageSchema.current,
      exportedAtKey: DateTime.now().toIso8601String(),
      valuesKey: values,
    });
  }

  /// Importiert ein Backup-JSON.
  ///
  /// Wirft eine [BackupException], wenn das Dokument nicht dem erwarteten
  /// Format entspricht, korrupte Daten enthält oder aus einer neueren
  /// App-Version stammt. Vorhandene Daten werden erst nach erfolgreicher
  /// Validierung ersetzt.
  Future<void> importJson(String json) async {
    final document = _validateDocument(json);
    final values = document[valuesKey] as Map<String, dynamic>;
    final schemaVersion = document[schemaVersionKey] as int;

    if (schemaVersion > StorageSchema.current) {
      throw const BackupException(
        'Dieses Backup stammt aus einer neueren Version von Kartler. '
        'Bitte aktualisiere die App zuerst.',
      );
    }

    _validateValues(values);

    final prefs = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      final value = entry.value;
      switch (value) {
        case final String text:
          await prefs.setString(entry.key, text);
        case final bool flag:
          await prefs.setBool(entry.key, flag);
        case final int number:
          await prefs.setInt(entry.key, number);
      }
    }
    // Immer die Version des Backups übernehmen: Der nächste App-Start (oder
    // der Import selbst) führt dann ausstehende Migrationen in der
    // richtigen Reihenfolge aus.
    await prefs.setInt(StorageKeys.schemaVersion, schemaVersion);
    if (schemaVersion != StorageSchema.current) {
      await AppStorage.init();
    }
  }

  Map<String, dynamic> _validateDocument(String json) {
    final decoded = JsonCodec.decodeMap(json);
    if (decoded == null) {
      throw const BackupException(
        'Das Backup konnte nicht gelesen werden (kein gültiges JSON).',
      );
    }
    if (decoded[formatKey] != formatVersion) {
      throw const BackupException(
        'Das Backup hat ein unbekanntes Format und kann nicht importiert '
        'werden.',
      );
    }
    final schemaVersion = decoded[schemaVersionKey];
    if (schemaVersion is! int || schemaVersion < 0) {
      throw const BackupException(
        'Das Backup enthält keine gültige Schema-Version.',
      );
    }
    final values = decoded[valuesKey];
    if (values is! Map) {
      throw const BackupException(
        'Das Backup enthält keine Daten und kann nicht importiert werden.',
      );
    }
    return decoded;
  }

  void _validateValues(Map<String, dynamic> values) {
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is! String && value is! bool && value is! int) {
        throw const BackupException(
          'Das Backup enthält ungültige Daten und wurde nicht importiert.',
        );
      }
      if (!_knownKeys.contains(entry.key)) {
        continue;
      }
      if (_jsonKeys.contains(entry.key) && value is String) {
        final decoded = JsonCodec.decode(value);
        if (decoded == null) {
          throw BackupException(
            'Das Backup enthält beschädigte Daten (${entry.key}) und wurde '
            'nicht importiert.',
          );
        }
      }
    }

    for (final key in [
      StorageKeys.players,
      StorageKeys.gameSessions,
      StorageKeys.matchHistory,
    ]) {
      final value = values[key];
      if (value is! String) {
        continue;
      }
      final failed = _firstInvalid(key, value);
      if (failed != null) {
        throw BackupException(
          'Das Backup enthält beschädigte Daten ($failed) und wurde nicht '
          'importiert.',
        );
      }
    }
  }

  /// Prüft die einzelnen Einträge der strukturierten Listen; beim kleinsten
  /// Zweifel wird der komplette Import abgelehnt (kein stiller Datenverlust).
  String? _firstInvalid(String key, String json) {
    final list = JsonCodec.decode(json);
    if (list is! List) {
      return key;
    }
    switch (key) {
      case StorageKeys.players:
        for (final item in list) {
          if (item is! Map ||
              item['id'] is! String ||
              item['name'] is! String) {
            return key;
          }
        }
      case StorageKeys.gameSessions:
        for (final item in list) {
          if (item is! Map ||
              item['id'] is! String ||
              DateTime.tryParse(item['startTime'] as String? ?? '') == null) {
            return key;
          }
        }
      case StorageKeys.matchHistory:
        for (final item in list) {
          if (item is! Map ||
              CompletedMatch.fromJson(Map<String, dynamic>.from(item)) ==
                  null) {
            return key;
          }
        }
    }
    return null;
  }
}
