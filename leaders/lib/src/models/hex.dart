import 'dart:math' as math;

/// Axial hexagonal coordinate (q, r) with implicit cube s = -q - r.
///
/// Pointy-top orientation is used for rendering (see ui layer). This class is a
/// pure value type: two [Hex] with equal coordinates are equal and hash alike,
/// so they can be used as map keys / set members.
class Hex {
  final int q;
  final int r;

  const Hex(this.q, this.r);

  /// Cube z-coordinate.
  int get s => -q - r;

  /// The six neighbour directions in axial coordinates, ordered clockwise
  /// starting from the east-ish direction. Index matches [neighbor].
  static const List<Hex> directions = [
    Hex(1, 0),
    Hex(1, -1),
    Hex(0, -1),
    Hex(-1, 0),
    Hex(-1, 1),
    Hex(0, 1),
  ];

  Hex operator +(Hex other) => Hex(q + other.q, r + other.r);
  Hex operator -(Hex other) => Hex(q - other.q, r - other.r);
  Hex scale(int k) => Hex(q * k, r * k);

  /// Neighbour in direction [i] (0..5).
  Hex neighbor(int i) => this + directions[i];

  /// All six adjacent hexes (no board-bounds filtering here).
  List<Hex> get neighbors => [for (var i = 0; i < 6; i++) neighbor(i)];

  /// Hex (Manhattan-on-cube) distance.
  int distanceTo(Hex other) {
    final dq = (q - other.q).abs();
    final dr = (r - other.r).abs();
    final ds = (s - other.s).abs();
    return (dq + dr + ds) ~/ 2;
  }

  bool isAdjacentTo(Hex other) => distanceTo(other) == 1;

  /// If [other] lies on one of the 6 straight axial directions from this hex,
  /// returns that direction index (0..5); otherwise null.
  int? directionTo(Hex other) {
    if (this == other) return null;
    final d = other - this;
    for (var i = 0; i < 6; i++) {
      final dir = directions[i];
      // d must be a positive integer multiple of dir.
      if (dir.q != 0) {
        if (d.q % dir.q != 0) continue;
        final k = d.q ~/ dir.q;
        if (k > 0 && dir.scale(k) == d) return i;
      } else {
        // dir.q == 0 => movement only along r (and s).
        if (d.q != 0) continue;
        if (dir.r != 0 && d.r % dir.r == 0) {
          final k = d.r ~/ dir.r;
          if (k > 0 && dir.scale(k) == d) return i;
        }
      }
    }
    return null;
  }

  /// Whether [other] is reachable from this hex along a single straight axial line.
  bool isInStraightLineWith(Hex other) => directionTo(other) != null;

  /// The hexes strictly between this and [other] along a straight axial line.
  /// Returns empty if they are not aligned or are adjacent/equal.
  List<Hex> cellsBetween(Hex other) {
    final dir = directionTo(other);
    if (dir == null) return const [];
    final step = directions[dir];
    final result = <Hex>[];
    var cur = this + step;
    while (cur != other) {
      result.add(cur);
      cur = cur + step;
    }
    return result;
  }

  /// All hexes within [radius] of this one (a filled hexagon), including itself.
  List<Hex> withinRange(int radius) {
    final result = <Hex>[];
    for (var dq = -radius; dq <= radius; dq++) {
      final lo = math.max(-radius, -dq - radius);
      final hi = math.min(radius, -dq + radius);
      for (var dr = lo; dr <= hi; dr++) {
        result.add(Hex(q + dq, r + dr));
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is Hex && other.q == q && other.r == r;

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'Hex($q, $r)';
}
