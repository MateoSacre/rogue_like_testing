import '../models/level_up_stat.dart';

class HeroStatPoints {
  const HeroStatPoints({
    this.maxHp = 0,
    this.attack = 0,
    this.defence = 0,
    this.unassigned = 0,
  });

  factory HeroStatPoints.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HeroStatPoints();
    return HeroStatPoints(
      maxHp: json[LevelUpStat.maxHp.name] as int? ?? 0,
      attack: json[LevelUpStat.attack.name] as int? ?? 0,
      defence: json[LevelUpStat.defence.name] as int? ?? 0,
      unassigned: json['unassigned'] as int? ?? 0,
    );
  }

  final int maxHp;
  final int attack;
  final int defence;
  final int unassigned;

  int get total => maxHp + attack + defence + unassigned;

  int valueFor(LevelUpStat stat) {
    return switch (stat) {
      LevelUpStat.maxHp => maxHp,
      LevelUpStat.attack => attack,
      LevelUpStat.defence => defence,
    };
  }

  HeroStatPoints addUnassigned() {
    return HeroStatPoints(
      maxHp: maxHp,
      attack: attack,
      defence: defence,
      unassigned: unassigned + 1,
    );
  }

  HeroStatPoints assign(LevelUpStat stat) {
    if (unassigned <= 0) return this;
    return switch (stat) {
      LevelUpStat.maxHp => HeroStatPoints(
        maxHp: maxHp + 1,
        attack: attack,
        defence: defence,
        unassigned: unassigned - 1,
      ),
      LevelUpStat.attack => HeroStatPoints(
        maxHp: maxHp,
        attack: attack + 1,
        defence: defence,
        unassigned: unassigned - 1,
      ),
      LevelUpStat.defence => HeroStatPoints(
        maxHp: maxHp,
        attack: attack,
        defence: defence + 1,
        unassigned: unassigned - 1,
      ),
    };
  }

  HeroStatPoints unassign(LevelUpStat stat) {
    return switch (stat) {
      LevelUpStat.maxHp => HeroStatPoints(
        maxHp: maxHp == 0 ? 0 : maxHp - 1,
        attack: attack,
        defence: defence,
        unassigned: maxHp == 0 ? unassigned : unassigned + 1,
      ),
      LevelUpStat.attack => HeroStatPoints(
        maxHp: maxHp,
        attack: attack == 0 ? 0 : attack - 1,
        defence: defence,
        unassigned: attack == 0 ? unassigned : unassigned + 1,
      ),
      LevelUpStat.defence => HeroStatPoints(
        maxHp: maxHp,
        attack: attack,
        defence: defence == 0 ? 0 : defence - 1,
        unassigned: defence == 0 ? unassigned : unassigned + 1,
      ),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      LevelUpStat.maxHp.name: maxHp,
      LevelUpStat.attack.name: attack,
      LevelUpStat.defence.name: defence,
      'unassigned': unassigned,
    };
  }
}
