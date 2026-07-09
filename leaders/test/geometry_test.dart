import 'package:flutter_test/flutter_test.dart';
import 'package:leaders/src/logic/hex_geometry.dart';
import 'package:leaders/src/models/character.dart';
import 'package:leaders/src/models/hex.dart';
import 'package:leaders/src/models/player.dart';

import 'helpers.dart';

void main() {
  test('clear straight line has line of sight', () {
    final state = makeState([
      pc('a', PlayerId.one, CharacterType.geolier, const Hex(0, 0)),
      pc('b', PlayerId.two, CharacterType.geolier, const Hex(3, 0)),
    ]);
    expect(
      HexGeometry.lineOfSight(state, const Hex(0, 0), const Hex(3, 0)),
      isTrue,
    );
  });

  test('a piece in between blocks line of sight', () {
    final state = makeState([
      pc('a', PlayerId.one, CharacterType.geolier, const Hex(0, 0)),
      pc('block', PlayerId.one, CharacterType.cogneur, const Hex(1, 0)),
      pc('b', PlayerId.two, CharacterType.geolier, const Hex(3, 0)),
    ]);
    expect(
      HexGeometry.lineOfSight(state, const Hex(0, 0), const Hex(3, 0)),
      isFalse,
    );
  });

  test('non-aligned cells never have line of sight', () {
    final state = makeState([
      pc('a', PlayerId.one, CharacterType.geolier, const Hex(0, 0)),
    ]);
    expect(
      HexGeometry.lineOfSight(state, const Hex(0, 0), const Hex(2, 1)),
      isFalse,
    );
  });

  test('visiblePieceCells finds the first piece per direction', () {
    final state = makeState([
      pc('a', PlayerId.one, CharacterType.geolier, const Hex(0, 0)),
      pc('near', PlayerId.two, CharacterType.geolier, const Hex(2, 0)),
      pc('behind', PlayerId.two, CharacterType.geolier, const Hex(3, 0)),
    ]);
    final visible =
        HexGeometry.visiblePieceCells(state, const Hex(0, 0)).toSet();
    expect(visible.contains(const Hex(2, 0)), isTrue);
    expect(visible.contains(const Hex(3, 0)), isFalse); // occluded
  });
}
