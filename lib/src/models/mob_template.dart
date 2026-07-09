import 'dart:math';

import '../game/game_balance.dart';
import '../game/targeting.dart';
import 'creature_rarity.dart';
import 'enums.dart';
import 'fighter.dart';
import 'skill.dart';

class MobTemplate {
  const MobTemplate({
    required this.name,
    required this.rarity,
    required this.category,
    this.weights = const StatWeights(),
    this.skillBuilder,
    this.isBoss = false,
    this.summonable = true,
  });

  final String name;

  /// Fixed rarity tier; drives the derived stats and [value].
  final CreatureRarity rarity;

  /// Per-creature stat lean applied on top of the rarity anchors.
  final StatWeights weights;

  final MobCategory category;
  final Skill Function()? skillBuilder;
  final bool isBoss;

  /// Whether this mob can be obtained from the summon pool. Evolution-only
  /// forms spawn in waves but are excluded from summoning.
  final bool summonable;

  double get hp => GameBalance.creatureHp(rarity, weights);
  double get attack => GameBalance.creatureAttack(rarity, weights);
  double get defence => GameBalance.creatureDefence(rarity, weights);
  int get value => GameBalance.rarityValue(rarity);

  Fighter build(String name, Random random) {
    final skill = skillBuilder?.call();
    return Fighter(
      name: name,
      maxHp: hp,
      attackPower: attack,
      baseDefence: defence,
      value: value,
      rarity: rarity,
      skill: skill,
      isBoss: isBoss,
      aiType: randomAi(skill, random),
    );
  }
}
