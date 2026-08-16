import 'package:flutter_test/flutter_test.dart';
import 'package:kartler/commands/callback_command.dart';
import 'package:kartler/commands/command_history.dart';

void main() {
  group('CommandHistory', () {
    test('execute applies the change and enables undo', () {
      var value = 0;
      final history = CommandHistory();

      history.execute(
        CallbackCommand(
          applyChange: () => value += 1,
          revertChange: () => value -= 1,
        ),
      );

      expect(value, 1);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('undo reverts the change and moves it to the redo stack', () {
      var value = 0;
      final history = CommandHistory();
      history.execute(
        CallbackCommand(
          applyChange: () => value += 1,
          revertChange: () => value -= 1,
        ),
      );

      history.undo();

      expect(value, 0);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
    });

    test('redo applies the change again', () {
      var value = 0;
      final history = CommandHistory();
      history.execute(
        CallbackCommand(
          applyChange: () => value += 2,
          revertChange: () => value -= 2,
        ),
      );

      history.undo();
      history.redo();

      expect(value, 2);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('undo and redo follow last-in-first-out order', () {
      var value = '';
      final history = CommandHistory();
      for (final letter in ['a', 'b', 'c']) {
        history.execute(
          CallbackCommand(
            applyChange: () => value += letter,
            revertChange: () => value = value.substring(0, value.length - 1),
          ),
        );
      }

      history.undo();
      history.undo();

      expect(value, 'a');
      expect(history.redoCount, 2);
      expect(history.undoCount, 1);
    });

    test('a new execute clears the redo stack', () {
      var value = 0;
      final history = CommandHistory();
      history.execute(
        CallbackCommand(
          applyChange: () => value += 1,
          revertChange: () => value -= 1,
        ),
      );
      history.undo();

      history.execute(
        CallbackCommand(
          applyChange: () => value += 10,
          revertChange: () => value -= 10,
        ),
      );

      expect(history.canRedo, isFalse);
      expect(history.redoCount, 0);
    });

    test('undo and redo on empty stacks are no-ops', () {
      final history = CommandHistory();

      expect(() => history.undo(), returnsNormally);
      expect(() => history.redo(), returnsNormally);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('drops the oldest command beyond the capacity', () {
      var value = 0;
      final history = CommandHistory(capacity: 2);

      for (var i = 0; i < 3; i++) {
        history.execute(
          CallbackCommand(
            applyChange: () => value += 1,
            revertChange: () => value -= 1,
          ),
        );
      }

      expect(value, 3);
      expect(history.undoCount, 2);

      history.undo();
      history.undo();
      history.undo();

      expect(value, 1);
    });

    test('clear resets both stacks', () {
      var value = 0;
      final history = CommandHistory();
      history.execute(
        CallbackCommand(
          applyChange: () => value += 1,
          revertChange: () => value -= 1,
        ),
      );
      history.undo();

      history.clear();

      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, 0);
      expect(history.redoCount, 0);
    });
  });
}
