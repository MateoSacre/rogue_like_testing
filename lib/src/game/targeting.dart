import 'dart:math';

import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/skill.dart';
import '../models/team.dart';
import 'game_balance.dart';

List<Fighter> manualTargetsForSkill(
  Fighter caster,
  Skill skill,
  Team attacker,
  Team defender,
) {
  return switch (skill.targetType) {
    TargetType.self => [caster],
    TargetType.allySingle ||
    TargetType.allySingleLowestHp ||
    TargetType.allyTeam => attacker.alive,
    TargetType.enemySingle ||
    TargetType.enemySingleHighestHp ||
    TargetType.enemyMultiTarget ||
    TargetType.enemyTeam => defender.alive,
  };
}

List<Fighter> autoTargetsForSkill(
  Fighter caster,
  Skill skill,
  Team attacker,
  Team defender,
) {
  return switch (skill.targetType) {
    TargetType.self => [caster],
    TargetType.allySingle => [
      attacker.alive.firstWhere((x) => x != caster, orElse: () => caster),
    ],
    TargetType.allySingleLowestHp => [lowestHp(attacker.alive)],
    TargetType.allyTeam => attacker.alive,
    TargetType.enemySingle => [defender.alive.first],
    TargetType.enemySingleHighestHp => [highestHp(defender.alive)],
    TargetType.enemyMultiTarget => pickMobTargets(
      caster,
      defender.alive,
      min(GameBalance.autoMultiTargetCount, defender.alive.length),
    ),
    TargetType.enemyTeam => pickMobTargets(
      caster,
      defender.alive,
      defender.alive.length,
    ),
  };
}

List<Fighter> pickMobTargets(
  Fighter mob,
  List<Fighter> candidates,
  int maximumTargets,
) {
  final ordered = [...candidates];
  switch (mob.aiType) {
    case AiType.dumb:
      break;
    case AiType.random:
      ordered.shuffle();
    case AiType.killer:
      ordered.sort((a, b) => (a.hp / a.maxHp).compareTo(b.hp / b.maxHp));
    case AiType.damager:
      ordered.sort((a, b) => a.defence.compareTo(b.defence));
    case AiType.effectDealer:
      ordered.sort((a, b) {
        final aHasEffect = a.effects.any((e) => e.kind == EffectKind.recurrent);
        final bHasEffect = b.effects.any((e) => e.kind == EffectKind.recurrent);
        return aHasEffect == bHasEffect ? 0 : (aHasEffect ? 1 : -1);
      });
    case AiType.effectStacker:
      ordered.sort((a, b) {
        final aHasEffect = a.effects.any((e) => e.kind == EffectKind.recurrent);
        final bHasEffect = b.effects.any((e) => e.kind == EffectKind.recurrent);
        return aHasEffect == bHasEffect ? 0 : (aHasEffect ? -1 : 1);
      });
  }
  return ordered.take(maximumTargets).toList();
}

Fighter lowestHp(List<Fighter> fighters) {
  return fighters.reduce((a, b) => a.hp / a.maxHp <= b.hp / b.maxHp ? a : b);
}

Fighter highestHp(List<Fighter> fighters) {
  return fighters.reduce((a, b) => a.hp / a.maxHp >= b.hp / b.maxHp ? a : b);
}

AiType randomAi(Skill? skill, Random random) {
  final types = [AiType.dumb, AiType.random, AiType.killer, AiType.damager];
  if (skill != null && skill.appliesNegativeEffect && skill.targetsEnemies) {
    types.addAll([AiType.effectDealer, AiType.effectStacker]);
  }
  return types[random.nextInt(types.length)];
}
