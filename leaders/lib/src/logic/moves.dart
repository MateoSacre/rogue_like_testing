import '../models/character.dart';
import '../models/game_state.dart';
import '../models/hex.dart';
import '../models/piece.dart';
import 'action_option.dart';
import 'passives.dart';

/// Normal "move to an empty cell" options for a piece.
///
/// Most pieces move exactly one cell to an empty neighbour. The Leader may move
/// up to `1 + Vizir bonus` cells through empty cells. Characters whose movement
/// is entirely special (see [CharacterMeta.hasNormalMove]) return no normal
/// moves here — their movement comes from their ability.
class Moves {
  const Moves._();

  static List<ActionOption> normalMoves(GameState state, Piece piece) {
    if (!piece.type.hasNormalMove) return const [];

    final range = piece.isLeader
        ? 1 + Passives.leaderRangeBonus(state, piece.owner)
        : 1;

    final reachable = _reachableEmptyCells(state, piece.pos, range);
    return [
      for (final cell in reachable)
        ActionOption(
          target: cell,
          kind: 'move',
          label: 'Déplacement',
          apply: (before) => before.withPieceMoved(piece.id, cell),
        ),
    ];
  }

  /// BFS over empty on-board cells up to [range] steps from [start].
  static List<Hex> _reachableEmptyCells(GameState state, Hex start, int range) {
    final visited = <Hex>{start};
    final result = <Hex>[];
    var frontier = <Hex>[start];
    for (var step = 0; step < range; step++) {
      final next = <Hex>[];
      for (final h in frontier) {
        for (final n in h.neighbors) {
          if (visited.contains(n)) continue;
          if (!state.board.contains(n)) continue;
          if (state.isOccupied(n)) continue;
          visited.add(n);
          result.add(n);
          next.add(n);
        }
      }
      frontier = next;
    }
    return result;
  }
}
