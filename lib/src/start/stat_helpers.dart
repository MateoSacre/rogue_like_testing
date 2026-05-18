part of 'start_screen.dart';

String _shortStat(LevelUpStat stat) {
  return switch (stat) {
    LevelUpStat.maxHp => 'HP',
    LevelUpStat.attack => 'ATK',
    LevelUpStat.defence => 'DEF',
  };
}
