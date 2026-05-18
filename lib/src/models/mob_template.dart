import 'dart:math';

import '../game/targeting.dart';
import 'enums.dart';
import 'fighter.dart';
import 'skill.dart';

class MobTemplate {
  const MobTemplate({
    required this.name,
    required this.hp,
    required this.attack,
    required this.defence,
    required this.value,
    required this.category,
    this.skillBuilder,
    this.isBoss = false,
  });

  final String name;
  final double hp;
  final double attack;
  final double defence;
  final int value;
  final MobCategory category;
  final Skill Function()? skillBuilder;
  final bool isBoss;

  Fighter build(String name, Random random) {
    final skill = skillBuilder?.call();
    return Fighter(
      name: name,
      maxHp: hp,
      attackPower: attack,
      baseDefence: defence,
      value: value,
      skill: skill,
      isBoss: isBoss,
      aiType: randomAi(skill, random),
    );
  }
}
