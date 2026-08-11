import 'undoable_command.dart';

/// Einfacher [UndoableCommand], der zwei Callbacks kapselt.
/// Bequem für kleine, klar umrissene Zustandsänderungen.
class CallbackCommand implements UndoableCommand {
  CallbackCommand({required this.applyChange, required this.revertChange});

  final void Function() applyChange;
  final void Function() revertChange;

  @override
  void apply() => applyChange();

  @override
  void revert() => revertChange();
}
