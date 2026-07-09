import 'dart:math';

import '../data/creatures.dart';
import '../game/game_balance.dart';
import '../models/creature_rarity.dart';

/// Outcome of summoning one creature.
class SummonResult {
  const SummonResult({
    required this.creatureId,
    required this.rarity,
    required this.isNew,
    required this.xpGained,
  });

  /// Catalog id of the summoned creature.
  final String creatureId;
  final CreatureRarity rarity;

  /// True when this summon unlocked the creature for the first time.
  final bool isNew;

  /// Duplicate XP actually granted toward the creature's level (0 when [isNew]
  /// or the creature is already at the max level).
  final int xpGained;
}

/// Rolls a rarity tier weighted by [GameBalance.summonRarityWeights], among the
/// tiers that both carry a positive weight and actually have creatures.
CreatureRarity rollSummonRarity(Random random) {
  final tiers = CreatureRarity.values
      .where(
        (r) =>
            GameBalance.summonWeight(r) > 0 && summonableByRarity(r).isNotEmpty,
      )
      .toList();
  final total = tiers.fold<double>(0, (sum, r) => sum + GameBalance.summonWeight(r));
  var roll = random.nextDouble() * total;
  for (final rarity in tiers) {
    roll -= GameBalance.summonWeight(rarity);
    if (roll < 0) return rarity;
  }
  return tiers.last;
}

/// Rolls a single creature: pick a rarity by weight, then a creature uniformly
/// within that tier.
CreatureDef rollSummon(Random random) {
  final pool = summonableByRarity(rollSummonRarity(random));
  return pool[random.nextInt(pool.length)];
}

/// Rolls a [count]-creature batch and applies the pity rule: if no roll is at
/// least [pityFloor], one random slot is replaced with a random creature of the
/// pity-floor tier. A natural roll above the floor (e.g. a mythic) satisfies it.
List<CreatureDef> rollSummonBatch(
  Random random, {
  int count = GameBalance.summonBatchSize,
  CreatureRarity pityFloor = GameBalance.summonPityFloor,
}) {
  final rolls = List.generate(count, (_) => rollSummon(random));
  final satisfied = rolls.any((def) => def.rarity.stars >= pityFloor.stars);
  if (!satisfied) {
    final floorPool = summonableByRarity(pityFloor);
    if (floorPool.isNotEmpty) {
      rolls[random.nextInt(count)] = floorPool[random.nextInt(floorPool.length)];
    }
  }
  return rolls;
}
