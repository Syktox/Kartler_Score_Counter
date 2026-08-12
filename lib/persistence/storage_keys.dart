/// Alle `shared_preferences`-Keys der aktuellen Speicherversion.
abstract final class StorageKeys {
  static const schemaVersion = 'schema_version';

  // Allgemeine Einstellungen
  static const themeMode = 'theme_mode';
  static const hapticsEnabled = 'haptics_enabled';
  static const wattenTableMode = 'watten_table_mode';
  static const appMode = 'app_mode';
  static const counterHistoryEnabled = 'counter_history_enabled';
  static const counterNegativeEnabled = 'counter_negative_enabled';
  static const wattenHistoryEnabled = 'watten_history_enabled';
  static const mulatschakHistoryEnabled = 'mulatschak_history_enabled';
  static const ruleProfile = 'rule_profile';

  // Globale Spieler
  static const players = 'players';

  // Zähler-Daten
  static const counterLineup = 'counter_lineup';
  static const currentCounter = 'current_counter';
  static const counterHistory = 'counter_history';

  // Watten-Daten
  static const wattenLineup = 'watten_lineup';
  static const currentWattenGame = 'current_watten_game';
  static const wattenTeamMe = 'watten_team_me';
  static const wattenTeamYou = 'watten_team_you';
  static const wattenHistory = 'watten_history';

  // Mulatschak-Daten
  static const mulatschakLineup = 'mulatschak_lineup';
  static const currentMulatschakPlayer = 'current_mulatschak_player';
  static const mulatschakMultiplier = 'mulatschak_multiplier';
  static const mulatschakHistory = 'mulatschak_history';
  static const mulatschakHistoryRound = 'mulatschak_history_round';
  static const mulatschakRoundPlayers = 'mulatschak_round_players';

  // Hosn-Obe-Daten
  static const hosnObeLineup = 'hosn_obe_lineup';
  static const currentHosnObePlayer = 'current_hosn_obe_player';

  // Spielabende / Match-History
  static const gameSessions = 'game_sessions';
  static const matchHistory = 'match_history';
}

/// Legacy-Keys aus der Zeit vor der globalen Spieler- und
/// Regelprofil-Migration (Schema 0). Sie werden ausschließlich noch von den
/// Migrationen gelesen.
abstract final class LegacyStorageKeys {
  static const counters = 'counters';
  static const wattenGames = 'watten_games';
  static const mulatschakPlayers = 'mulatschak_players';
  static const hosnObePlayers = 'hosn_obe_players';
  static const muleqackEnabled = 'muleqack_enabled';
  static const muleqackTriggerPoints = 'muleqack_trigger_points';
  static const muleqackResetPoints = 'muleqack_reset_points';
}
