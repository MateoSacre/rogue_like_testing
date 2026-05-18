class GameBalance {
  const GameBalance._();

  static const maxLogEntries = 80;
  static const criticalHitChanceDivisor = 10;
  static const criticalHitModifier = 1.5;
  static const minimumDamage = 1.0;
  static const minimumLevelIncrease = 1.0;

  static const waveThemeLength = 5;
  static const maxWaveSize = 6;
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

  static const baseXpCap = 100.0;
  static const xpCapBaseMultiplier = 1.02;
  static const xpCapCurveMultiplier = .48;
  static const xpCapSlopeModifier = .00001;
  static const levelUpStatRatio = .05;

  static const autoMultiTargetCount = 3;
}
