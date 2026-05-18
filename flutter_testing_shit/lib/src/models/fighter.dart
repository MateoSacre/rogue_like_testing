import 'dart:math';

import '../data/skills.dart';
import '../game/game_balance.dart';
import 'enums.dart';
import 'skill.dart';
import 'status_effect.dart';

class Fighter {
  Fighter({
    required this.name,
    required this.maxHp,
    required this.attackPower,
    required this.baseDefence,
    this.skill,
    this.value = 0,
    this.isHero = false,
    this.isBoss = false,
    this.aiType = AiType.dumb,
  }) : hp = maxHp,
       initialMaxHp = maxHp,
       initialAttackPower = attackPower,
       initialBaseDefence = baseDefence;

  String name;
  double hp;
  double maxHp;
  double attackPower;
  double baseDefence;
  final double initialMaxHp;
  final double initialAttackPower;
  final double initialBaseDefence;
  Skill? skill;
  int value;
  bool isHero;
  bool isBoss;
  AiType aiType;
  int level = 1;
  int xp = 0;
  final List<StatusEffect> effects = [];

  bool get isAlive => hp > 0;

  double get defence {
    final bonus = effects
        .where((effect) => effect.kind == EffectKind.buff)
        .fold<double>(0, (sum, effect) => sum + effect.defenceBonus);
    return baseDefence + bonus;
  }

  String get statusLabel {
    if (effects.isEmpty) return '';
    return effects
        .map((effect) => '${effect.name} ${effect.duration}')
        .join(' | ');
  }

  int get xpCap {
    var cap = GameBalance.baseXpCap;
    for (var i = 1; i < level; i++) {
      cap *=
          GameBalance.xpCapBaseMultiplier +
          GameBalance.xpCapCurveMultiplier *
              exp(-GameBalance.xpCapSlopeModifier * i);
    }
    return cap.round();
  }

  Fighter copy({String? renamed}) {
    return Fighter(
      name: renamed ?? name,
      maxHp: maxHp,
      attackPower: attackPower,
      baseDefence: baseDefence,
      skill: skill == null ? null : skillFactoryFrom(skill!),
      value: value,
      isHero: isHero,
      isBoss: isBoss,
      aiType: aiType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hp': hp,
      'maxHp': maxHp,
      'attackPower': attackPower,
      'baseDefence': baseDefence,
      'skillName': skill?.name,
      'skillCharge': skill?.charge,
      'skillChargeBars': skill?.chargeBars,
      'value': value,
      'isHero': isHero,
      'isBoss': isBoss,
      'aiType': aiType.name,
      'level': level,
      'xp': xp,
      'effects': effects.map((effect) => effect.toJson()).toList(),
    };
  }

  static Fighter fromJson(Map<String, dynamic> json) {
    final skillName = json['skillName'] as String?;
    final skill = skillName == null ? null : skillFactoryFromName(skillName);
    if (skill != null) {
      skill.charge = json['skillCharge'] as int? ?? skill.charge;
      skill.chargeBars = json['skillChargeBars'] as int? ?? skill.chargeBars;
      skill.charge = skill.charge.clamp(0, skill.maxCharge).toInt();
    }
    final fighter = Fighter(
      name: json['name'] as String? ?? 'Unknown',
      maxHp: (json['maxHp'] as num?)?.toDouble() ?? 1,
      attackPower: (json['attackPower'] as num?)?.toDouble() ?? 1,
      baseDefence: (json['baseDefence'] as num?)?.toDouble() ?? 0,
      skill: skill,
      value: json['value'] as int? ?? 0,
      isHero: json['isHero'] == true,
      isBoss: json['isBoss'] == true,
      aiType: AiType.values.firstWhere(
        (type) => type.name == json['aiType'],
        orElse: () => AiType.dumb,
      ),
    );
    fighter.hp = (json['hp'] as num?)?.toDouble() ?? fighter.maxHp;
    fighter.level = json['level'] as int? ?? 1;
    fighter.xp = json['xp'] as int? ?? 0;
    final effects = json['effects'] as List<dynamic>? ?? const [];
    fighter.effects.addAll(
      effects.whereType<Map<String, dynamic>>().map(StatusEffect.fromJson),
    );
    return fighter;
  }

  double takeDamage(double amount) {
    if (!isAlive || amount <= 0) return 0;
    final dealt = min(hp, amount);
    hp -= dealt;
    return dealt;
  }

  double heal(double amount) {
    if (!isAlive || amount <= 0) return 0;
    final healed = min(maxHp - hp, amount);
    hp += healed;
    return healed;
  }
}
