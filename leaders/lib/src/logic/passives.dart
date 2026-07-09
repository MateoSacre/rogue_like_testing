import '../models/character.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player.dart';

/// Always-on passive effects that gate or modify other actions.
class Passives {
  const Passives._();

  /// Geôlier: an enemy piece adjacent to a Geôlier cannot use its active skill.
  /// Returns true if [piece]'s active ability is currently jailed.
  static bool isAbilityBlocked(GameState state, Piece piece) {
    for (final other in state.allPieces) {
      if (other.owner == piece.owner) continue;
      if (other.type == CharacterType.geolier &&
          other.pos.isAdjacentTo(piece.pos)) {
        return true;
      }
    }
    return false;
  }

  /// Protecteur: enemy skills can move neither a Protecteur nor an ally adjacent
  /// to one. [target] is the piece an enemy ability is trying to move;
  /// [mover] is the piece using the ability. Returns true if [target] is shielded.
  static bool isMoveShielded(GameState state, Piece mover, Piece target) {
    // Only enemy abilities are constrained by the opposing Protecteur.
    if (mover.owner == target.owner) return false;
    // A Protecteur protects itself…
    if (target.type == CharacterType.protecteur) return true;
    // …and any ally adjacent to a Protecteur of the target's side.
    for (final p in state.piecesOf(target.owner)) {
      if (p.type == CharacterType.protecteur &&
          p.pos.isAdjacentTo(target.pos)) {
        return true;
      }
    }
    return false;
  }

  /// Vizir: each Vizir a player controls increases that player's Leader move
  /// range by 1. Returns the extra range (0 if none).
  static int leaderRangeBonus(GameState state, PlayerId owner) {
    return state
        .piecesOf(owner)
        .where((p) => p.type == CharacterType.vizir)
        .length;
  }
}
