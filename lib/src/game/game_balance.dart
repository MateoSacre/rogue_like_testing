import 'dart:math';

class GameBalance {
  const GameBalance._();

  static const maxLogEntries = 80;
  static const criticalHitChanceDivisor = 10;
  static const criticalHitModifier = 1.5;
  static const minimumDamage = 1.0;

  static const waveThemeLength = 5;
  static const maxWaveSize = 6;

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
  static const itemDropChanceDivisor = 8;

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
}
