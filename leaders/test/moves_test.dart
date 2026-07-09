import 'package:flutter_test/flutter_test.dart';
import 'package:leaders/src/logic/moves.dart';
import 'package:leaders/src/models/character.dart';
import 'package:leaders/src/models/hex.dart';
import 'package:leaders/src/models/player.dart';

import 'helpers.dart';

void main() {
  test('a normal piece in open space has 6 moves', () {
    final state = makeState([
      pc('g', PlayerId.one, CharacterType.geolier, const Hex(0, 0)),
    ]);
    final moves = Moves.normalMoves(state, state.pieces['g']!);
    expect(moves.length, 6);
    expect(moves.map((m) => m.target).toSet(),
        const Hex(0, 0).neighbors.toSet());
  });

  test('occupied and off-board neighbours are not move targets', () {
    final state = makeState([
      // Corner of a radius-2 board: only some neighbours are on-board.
      pc('g', PlayerId.one, CharacterType.geolier, const Hex(0, 2)),
    ], radius: 2);
    final moves = Moves.normalMoves(state, state.pieces['g']!);
    for (final m in moves) {
      expect(state.board.contains(m.target), isTrue);
    }
    expect(moves.length, lessThan(6));
  });

  test('special-movement characters have no normal moves', () {
    final state = makeState([
      pc('r', PlayerId.one, CharacterType.rodeuse, const Hex(0, 0)),
    ]);
    expect(Moves.normalMoves(state, state.pieces['r']!), isEmpty);
  });

  test('leader moves 1 normally, 2 with a friendly Vizir', () {
    final without = makeState([
      pc('L', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
    ]);
    expect(Moves.normalMoves(without, without.pieces['L']!).length, 6);

    final withVizir = makeState([
      pc('L', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
      pc('v', PlayerId.one, CharacterType.vizir, const Hex(0, 4)),
    ]);
    // Range 2 in open space (minus the far Vizir, which is out of range) = 18.
    expect(Moves.normalMoves(withVizir, withVizir.pieces['L']!).length, 18);
  });
}
