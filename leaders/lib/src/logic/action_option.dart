import '../models/game_state.dart';
import '../models/hex.dart';

/// A single concrete action a player can take with a selected piece, whether a
/// normal move or an ability. [target] is the board cell the player taps to
/// choose it; [applyTo] returns the new game state with the action's board
/// effect applied (turn/phase bookkeeping is added later by the engine).
class ActionOption {
  /// The cell the user taps to pick this option (used for highlighting).
  final Hex target;

  /// Short human-readable description (debug / tooltips).
  final String label;

  /// Identifier of the source: 'move' for a normal move, otherwise the ability id.
  final String kind;

  final GameState Function(GameState before) _apply;

  const ActionOption({
    required this.target,
    required this.label,
    required this.kind,
    required GameState Function(GameState before) apply,
  }) : _apply = apply;

  GameState applyTo(GameState before) => _apply(before);
}
