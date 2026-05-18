import '../utils/format.dart';
import 'fighter.dart';

enum LevelUpStat {
  maxHp('Max HP'),
  attack('Attack'),
  defence('Defence');

  const LevelUpStat(this.label);

  final String label;

  double currentValue(Fighter hero) {
    return switch (this) {
      LevelUpStat.maxHp => hero.maxHp,
      LevelUpStat.attack => hero.attackPower,
      LevelUpStat.defence => hero.baseDefence,
    };
  }

  double baseValue(Fighter hero) {
    return switch (this) {
      LevelUpStat.maxHp => hero.initialMaxHp,
      LevelUpStat.attack => hero.initialAttackPower,
      LevelUpStat.defence => hero.initialBaseDefence,
    };
  }

  String describe(Fighter hero, double increase) {
    return '$label (${fmt(currentValue(hero))} -> ${fmt(currentValue(hero) + increase)})';
  }
}

class PendingLevelUp {
  const PendingLevelUp(this.hero);

  final Fighter hero;
}
