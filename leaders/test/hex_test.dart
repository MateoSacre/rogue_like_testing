import 'package:flutter_test/flutter_test.dart';
import 'package:leaders/src/models/hex.dart';

void main() {
  test('a hex has 6 neighbours all at distance 1', () {
    const h = Hex(0, 0);
    expect(h.neighbors.length, 6);
    for (final n in h.neighbors) {
      expect(h.distanceTo(n), 1);
      expect(h.isAdjacentTo(n), isTrue);
    }
  });

  test('distance is symmetric and correct', () {
    expect(const Hex(0, 0).distanceTo(const Hex(3, 0)), 3);
    expect(const Hex(0, 0).distanceTo(const Hex(0, 3)), 3);
    expect(const Hex(0, 0).distanceTo(const Hex(-2, -1)), 3);
    expect(const Hex(2, -1).distanceTo(const Hex(0, 0)),
        const Hex(0, 0).distanceTo(const Hex(2, -1)));
  });

  test('straight-line detection and cells between', () {
    const o = Hex(0, 0);
    expect(o.isInStraightLineWith(const Hex(3, 0)), isTrue);
    expect(o.isInStraightLineWith(const Hex(0, -3)), isTrue);
    expect(o.isInStraightLineWith(const Hex(2, 1)), isFalse);
    expect(
      o.cellsBetween(const Hex(3, 0)),
      [const Hex(1, 0), const Hex(2, 0)],
    );
    expect(o.cellsBetween(const Hex(1, 0)), isEmpty); // adjacent
    expect(o.cellsBetween(const Hex(2, 1)), isEmpty); // not aligned
  });

  test('equality and hashing work as a value type', () {
    expect(const Hex(1, 2), const Hex(1, 2));
    final set = <Hex>{}
      ..addAll([const Hex(1, 2), const Hex(1, 2), const Hex(0, 0)]);
    expect(set.length, 2);
  });

  test('withinRange returns the right count', () {
    // 1 + 3*r*(r+1) cells for a filled hexagon of radius r.
    expect(const Hex(0, 0).withinRange(1).length, 7);
    expect(const Hex(0, 0).withinRange(2).length, 19);
  });
}
