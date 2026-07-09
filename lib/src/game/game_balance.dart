import 'dart:math';

import '../models/creature_rarity.dart';

class GameBalance {
  const GameBalance._();

  static const maxLogEntries = 80;
  static const criticalHitChanceDivisor = 10;

  /// Base critical-hit chance (0..1) before per-fighter item/buff bonuses.
  static const baseCritChance = 0.10;
  static const criticalHitModifier = 1.5;
  static const minimumDamage = 1.0;

  static const waveThemeLength = 5;
  static const maxWaveSize = 6;

  /// Maximum number of heroes the player can field in a single run.
  static const maxTeamSize = 6;

  /// Number of persistent, player-editable team presets (start-screen "Run" tab).
  static const teamSlotCount = 5;

  /// A wave that is still unresolved after this many rounds is decided by
  /// comparing the two teams' HP ratio (highest ratio wins the wave).
  /// Prevents endless stalemates.
  static const maxRoundsPerWave = 50;
  static const waveValueOffset = 0; //10
  static const waveRewardMultiplier = 10;
  static const killXpDivisor = 3;
  static const goldPerMobValue = 2;
  static const merchantChanceDivisor = 4;
  static const singlePotionCost = 95;
  static const teamPotionCost = 280;
  static const smallXpPotionCost = 120;
  static const largeXpPotionCost = 320;
  static const superXpPotionCost = 780;
  static const specialPotionCost = 240;
  static const specialBarUpgradeCost = 900;
  static const singlePotionHealRatio = .50;
  static const teamPotionHealRatio = .35;
  static const smallXpPotionAmount = 55;
  static const largeXpPotionAmount = 170;
  static const superXpPotionAmount = 460;
  static const finalThemeWaveRewardMultiplier = 2;
  static const postWaveHealRatio = .10;

  /// Item drops: 1-in-N chance per non-boss mob kill. Bosses always drop
  /// their category item.
  static const itemDropChanceDivisor = 16;

  // ── Enemy power scaling ─────────────────────────────────────────────────────
  // Mob base stats (HP/ATK/DEF) are multiplied by a wave-driven factor so that
  // enemies keep pace with — and eventually outpace — a snowballing hero build
  // (level cap + stacked relics). Compounding growth guarantees runs end.
  // Tuned by the balance simulator.

  /// Per-wave compounding growth of mob stats.
  static const waveScalingPerWave = 0.02;

  /// Stat multiplier applied to every mob spawned on [wave] (1 at wave 1).
  static double waveStatScale(int wave) {
    if (wave <= 1) return 1;
    return pow(1 + waveScalingPerWave, wave - 1).toDouble();
  }

  // ── Enemy items ─────────────────────────────────────────────────────────────
  // Past a wave threshold, mobs start carrying offensive relics, more of them
  // (and rarer) as the run goes on — so enemies can fight back with the same
  // systems heroes use (lifesteal, on-hit, double strike, crit).

  static const enemyItemStartWave = 25;
  static const enemyItemWavesPerRelic = 40;
  static const enemyMaxRelics = 4;

  /// Number of relics a mob spawned on [wave] carries.
  static int enemyRelicCount(int wave) {
    if (wave < enemyItemStartWave) return 0;
    return (1 + (wave - enemyItemStartWave) ~/ enemyItemWavesPerRelic).clamp(
      0,
      enemyMaxRelics,
    );
  }

  /// Rarity roll out of 100 for standard drops: < uncommon threshold is
  /// common, < legendary threshold is uncommon, the rest is legendary.
  static const itemUncommonThreshold = 75;
  static const itemLegendaryThreshold = 95;

  /// Hard cap on the summed double-strike chance from items.
  static const extraAttackChanceCap = .80;

  static const autoMultiTargetCount = 3;

  // ── Hero progression ───────────────────────────────────────────────────────
  // A hero has a single persistent level (in-run XP and duplicate XP feed the
  // same bar). Stats scale with diminishing returns per level; the XP needed
  // per level grows geometrically. All four constants are tuned by the
  // balance simulator.

  static const maxHeroLevel = 50;

  /// Stat bonus added at level 2, as a fraction of the hero's base stat.
  static const statLevelGain = 0.12;

  /// Each further level adds this share of the previous level's bonus
  /// (< 1 ⇒ degressive: every level grants less than the last).
  static const statLevelDecay = 0.93;

  /// XP to go from level 1 to 2.
  static const baseXpToNextLevel = 80.0;

  /// Geometric growth of the per-level XP requirement.
  static const xpLevelGrowth = 1.12;

  /// Cumulative stat-bonus fraction at [level] (level 1 = 0, degressive).
  /// Effective stat = base × (1 + statBonusForLevel(level)).
  static double statBonusForLevel(int level) {
    if (level <= 1) return 0;
    final steps = level - 1;
    return statLevelGain *
        (1 - pow(statLevelDecay, steps)) /
        (1 - statLevelDecay);
  }

  /// XP required to advance from [level] to [level] + 1.
  static int xpForLevel(int level) {
    return (baseXpToNextLevel * pow(xpLevelGrowth, level - 1)).round();
  }

  // ── Creature rarity budget ─────────────────────────────────────────────────
  // Every creature (mobs AND summonable heroes) derives its base stats from
  // its rarity anchor × its per-creature [StatWeights]. This is the single
  // tunable place for the whole power curve.
  //
  // HP scales linearly across the six tiers between [_rarityHpFloor] (1★) and
  // [_rarityHpCeil] (6★); ATK and DEF are fixed fractions of that HP anchor.
  // Anchors: 1★ ≈ 100/10/4 … 6★ ≈ 900/90/36.

  /// HP anchor of the lowest rarity (1★).
  static const _rarityHpFloor = 100.0;

  /// HP anchor of the highest rarity (6★).
  static const _rarityHpCeil = 900.0;

  /// ATK anchor as a fraction of the rarity HP anchor.
  static const rarityAtkRatio = 0.10;

  /// DEF anchor as a fraction of the rarity HP anchor.
  static const rarityDefRatio = 0.04;

  /// HP budget anchor for [rarity] before per-creature weights.
  static double rarityHpAnchor(CreatureRarity rarity) {
    final t = (rarity.stars - 1) / (CreatureRarity.values.length - 1);
    return _rarityHpFloor + (_rarityHpCeil - _rarityHpFloor) * t;
  }

  /// Final base HP for a creature of [rarity] with stat [weights].
  static double creatureHp(CreatureRarity rarity, StatWeights weights) =>
      rarityHpAnchor(rarity) * weights.hp;

  /// Final base ATK for a creature of [rarity] with stat [weights].
  static double creatureAttack(CreatureRarity rarity, StatWeights weights) =>
      rarityHpAnchor(rarity) * rarityAtkRatio * weights.atk;

  /// Final base DEF for a creature of [rarity] with stat [weights].
  static double creatureDefence(CreatureRarity rarity, StatWeights weights) =>
      rarityHpAnchor(rarity) * rarityDefRatio * weights.def;

  /// Reward/wave-pacing [value] per rarity. The wave generator affords mobs
  /// against a budget equal to the wave number, so [value] doubles as "the wave
  /// at which this tier starts showing up". Mythic (bosses) is set so they
  /// become a recurring wall well inside the playable range — without it the
  /// difficulty plateaus once epic mobs are reached (~wave 40) while heroes
  /// keep levelling, and every team trivially caps out.
  static const Map<CreatureRarity, int> _rarityValue = {
    CreatureRarity.common: 1,
    CreatureRarity.uncommon: 4,
    CreatureRarity.rare: 15,
    CreatureRarity.epic: 40,
    CreatureRarity.legendary: 90,
    CreatureRarity.mythic: 160,
  };

  static int rarityValue(CreatureRarity rarity) => _rarityValue[rarity]!;

  // ── Summon drop weights ────────────────────────────────────────────────────
  // Relative chance of summoning each rarity tier. A summon rolls a rarity by
  // these weights, then picks a creature uniformly within that tier. Tunable;
  // the x10 epic-pity guarantee (slice C) layers on top. Legendary (5★) has no
  // base-roster creatures yet (evolution-only), so its weight is 0 for now.
  static const Map<CreatureRarity, double> summonRarityWeights = {
    CreatureRarity.common: 50,
    CreatureRarity.uncommon: 30,
    CreatureRarity.rare: 14,
    CreatureRarity.epic: 5,
    CreatureRarity.legendary: 0,
    CreatureRarity.mythic: 1,
  };

  /// Summon weight for [rarity] (0 when the tier currently has no creatures).
  static double summonWeight(CreatureRarity rarity) =>
      summonRarityWeights[rarity] ?? 0;

  // ── Summon costs & rewards ─────────────────────────────────────────────────
  // The free first summon (player chooses a starter) is handled separately.

  /// Gem cost of a single summon.
  static const summonCostSingle = 50;

  /// Gem cost of a ten-pull (cheaper per pull, with the epic pity below).
  static const summonCostTen = 500;

  /// Number of creatures in a ten-pull.
  static const summonBatchSize = 10;

  /// A ten-pull guarantees at least one creature of this rarity or higher.
  static const summonPityFloor = CreatureRarity.epic;

  /// Fixed XP granted toward a creature's persistent level when a summon is a
  /// duplicate (already owned). No copies/shards system. Tunable.
  static const summonDuplicateXp = 60;

  // ── Evolution ──────────────────────────────────────────────────────────────
  // A creature at the max level can evolve (pay gems) into its predetermined
  // next form, one rarity tier up, restarting at level 1. Cost grows with the
  // target tier. Tunable.
  static const Map<CreatureRarity, int> _evolutionCost = {
    CreatureRarity.uncommon: 150,
    CreatureRarity.rare: 300,
    CreatureRarity.epic: 600,
    CreatureRarity.legendary: 1200,
    CreatureRarity.mythic: 2400,
  };

  /// Gem cost to evolve into a form of [targetRarity].
  static int evolutionCost(CreatureRarity targetRarity) =>
      _evolutionCost[targetRarity] ?? 300;
}
