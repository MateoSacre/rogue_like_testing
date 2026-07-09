import 'hex.dart';
import 'player.dart';

/// A regular hexagon-shaped board of a given [radius], centred on Hex(0, 0).
///
/// Player one's home side is the high-r edge (bottom), player two's is the
/// low-r edge (top). Each player has a designated leader start cell and a set of
/// recruitment cells on their home rows.
class Board {
  final int radius;
  final Set<Hex> cells;

  Board._(this.radius, this.cells);

  factory Board.hexagon({int radius = 4}) {
    final cells = const Hex(0, 0).withinRange(radius).toSet();
    return Board._(radius, cells);
  }

  bool contains(Hex h) => cells.contains(h);

  /// Designated starting cell for a player's leader.
  Hex leaderStart(PlayerId player) =>
      player == PlayerId.one ? Hex(0, radius) : Hex(0, -radius);

  /// Recruitment cells for [player]: the two home rows closest to that player's
  /// edge, excluding the leader start cell. Recruits are placed on the first
  /// free one of these (the engine decides ordering).
  List<Hex> recruitCells(PlayerId player) {
    final rows = player == PlayerId.one
        ? {radius, radius - 1}
        : {-radius, -radius + 1};
    final start = leaderStart(player);
    final result = cells
        .where((h) => rows.contains(h.r) && h != start)
        .toList()
      ..sort(_homeOrder(player));
    return result;
  }

  /// Orders recruit cells so the back-most row fills first, left to right.
  int Function(Hex, Hex) _homeOrder(PlayerId player) {
    final backFirst = player == PlayerId.one ? -1 : 1;
    return (a, b) {
      if (a.r != b.r) return backFirst * (b.r - a.r);
      return a.q - b.q;
    };
  }
}
