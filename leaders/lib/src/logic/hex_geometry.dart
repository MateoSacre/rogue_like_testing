import '../models/game_state.dart';
import '../models/hex.dart';

/// Hexagonal line-of-sight helpers used by several abilities and by the
/// Archère victory rule. "Visible in a straight line" means: [a] and [b] lie on
/// one of the 6 axial directions, and no piece occupies any cell between them.
class HexGeometry {
  const HexGeometry._();

  /// Whether [b] is visible from [a] along a straight axial line with no piece
  /// in between. Adjacent aligned cells are trivially visible.
  static bool lineOfSight(GameState state, Hex a, Hex b) {
    if (!a.isInStraightLineWith(b)) return false;
    for (final cell in a.cellsBetween(b)) {
      if (state.isOccupied(cell)) return false;
    }
    return true;
  }

  /// All pieces visible from [origin] in a straight unobstructed line.
  /// Returns the first piece encountered in each of the 6 directions.
  static Iterable<Hex> visiblePieceCells(GameState state, Hex origin) sync* {
    for (var dir = 0; dir < 6; dir++) {
      var cur = origin.neighbor(dir);
      while (state.board.contains(cur)) {
        if (state.isOccupied(cur)) {
          yield cur;
          break;
        }
        cur = cur + Hex.directions[dir];
      }
    }
  }
}
