import '../models/level_up_stat.dart';

class HeroStatPoints {
  const HeroStatPoints({this.maxHp = 0, this.attack = 0, this.defence = 0});

  factory HeroStatPoints.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HeroStatPoints();
    return HeroStatPoints(
      maxHp: json[LevelUpStat.maxHp.name] as int? ?? 0,
      attack: json[LevelUpStat.attack.name] as int? ?? 0,
      defence: json[LevelUpStat.defence.name] as int? ?? 0,
    );
  }

  final int maxHp;
  final int attack;
  final int defence;

  int get total => maxHp + attack + defence;

  int valueFor(LevelUpStat stat) {
    return switch (stat) {
      LevelUpStat.maxHp => maxHp,
      LevelUpStat.attack => attack,
      LevelUpStat.defence => defence,
    };
  }

  HeroStatPoints add(LevelUpStat stat) {
    return switch (stat) {
      LevelUpStat.maxHp => HeroStatPoints(
        maxHp: maxHp + 1,
        attack: attack,
        defence: defence,
      ),
      LevelUpStat.attack => HeroStatPoints(
        maxHp: maxHp,
        attack: attack + 1,
        defence: defence,
      ),
      LevelUpStat.defence => HeroStatPoints(
        maxHp: maxHp,
        attack: attack,
        defence: defence + 1,
      ),
    };
  }

  HeroStatPoints remove(LevelUpStat stat) {
    return switch (stat) {
      LevelUpStat.maxHp => HeroStatPoints(
        maxHp: maxHp == 0 ? 0 : maxHp - 1,
        attack: attack,
        defence: defence,
      ),
      LevelUpStat.attack => HeroStatPoints(
        maxHp: maxHp,
        attack: attack == 0 ? 0 : attack - 1,
        defence: defence,
      ),
      LevelUpStat.defence => HeroStatPoints(
        maxHp: maxHp,
        attack: attack,
        defence: defence == 0 ? 0 : defence - 1,
      ),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      LevelUpStat.maxHp.name: maxHp,
      LevelUpStat.attack.name: attack,
      LevelUpStat.defence.name: defence,
    };
  }
}
