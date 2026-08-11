/// Konfigurierbares Regelwerk für die Kartenspielmodi.
///
/// Ein Profil fasst alle derzeit konfigurierbaren Spielregeln zusammen.
/// Die Standardwerte entsprechen dem bisherigen fest verdrahteten Verhalten,
/// damit bestehende Abläufe unverändert funktionieren.
class RuleProfile {
  final int wattenWinningScore;
  final int mulatschakStartingScore;
  final int hosnObeStartingLives;
  final bool muleqackEnabled;
  final int muleqackTriggerPoints;
  final int muleqackResetPoints;

  const RuleProfile({
    required this.wattenWinningScore,
    required this.mulatschakStartingScore,
    required this.hosnObeStartingLives,
    required this.muleqackEnabled,
    required this.muleqackTriggerPoints,
    required this.muleqackResetPoints,
  });

  const RuleProfile.defaults()
    : wattenWinningScore = 11,
      mulatschakStartingScore = 21,
      hosnObeStartingLives = 4,
      muleqackEnabled = false,
      muleqackTriggerPoints = 100,
      muleqackResetPoints = 50;

  RuleProfile copyWith({
    int? wattenWinningScore,
    int? mulatschakStartingScore,
    int? hosnObeStartingLives,
    bool? muleqackEnabled,
    int? muleqackTriggerPoints,
    int? muleqackResetPoints,
  }) {
    return RuleProfile(
      wattenWinningScore: wattenWinningScore ?? this.wattenWinningScore,
      mulatschakStartingScore:
          mulatschakStartingScore ?? this.mulatschakStartingScore,
      hosnObeStartingLives: hosnObeStartingLives ?? this.hosnObeStartingLives,
      muleqackEnabled: muleqackEnabled ?? this.muleqackEnabled,
      muleqackTriggerPoints:
          muleqackTriggerPoints ?? this.muleqackTriggerPoints,
      muleqackResetPoints: muleqackResetPoints ?? this.muleqackResetPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wattenWinningScore': wattenWinningScore,
      'mulatschakStartingScore': mulatschakStartingScore,
      'hosnObeStartingLives': hosnObeStartingLives,
      'muleqackEnabled': muleqackEnabled,
      'muleqackTriggerPoints': muleqackTriggerPoints,
      'muleqackResetPoints': muleqackResetPoints,
    };
  }

  factory RuleProfile.fromJson(Map<String, dynamic> json) {
    const defaults = RuleProfile.defaults();
    int readInt(String key, int fallback) {
      final value = json[key];
      return value is num && value >= 0 ? value.toInt() : fallback;
    }

    bool readBool(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    return RuleProfile(
      wattenWinningScore: readInt('wattenWinningScore', defaults.wattenWinningScore),
      mulatschakStartingScore: readInt(
        'mulatschakStartingScore',
        defaults.mulatschakStartingScore,
      ),
      hosnObeStartingLives: readInt('hosnObeStartingLives', defaults.hosnObeStartingLives),
      muleqackEnabled: readBool('muleqackEnabled', defaults.muleqackEnabled),
      muleqackTriggerPoints: readInt(
        'muleqackTriggerPoints',
        defaults.muleqackTriggerPoints,
      ),
      muleqackResetPoints: readInt(
        'muleqackResetPoints',
        defaults.muleqackResetPoints,
      ),
    );
  }
}
