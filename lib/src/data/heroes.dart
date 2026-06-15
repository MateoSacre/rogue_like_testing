import '../game/game_balance.dart';
import '../models/fighter.dart';
import 'skills.dart';

const List<String> heroNames = [
  'Paladin',
  'Warrior',
  'Artificier',
  'Archer',
  'Priest',
  'Mage',
];

List<Fighter> buildBaseTeam() {
  return [
    Fighter(
      name: 'Paladin',
      maxHp: 25,
      attackPower: 3,
      baseDefence: 7,
      skill: protectSkill(),
      isHero: true,
    ),
    // Fighter(
    //   name: 'Hero',
    //   maxHp: 20,
    //   attackPower: 5,
    //   baseDefence: 5,
    //   skill: powerSlashSkill(),
    //   isHero: true,
    // ),
    Fighter(
      name: 'Warrior',
      maxHp: 15,
      attackPower: 7,
      baseDefence: 3,
      skill: deepCutSkill(),
      isHero: true,
    ),
    Fighter(
      name: 'Artificier',
      maxHp: 10,
      attackPower: 10,
      baseDefence: 5,
      skill: nukeSkill(),
      isHero: true,
    ),
    Fighter(
      name: 'Archer',
      maxHp: 15,
      attackPower: 5,
      baseDefence: 5,
      skill: poisonArrowSkill(),
      isHero: true,
    ),
    Fighter(
      name: 'Priest',
      maxHp: 15,
      attackPower: 2,
      baseDefence: 3,
      skill: magicHealingSkill(),
      isHero: true,
    ),
    Fighter(
      name: 'Mage',
      maxHp: 15,
      attackPower: 8,
      baseDefence: 2,
      skill: tripleBeamSkill(),
      isHero: true,
    ),
  ];
}

List<Fighter> buildHeroRoster() {
  return buildBaseTeam();
}

List<Fighter> buildTeamFromProgress({
  required Iterable<String> selectedHeroNames,
  required int Function(String heroName) levelFor,
  required int Function(String heroName) xpFor,
}) {
  final selected = selectedHeroNames.toSet();
  return buildHeroRoster()
      .where((hero) => selected.contains(hero.name))
      .map((hero) => heroAtLevel(hero, levelFor(hero.name), xp: xpFor(hero.name)))
      .toList();
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
