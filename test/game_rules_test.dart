import 'package:kartler/models/game_rules.dart';
import 'package:kartler/models/watten_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRules', () {
    test('detects Watten winners at the winning score', () {
      expect(GameRules.wattenWinner(const WattenGame(me: 10, you: 0)), isNull);
      expect(GameRules.wattenWinner(const WattenGame(me: 11, you: 10)), 'Me');
      expect(GameRules.wattenWinner(const WattenGame(me: 11, you: 11)), isNull);
      expect(GameRules.wattenWinner(const WattenGame(me: 8, you: 12)), 'You');
    });

    test('detects Mulatschak winner by the first zero score', () {
      expect(GameRules.firstZeroScoreWinner({'Anna': 3, 'Ben': 1}), isNull);
      expect(GameRules.firstZeroScoreWinner({'Anna': 0, 'Ben': 0}), 'Anna');
    });

    test('applies Mulatschak reset loop predictably', () {
      expect(
        GameRules.applyResetLoop(
          score: 100,
          triggerPoints: 100,
          resetPoints: 50,
        ),
        50,
      );
      expect(
        GameRules.applyResetLoop(
          score: 155,
          triggerPoints: 100,
          resetPoints: 50,
        ),
        55,
      );
    });

    test('detects Hosn Obe winner by remaining lives', () {
      expect(GameRules.lastPlayerWithLives({'Anna': 1, 'Ben': 1}), isNull);
      expect(GameRules.lastPlayerWithLives({'Anna': 0, 'Ben': 2}), 'Ben');
      expect(GameRules.lastPlayerWithLives({'Anna': 0, 'Ben': 0}), isNull);
    });

    test('clamps score values at zero for counter-like scoring', () {
      expect(GameRules.clampAtZero(-3), 0);
      expect(GameRules.clampAtZero(4), 4);
    });
  });
}
