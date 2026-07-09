import 'package:flutter_test/flutter_test.dart';
import 'package:leaders/src/logic/abilities.dart';
import 'package:leaders/src/models/character.dart';
import 'package:leaders/src/models/hex.dart';
import 'package:leaders/src/models/player.dart';

import 'helpers.dart';

void main() {
  test('Cogneur pushes an adjacent enemy straight back', () {
    final state = makeState([
      pc('c', PlayerId.one, CharacterType.cogneur, const Hex(0, 0)),
      pc('e', PlayerId.two, CharacterType.vizir, const Hex(1, 0)),
    ]);
    final options = abilityOptions(state, state.pieces['c']!);
    final push = options.firstWhere((o) => o.target == const Hex(1, 0));
    final after = push.applyTo(state);
    expect(after.pieces['e']!.pos, const Hex(2, 0)); // pushed beyond
  });

  test('Geôlier jails an adjacent enemy active ability', () {
    final state = makeState([
      pc('c', PlayerId.one, CharacterType.cogneur, const Hex(0, 0)),
      pc('e', PlayerId.two, CharacterType.geolier, const Hex(1, 0)),
    ]);
    // The cogneur is adjacent to an enemy Geôlier -> its ability is blocked.
    expect(abilityOptions(state, state.pieces['c']!), isEmpty);
  });

  test('Protecteur shields an ally from enemy manipulation', () {
    final state = makeState([
      pc('m', PlayerId.one, CharacterType.manipulatrice, const Hex(0, 0)),
      pc('t', PlayerId.two, CharacterType.geolier, const Hex(2, 0)),
      pc('p', PlayerId.two, CharacterType.protecteur, const Hex(3, 0)),
    ]);
    // Target 't' is adjacent to its Protecteur 'p' -> cannot be manipulated.
    expect(abilityOptions(state, state.pieces['m']!), isEmpty);
  });

  test('Sauteur jumps over an adjacent piece to the empty cell beyond', () {
    final state = makeState([
      pc('s', PlayerId.one, CharacterType.sauteur, const Hex(0, 0)),
      pc('o', PlayerId.one, CharacterType.geolier, const Hex(1, 0)),
    ]);
    final options = abilityOptions(state, state.pieces['s']!);
    final jump = options.firstWhere((o) => o.target == const Hex(2, 0));
    final after = jump.applyTo(state);
    expect(after.pieces['s']!.pos, const Hex(2, 0));
  });

  test('Illusionniste swaps with a visible non-adjacent piece', () {
    final state = makeState([
      pc('i', PlayerId.one, CharacterType.illusionniste, const Hex(0, 0)),
      pc('x', PlayerId.two, CharacterType.geolier, const Hex(3, 0)),
    ]);
    final options = abilityOptions(state, state.pieces['i']!);
    final swap = options.firstWhere((o) => o.target == const Hex(3, 0));
    final after = swap.applyTo(state);
    expect(after.pieces['i']!.pos, const Hex(3, 0));
    expect(after.pieces['x']!.pos, const Hex(0, 0));
  });
}
