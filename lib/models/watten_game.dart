class WattenGame {
  final int me;
  final int you;

  const WattenGame({required this.me, required this.you});

  WattenGame copyWith({int? me, int? you}) {
    return WattenGame(me: me ?? this.me, you: you ?? this.you);
  }

  Map<String, int> toJson() {
    return {'me': me, 'you': you};
  }

  static WattenGame fromJson(Map<String, dynamic> json) {
    return WattenGame(
      me: (json['me'] as num?)?.toInt() ?? 0,
      you: (json['you'] as num?)?.toInt() ?? 0,
    );
  }
}
