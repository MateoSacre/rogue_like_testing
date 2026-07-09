import 'package:flutter_test/flutter_test.dart';
import 'package:leaders/src/logic/victory.dart';
import 'package:leaders/src/models/character.dart';
import 'package:leaders/src/models/hex.dart';
import 'package:leaders/src/models/player.dart';

import 'helpers.dart';

void main() {
  test('two adjacent enemies capture the Leader', () {
    final state = makeState([
      pc('L1', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('L2', PlayerId.two, CharacterType.leader, const Hex(0, -4)),
      pc('a', PlayerId.two, CharacterType.geolier, const Hex(1, 0)),
      pc('b', PlayerId.two, CharacterType.cogneur, const Hex(0, 1)),
    ]);
    expect(Victory.check(state), PlayerId.two);
  });

  test('a single adjacent enemy is not enough', () {
    final state = makeState([
      pc('L1', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('L2', PlayerId.two, CharacterType.leader, const Hex(0, -4)),
      pc('a', PlayerId.two, CharacterType.geolier, const Hex(1, 0)),
    ]);
    expect(Victory.check(state), isNull);
  });

  test('Assassin captures the Leader alone', () {
    final state = makeState([
      pc('L1', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('L2', PlayerId.two, CharacterType.leader, const Hex(0, -4)),
      pc('as', PlayerId.two, CharacterType.assassin, const Hex(1, 0)),
    ]);
    expect(Victory.check(state), PlayerId.two);
  });

  test('Archère contributes from distance 2 on a clear line', () {
    final state = makeState([
      pc('L1', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('L2', PlayerId.two, CharacterType.leader, const Hex(0, -4)),
      pc('adj', PlayerId.two, CharacterType.geolier, const Hex(0, 1)),
      pc('arch', PlayerId.two, CharacterType.archere, const Hex(2, 0)),
    ]);
    expect(Victory.check(state), PlayerId.two);
  });

  test('an obstacle blocks the Archère contribution', () {
    final state = makeState([
      pc('L1', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('L2', PlayerId.two, CharacterType.leader, const Hex(0, -4)),
      pc('adj', PlayerId.two, CharacterType.geolier, const Hex(0, 1)),
      // Friendly (to L1) blocker between archer and leader: blocks LoS, does not
      // count as an attacker.
      pc('wall', PlayerId.one, CharacterType.geolier, const Hex(1, 0)),
      pc('arch', PlayerId.two, CharacterType.archere, const Hex(2, 0)),
    ]);
    expect(Victory.check(state), isNull);
  });

  test('an adjacent Archère does not count toward capture', () {
    final state = makeState([
      pc('L1', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('L2', PlayerId.two, CharacterType.leader, const Hex(0, -4)),
      pc('adj', PlayerId.two, CharacterType.geolier, const Hex(0, 1)),
      pc('arch', PlayerId.two, CharacterType.archere, const Hex(1, 0)),
    ]);
    expect(Victory.check(state), isNull);
  });

  test('a fully surrounded Leader is encircled (opponent wins)', () {
    final neighbours = const Hex(0, 0).neighbors;
    final state = makeState([
      pc('L1', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('L2', PlayerId.two, CharacterType.leader, const Hex(0, -4)),
      // Surround with the Leader's own allies (no enemy adjacent -> isolates the
      // encirclement rule from the capture rule).
      for (var i = 0; i < neighbours.length; i++)
        pc('o$i', PlayerId.one, CharacterType.geolier, neighbours[i]),
    ]);
    expect(Victory.check(state), PlayerId.two);
  });
}
