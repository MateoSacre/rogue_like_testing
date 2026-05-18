import '../models/fighter.dart';
import '../models/level_up_stat.dart';
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
  required int Function(String heroName, LevelUpStat stat) statPointsFor,
}) {
  final selected = selectedHeroNames.toSet();
  return buildHeroRoster()
      .where((hero) => selected.contains(hero.name))
      .map(
        (hero) => heroWithPermanentStats(
          hero,
          levelFor(hero.name),
          (stat) => statPointsFor(hero.name, stat),
        ),
      )
      .toList();
}

Fighter heroWithPermanentStats(
  Fighter baseHero,
  int permanentLevel,
  int Function(LevelUpStat stat) statPointsFor,
) {
  final hero = baseHero.copy();
  final safeLevel = permanentLevel.clamp(1, 50);
  hero.maxHp += statPointsFor(LevelUpStat.maxHp);
  hero.attackPower += statPointsFor(LevelUpStat.attack);
  hero.baseDefence += statPointsFor(LevelUpStat.defence);
  hero.level = safeLevel;
  hero.xp = 0;
  hero.hp = hero.maxHp;
  return hero;
}
