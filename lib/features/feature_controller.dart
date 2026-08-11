import 'package:flutter/foundation.dart';

import '../../commands/command_history.dart';

/// Gemeinsame Basis aller Feature-Controller.
///
/// Stellt den Undo-/Redo-Verlauf ([history]) und den Ladezustand bereit.
abstract class FeatureController extends ChangeNotifier {
  final CommandHistory history = CommandHistory();

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  @protected
  set isLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;

  void undo() => history.undo();

  void redo() => history.redo();

  /// Lädt den gespeicherten Zustand. Wird genau einmal aufgerufen.
  Future<void> load();

  @override
  void dispose() {
    history.dispose();
    super.dispose();
  }
}
