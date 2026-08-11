import 'package:flutter/foundation.dart';

import 'undoable_command.dart';

/// Verwaltet Undo-/Redo-Stapel für [UndoableCommand]s.
///
/// Jede Änderung wird über [execute] angewendet und auf den Undo-Stapel
/// gelegt. [undo] stellt den Zustand wieder her, [redo] wendet die Änderung
/// erneut an. Die Kapazität begrenzt die Zahl der rückgängig machbaren
/// Aktionen, alte Einträge werden verworfen.
class CommandHistory extends ChangeNotifier {
  CommandHistory({this.capacity = 40});

  final int capacity;

  final List<UndoableCommand> _undoStack = [];
  final List<UndoableCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  void execute(UndoableCommand command) {
    command.apply();
    _undoStack.add(command);
    _redoStack.clear();
    if (_undoStack.length > capacity) {
      _undoStack.removeAt(0);
    }
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final command = _undoStack.removeLast();
    command.revert();
    _redoStack.add(command);
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    final command = _redoStack.removeLast();
    command.apply();
    _undoStack.add(command);
    notifyListeners();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
