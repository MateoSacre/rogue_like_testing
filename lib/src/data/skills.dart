import 'dart:math';

import '../models/battle_actions.dart';
import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/skill.dart';
import '../models/status_effect.dart';
import '../utils/format.dart';
import '../game/game_balance.dart';

Skill skillFactoryFrom(Skill skill) {
  final result = skillFactoryFromName(skill.name);
  result.charge = skill.charge;
  result.chargeBars = skill.chargeBars;
  return result;
}

Skill skillFactoryFromName(String name) {
  return switch (name) {
    'Protect' => protectSkill(),
    'Power slash' => powerSlashSkill(),
    'Deep cut' => deepCutSkill(),
    'Nuke' => nukeSkill(),
    'Poison Arrow' => poisonArrowSkill(),
    'Magic Healing' => magicHealingSkill(),
    'Triple Beam' => tripleBeamSkill(),
    'Splash' => splashSkill(),
    _ => powerStrikeSkill(),
  };
}

Skill powerStrikeSkill({
  String name = 'Power Strike',
  TargetType targetType = TargetType.enemySingle,
  int cooldown = 3,
  double modifier = 2,
}) {
  return Skill(
    name: name,
    chargeMax: cooldown,
    targetType: targetType,
    description: 'Heavy single-target hit',
    shouldUse: (caster, targets) {
      if (targets.length == 1) {
        final target = targets.first;
        return target.hp > caster.attackPower &&
            target.defence <= caster.attackPower * modifier;
      }
      return true;
    },
    apply: (battle, caster, targets) {
      for (final target in targets) {
        battle.basicAttack(caster, target, modifier: modifier);
        battle.addLog('${caster.name} uses $name');
      }
    },
  );
}

Skill powerSlashSkill() {
  return powerStrikeSkill(name: 'Power slash', cooldown: 3, modifier: 3);
}

Skill deepCutSkill() {
  return Skill(
    name: 'Deep cut',
    chargeMax: 4,
    targetType: TargetType.enemySingleHighestHp,
    description: 'Attack and bleed the highest HP enemy',
    appliesNegativeEffect: true,
    apply: (battle, caster, targets) {
      for (final target in targets) {
        battle.basicAttack(caster, target);
        target.effects.add(
          StatusEffect(
            name: 'Deep cut',
            kind: EffectKind.recurrent,
            duration: 5,
            damage: 5,
          ),
        );
        battle.addLog('${target.name} is bleeding');
      }
    },
  );
}

Skill poisonArrowSkill({
  String name = 'Poison Arrow',
  TargetType targetType = TargetType.enemySingleHighestHp,
  int duration = 5,
  double damage = 2,
}) {
  return Skill(
    name: name,
    chargeMax: 3,
    targetType: targetType,
    description: 'Attack and poison a target',
    appliesNegativeEffect: true,
    apply: (battle, caster, targets) {
      for (final target in targets) {
        battle.basicAttack(caster, target);
        final alreadyPoisoned = target.effects.any(
          (effect) => effect.name == name,
        );
        if (!alreadyPoisoned) {
          target.effects.add(
            StatusEffect(
              name: name,
              kind: EffectKind.recurrent,
              duration: duration,
              damage: damage,
            ),
          );
          battle.addLog('${target.name} is poisoned');
        }
      }
    },
  );
}

Skill explosionSkill({
  required String name,
  required int cooldown,
  required TargetType targetType,
  int? targetCount,
  double? damage,
  bool isMultiplier = false,
}) {
  return Skill(
    name: name,
    chargeMax: cooldown,
    targetType: targetType,
    description: 'Area damage',
    shouldUse: (_, targets) => targets.length > 1,
    apply: (battle, caster, targets) {
      final trueTargets = targetCount == null
          ? targets
          : targets.take(targetCount).toList();
      for (final target in trueTargets) {
        final amount = isMultiplier
            ? caster.attackPower * (damage ?? 1.5)
            : (damage ?? caster.attackPower * 1.5);
        final dealt = target.takeDamage(amount);
        battle.addLog(
          '${caster.name} uses $name on ${target.name} for ${fmt(dealt)} dmg',
        );
      }
    },
  );
}

Skill nukeSkill() {
  return explosionSkill(
    name: 'Nuke',
    cooldown: 10,
    targetType: TargetType.enemyTeam,
    damage: 3,
    isMultiplier: true,
  );
}

Skill tripleBeamSkill() {
  return explosionSkill(
    name: 'Triple Beam',
    cooldown: 5,
    targetType: TargetType.enemyMultiTarget,
    targetCount: 3,
    damage: 16,
  );
}

Skill splashSkill() {
  return Skill(
    name: 'Splash',
    chargeMax: 2,
    targetType: TargetType.enemyTeam,
    description: 'Deals 1 damage to all enemies',
    shouldUse: (_, targets) => targets.length > 1,
    apply: (battle, caster, targets) {
      for (final target in targets) {
        final dealt = target.takeDamage(1);
        battle.addLog(
          '${caster.name} splashes ${target.name} for ${fmt(dealt)} dmg',
        );
      }
    },
  );
}

Skill magicHealingSkill() {
  return Skill(
    name: 'Magic Healing',
    chargeMax: 3,
    targetType: TargetType.allySingleLowestHp,
    description: 'Heal the weakest ally for 30%',
    shouldUse: (_, targets) =>
        targets.isNotEmpty && targets.first.hp < targets.first.maxHp,
    apply: (battle, caster, targets) {
      for (final target in targets) {
        final healed = target.heal(target.maxHp * .30);
        battle.addLog(
          '${caster.name} heals ${target.name} for ${fmt(healed)} hp',
        );
      }
    },
  );
}

Skill protectSkill() {
  return Skill(
    name: 'Protect',
    chargeMax: 3,
    targetType: TargetType.allySingleLowestHp,
    description: 'Give +10 defence for 3 turns',
    apply: (battle, caster, targets) {
      _applyProtection(battle, caster, targets);
    },
  );
}

void _applyProtection(
  BattleActions battle,
  Fighter caster,
  List<Fighter> targets,
) {
  for (final target in targets) {
    final alreadyProtected = target.effects.any(
      (effect) => effect.name == 'Protect',
    );
    if (!alreadyProtected) {
      target.effects.add(
        StatusEffect(
          name: 'Protect',
          kind: EffectKind.buff,
          duration: 3,
          defenceBonus: 10,
        ),
      );
      battle.addLog('${caster.name} protects ${target.name}');
    }
  }
}

double levelIncrease(double currentValue) {
  return max(
    GameBalance.minimumLevelIncrease,
    (currentValue * GameBalance.levelUpStatRatio).ceilToDouble(),
  );
}
