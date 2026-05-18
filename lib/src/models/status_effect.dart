import 'enums.dart';

class StatusEffect {
  StatusEffect({
    required this.name,
    required this.kind,
    required this.duration,
    this.damage = 0,
    this.defenceBonus = 0,
  });

  final String name;
  final EffectKind kind;
  int duration;
  final double damage;
  final double defenceBonus;

  StatusEffect copy() {
    return StatusEffect(
      name: name,
      kind: kind,
      duration: duration,
      damage: damage,
      defenceBonus: defenceBonus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'kind': kind.name,
      'duration': duration,
      'damage': damage,
      'defenceBonus': defenceBonus,
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
    );
  }
}
