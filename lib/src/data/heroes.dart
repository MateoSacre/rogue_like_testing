import '../game/game_balance.dart';
import '../models/creature_rarity.dart';
import '../models/fighter.dart';
import '../models/skill.dart';
import 'skills.dart';

const List<String> heroNames = [
  'Paladin',
  'Warrior',
  'Artificier',
  'Archer',
  'Priest',
  'Mage',
];

/// The six classic heroes are summonable creatures at [CreatureRarity.rare]
/// (3★); their stats derive from that rarity's anchors modulated by the
/// per-hero role weights below — same system as the bestiary.
const _heroRarity = CreatureRarity.rare;

/// Builds a 3★ hero with stats derived from the rarity budget and [weights].
Fighter _hero(String name, StatWeights weights, Skill skill) {
  return Fighter(
    name: name,
    maxHp: GameBalance.creatureHp(_heroRarity, weights),
    attackPower: GameBalance.creatureAttack(_heroRarity, weights),
    baseDefence: GameBalance.creatureDefence(_heroRarity, weights),
    skill: skill,
    isHero: true,
    rarity: _heroRarity,
  );
}

List<Fighter> buildBaseTeam() {
  return [
    _hero('Paladin', CreatureRole.tank, protectSkill()),
    _hero('Warrior', CreatureRole.bruiser, deepCutSkill()),
    _hero('Artificier', CreatureRole.caster, nukeSkill()),
    _hero('Archer', CreatureRole.skirmisher, poisonArrowSkill()),
    _hero('Priest', CreatureRole.support, magicHealingSkill()),
    _hero('Mage', CreatureRole.caster, tripleBeamSkill()),
  ];
}

/// Builds [baseHero] scaled to [level]: every base stat is multiplied by the
/// degressive level bonus. [xp] is the persisted progress toward the next
/// level. Items, if any, are applied on top afterwards.
Fighter heroAtLevel(Fighter baseHero, int level, {int xp = 0}) {
  final hero = baseHero.copy();
  final safeLevel = level.clamp(1, GameBalance.maxHeroLevel);
  final multiplier = 1 + GameBalance.statBonusForLevel(safeLevel);
  hero.maxHp = baseHero.initialMaxHp * multiplier;
  hero.attackPower = baseHero.initialAttackPower * multiplier;
  hero.baseDefence = baseHero.initialBaseDefence * multiplier;
  hero.level = safeLevel;
  hero.xp = safeLevel >= GameBalance.maxHeroLevel ? 0 : xp;
  hero.hp = hero.maxHp;
  return hero;
}
