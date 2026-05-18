import '../models/fighter.dart';
import 'skills.dart';

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
