import 'enums.dart';

class StatusEffect {
  StatusEffect({
    required this.name,
    required this.kind,
    required this.duration,
    this.damage = 0,
    this.defenceBonus = 0,
    this.attackBonus = 0,
    this.critChanceBonus = 0,
    this.dotType = DotType.generic,
  });

  final String name;
  final EffectKind kind;
  int duration;
  final double damage;

  /// DoT family of a recurrent effect, for resistance targeting.
  final DotType dotType;

  /// Buff effects: flat bonuses while active.
  final double defenceBonus;
  final double attackBonus;

  /// Added to the holder's critical-hit chance (0..1) while active.
  final double critChanceBonus;

  StatusEffect copy() {
    return StatusEffect(
      name: name,
      kind: kind,
      duration: duration,
      damage: damage,
      defenceBonus: defenceBonus,
      attackBonus: attackBonus,
      critChanceBonus: critChanceBonus,
      dotType: dotType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'kind': kind.name,
      'duration': duration,
      'damage': damage,
      'defenceBonus': defenceBonus,
      'attackBonus': attackBonus,
      'critChanceBonus': critChanceBonus,
      'dotType': dotType.name,
    };
  }

  static StatusEffect fromJson(Map<String, dynamic> json) {
    return StatusEffect(
      name: json['name'] as String? ?? 'Effect',
      kind: EffectKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => EffectKind.recurrent,
      ),
      duration: json['duration'] as int? ?? 0,
      damage: (json['damage'] as num?)?.toDouble() ?? 0,
      defenceBonus: (json['defenceBonus'] as num?)?.toDouble() ?? 0,
      attackBonus: (json['attackBonus'] as num?)?.toDouble() ?? 0,
      critChanceBonus: (json['critChanceBonus'] as num?)?.toDouble() ?? 0,
      dotType: DotType.values.firstWhere(
        (type) => type.name == json['dotType'],
        orElse: () => DotType.generic,
      ),
    );
  }
}
