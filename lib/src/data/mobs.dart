import '../models/creature_rarity.dart';
import '../models/enums.dart';
import '../models/mob_template.dart';
import 'skills.dart';

/// Bestiary. Each category holds four regular mobs spanning rarities
/// common → epic (1★ → 4★, by power rank) plus one mythic (6★) boss. Stats are
/// derived from the rarity anchors in `GameBalance` modulated by per-mob
/// [StatWeights]; only the rarity, role and skill define a mob here.
///
/// Flat skill numbers (AoE damage, DoT damage, buff bonuses) are tuned to the
/// post-rescale stat scale (~100 HP at 1★ … ~900 HP at 6★).
final List<MobTemplate> mobRoster = [
  // ── Monsters ───────────────────────────────────────────────────────────────
  MobTemplate(
    name: 'Slime',
    rarity: CreatureRarity.common,
    weights: CreatureRole.balanced,
    category: MobCategory.monsters,
    skillBuilder: splashSkill,
  ),
  MobTemplate(
    name: 'Dire Wolf',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.bruiser,
    category: MobCategory.monsters,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Pounce', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Venommaw',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.skirmisher,
    category: MobCategory.monsters,
    skillBuilder: () => poisonArrowSkill(
      name: 'Venom Bite',
      targetType: TargetType.enemySingle,
      duration: 4,
    ),
  ),
  MobTemplate(
    name: 'Bonehide',
    rarity: CreatureRarity.epic,
    weights: CreatureRole.tank,
    category: MobCategory.monsters,
    skillBuilder: () => buffSkill(
      name: 'Bone Wall',
      description: 'Hardens allies (+8 DEF)',
      defenceBonus: 8,
    ),
  ),
  MobTemplate(
    name: 'World Ender',
    rarity: CreatureRarity.mythic,
    weights: CreatureRole.balanced,
    category: MobCategory.monsters,
    isBoss: true,
    skillBuilder: () => explosionSkill(
      name: 'World End',
      cooldown: 4,
      targetType: TargetType.enemyTeam,
      damage: 2.5,
      isMultiplier: true,
    ),
  ),

  // ── Bandits ──────────────────────────────────────────────────────────────
  MobTemplate(
    name: 'Cutpurse',
    rarity: CreatureRarity.common,
    weights: CreatureRole.skirmisher,
    category: MobCategory.bandits,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Backstab', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Highway Scout',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.support,
    category: MobCategory.bandits,
    skillBuilder: () => buffSkill(
      name: 'Rally',
      description: 'Rallies allies (+6 ATK)',
      attackBonus: 6,
    ),
  ),
  MobTemplate(
    name: 'Assassin',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.skirmisher,
    category: MobCategory.bandits,
    skillBuilder: deepCutSkill,
  ),
  MobTemplate(
    name: 'War Wagon',
    rarity: CreatureRarity.epic,
    weights: CreatureRole.tank,
    category: MobCategory.bandits,
    skillBuilder: () => explosionSkill(
      name: 'Ram',
      cooldown: 4,
      targetType: TargetType.enemyMultiTarget,
      targetCount: 2,
    ),
  ),
  MobTemplate(
    name: 'Tyrant of Knives',
    rarity: CreatureRarity.mythic,
    weights: CreatureRole.skirmisher,
    category: MobCategory.bandits,
    isBoss: true,
    skillBuilder: () => explosionSkill(
      name: 'Blade Storm',
      cooldown: 4,
      targetType: TargetType.enemyTeam,
      damage: 2,
      isMultiplier: true,
    ),
  ),

  // ── Cultists ─────────────────────────────────────────────────────────────
  MobTemplate(
    name: 'Initiate',
    rarity: CreatureRarity.common,
    weights: CreatureRole.support,
    category: MobCategory.cultists,
    skillBuilder: () => buffSkill(
      name: 'Dark Chant',
      description: 'Chants for allies (+4 ATK)',
      attackBonus: 4,
    ),
  ),
  MobTemplate(
    name: 'Acolyte',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.support,
    category: MobCategory.cultists,
    skillBuilder: protectSkill,
  ),
  MobTemplate(
    name: 'Plague Cantor',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.caster,
    category: MobCategory.cultists,
    skillBuilder: () => poisonArrowSkill(name: 'Virulent Hymn', duration: 5),
  ),
  MobTemplate(
    name: 'Void Caller',
    rarity: CreatureRarity.epic,
    weights: CreatureRole.caster,
    category: MobCategory.cultists,
    skillBuilder: () => explosionSkill(
      name: 'Void Pulse',
      cooldown: 5,
      targetType: TargetType.enemyTeam,
      damage: 56,
    ),
  ),
  MobTemplate(
    name: 'Apocalypse Choir',
    rarity: CreatureRarity.mythic,
    weights: CreatureRole.caster,
    category: MobCategory.cultists,
    isBoss: true,
    skillBuilder: () => explosionSkill(
      name: 'Apocalypse',
      cooldown: 4,
      targetType: TargetType.enemyTeam,
      damage: 2.5,
      isMultiplier: true,
    ),
  ),

  // ── Mages ────────────────────────────────────────────────────────────────
  MobTemplate(
    name: 'Spark Familiar',
    rarity: CreatureRarity.common,
    weights: CreatureRole.caster,
    category: MobCategory.mages,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Spark', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Rune Adept',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.caster,
    category: MobCategory.mages,
    skillBuilder: () => explosionSkill(
      name: 'Rune Blast',
      cooldown: 4,
      targetType: TargetType.enemyMultiTarget,
      targetCount: 2,
      damage: 42,
    ),
  ),
  MobTemplate(
    name: 'Pyromancer',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.caster,
    category: MobCategory.mages,
    skillBuilder: () => explosionSkill(
      name: 'Fire Burst',
      cooldown: 5,
      targetType: TargetType.enemyTeam,
      damage: 49,
    ),
  ),
  MobTemplate(
    name: 'Chrono Mage',
    rarity: CreatureRarity.epic,
    weights: CreatureRole.caster,
    category: MobCategory.mages,
    skillBuilder: () => explosionSkill(
      name: 'Time Rupture',
      cooldown: 4,
      targetType: TargetType.enemyMultiTarget,
      targetCount: 4,
      damage: 126,
    ),
  ),
  MobTemplate(
    name: 'Cataclysm Sage',
    rarity: CreatureRarity.mythic,
    weights: CreatureRole.caster,
    category: MobCategory.mages,
    isBoss: true,
    skillBuilder: () => explosionSkill(
      name: 'Cataclysm',
      cooldown: 4,
      targetType: TargetType.enemyTeam,
      damage: 2.6,
      isMultiplier: true,
    ),
  ),

  // ── Empire ───────────────────────────────────────────────────────────────
  MobTemplate(
    name: 'Recruit',
    rarity: CreatureRarity.common,
    weights: CreatureRole.balanced,
    category: MobCategory.empire,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Stab', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Legionnaire',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.tank,
    category: MobCategory.empire,
    skillBuilder: () => buffSkill(
      name: 'Shield Wall',
      description: 'Raises shields (+10 DEF)',
      defenceBonus: 10,
    ),
  ),
  MobTemplate(
    name: 'War Priest',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.support,
    category: MobCategory.empire,
    skillBuilder: protectSkill,
  ),
  MobTemplate(
    name: 'Siege Engineer',
    rarity: CreatureRarity.epic,
    weights: CreatureRole.caster,
    category: MobCategory.empire,
    skillBuilder: () => explosionSkill(
      name: 'Bombardment',
      cooldown: 5,
      targetType: TargetType.enemyTeam,
      damage: 56,
    ),
  ),
  MobTemplate(
    name: 'Emperor Wrath',
    rarity: CreatureRarity.mythic,
    weights: CreatureRole.bruiser,
    category: MobCategory.empire,
    isBoss: true,
    skillBuilder: () => buffSkill(
      name: 'Imperial Command',
      description: 'Commands the legion (+12 ATK, +12 DEF)',
      attackBonus: 12,
      defenceBonus: 12,
      cooldown: 3,
    ),
  ),

  // ── Ghosts ───────────────────────────────────────────────────────────────
  MobTemplate(
    name: 'Wisp',
    rarity: CreatureRarity.common,
    weights: CreatureRole.caster,
    category: MobCategory.ghosts,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Haunt', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Haunter',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.skirmisher,
    category: MobCategory.ghosts,
    skillBuilder: () => poisonArrowSkill(
      name: 'Curse',
      targetType: TargetType.enemySingle,
      duration: 4,
    ),
  ),
  MobTemplate(
    name: 'Crypt Lord',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.support,
    category: MobCategory.ghosts,
    skillBuilder: magicHealingSkill,
  ),
  MobTemplate(
    name: 'Soul Reaper',
    rarity: CreatureRarity.epic,
    weights: CreatureRole.skirmisher,
    category: MobCategory.ghosts,
    skillBuilder: deepCutSkill,
  ),
  MobTemplate(
    name: 'Lich King',
    rarity: CreatureRarity.mythic,
    weights: CreatureRole.caster,
    category: MobCategory.ghosts,
    isBoss: true,
    skillBuilder: () => explosionSkill(
      name: 'Death Nova',
      cooldown: 4,
      targetType: TargetType.enemyTeam,
      damage: 2.4,
      isMultiplier: true,
    ),
  ),

  // ── Giants ───────────────────────────────────────────────────────────────
  MobTemplate(
    name: 'Pebbleling',
    rarity: CreatureRarity.common,
    weights: CreatureRole.bruiser,
    category: MobCategory.giants,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Throw Rock', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Young Giant',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.bruiser,
    category: MobCategory.giants,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Smash', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Stone Giant',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.tank,
    category: MobCategory.giants,
    skillBuilder: () => buffSkill(
      name: 'Stone Skin',
      description: 'Toughens allies (+12 DEF)',
      defenceBonus: 12,
    ),
  ),
  MobTemplate(
    name: 'Storm Giant',
    rarity: CreatureRarity.epic,
    weights: CreatureRole.bruiser,
    category: MobCategory.giants,
    skillBuilder: () => explosionSkill(
      name: 'Thunderclap',
      cooldown: 4,
      targetType: TargetType.enemyTeam,
      damage: 84,
    ),
  ),
  MobTemplate(
    name: 'Ancient Titan',
    rarity: CreatureRarity.mythic,
    weights: CreatureRole.bruiser,
    category: MobCategory.giants,
    isBoss: true,
    skillBuilder: () => explosionSkill(
      name: 'Titan Quake',
      cooldown: 4,
      targetType: TargetType.enemyTeam,
      damage: 2.8,
      isMultiplier: true,
    ),
  ),

  // ── Evolution forms ──────────────────────────────────────────────────────
  // Each category's 1★ common evolves up a line (1★ → 2★ → 3★) into these
  // dedicated forms. They spawn in waves like any mob but are NOT summonable
  // (only obtainable by evolving the base creature). Same role and skill as
  // their base; stats follow the higher rarity anchors automatically.
  MobTemplate(
    name: 'Gros Slime',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.balanced,
    category: MobCategory.monsters,
    summonable: false,
    skillBuilder: splashSkill,
  ),
  MobTemplate(
    name: 'Roi Slime',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.balanced,
    category: MobCategory.monsters,
    summonable: false,
    skillBuilder: splashSkill,
  ),
  MobTemplate(
    name: 'Brigand',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.skirmisher,
    category: MobCategory.bandits,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Backstab', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Bandit Chief',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.skirmisher,
    category: MobCategory.bandits,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Backstab', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Zealot',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.support,
    category: MobCategory.cultists,
    summonable: false,
    skillBuilder: () => buffSkill(
      name: 'Dark Chant',
      description: 'Chants for allies (+4 ATK)',
      attackBonus: 4,
    ),
  ),
  MobTemplate(
    name: 'High Zealot',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.support,
    category: MobCategory.cultists,
    summonable: false,
    skillBuilder: () => buffSkill(
      name: 'Dark Chant',
      description: 'Chants for allies (+4 ATK)',
      attackBonus: 4,
    ),
  ),
  MobTemplate(
    name: 'Flame Familiar',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.caster,
    category: MobCategory.mages,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Spark', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Inferno Familiar',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.caster,
    category: MobCategory.mages,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Spark', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Soldier',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.balanced,
    category: MobCategory.empire,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Stab', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Veteran',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.balanced,
    category: MobCategory.empire,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Stab', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Shade',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.caster,
    category: MobCategory.ghosts,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Haunt', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Wraith',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.caster,
    category: MobCategory.ghosts,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Haunt', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Boulderkin',
    rarity: CreatureRarity.uncommon,
    weights: CreatureRole.bruiser,
    category: MobCategory.giants,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Throw Rock', cooldown: 3, modifier: 2),
  ),
  MobTemplate(
    name: 'Rockfist',
    rarity: CreatureRarity.rare,
    weights: CreatureRole.bruiser,
    category: MobCategory.giants,
    summonable: false,
    skillBuilder: () =>
        powerStrikeSkill(name: 'Throw Rock', cooldown: 3, modifier: 2),
  ),
];
