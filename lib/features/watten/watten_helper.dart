import '../../models/game_rules.dart';
import '../../models/watten_game.dart';
import '../../models/watten_side.dart';

class WattenHelper {
  const WattenHelper._();

  static String? winner(WattenGame game, {int winningScore = 11}) {
    return GameRules.wattenWinner(game, winningScore: winningScore);
  }

  static WattenGame updateSideScore({
    required WattenGame game,
    required WattenSide side,
    required int delta,
  }) {
    final currentValue = side == WattenSide.me ? game.me : game.you;
    final nextValue = currentValue + delta;

    return side == WattenSide.me
        ? game.copyWith(me: nextValue)
        : game.copyWith(you: nextValue);
  }

  static int sideScore(WattenGame game, WattenSide side) {
    return side == WattenSide.me ? game.me : game.you;
  }
}
