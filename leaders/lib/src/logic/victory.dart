import '../models/character.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'hex_geometry.dart';

/// Detects whether the game has been won after an action resolves.
class Victory {
  const Victory._();

  /// Returns the winning player, or null if the game continues. A player wins if
  /// the opponent's Leader is captured or encircled.
  static PlayerId? check(GameState state) {
    for (final owner in PlayerId.values) {
      if (_isLeaderLost(state, owner)) return owner.opponent;
    }
    return null;
  }

  static bool _isLeaderLost(GameState state, PlayerId owner) {
    final leader = state.leaderOf(owner);
    final lead = leader.pos;

    // --- Capture ---
    var attackers = 0;
    for (final e in state.piecesOf(owner.opponent)) {
      final adjacent = e.pos.isAdjacentTo(lead);

      if (e.type == CharacterType.assassin && adjacent) {
        return true; // Assassin captures alone.
      }

      if (e.type == CharacterType.archere) {
        // Archère contributes from distance 2 in a clear straight line, but NOT
        // while adjacent to the Leader.
        if (adjacent) continue;
        if (e.pos.distanceTo(lead) == 2 &&
            HexGeometry.lineOfSight(state, e.pos, lead)) {
          attackers++;
        }
        continue;
      }

      if (adjacent) attackers++;
    }
    if (attackers >= 2) return true;

    // --- Encirclement: every on-board adjacent cell is occupied. ---
    final onBoardNeighbors =
        lead.neighbors.where(state.board.contains).toList();
    if (onBoardNeighbors.isNotEmpty &&
        onBoardNeighbors.every(state.isOccupied)) {
      return true;
    }

    return false;
  }
}
