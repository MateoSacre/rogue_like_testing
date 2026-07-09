import 'dart:math';

import '../data/items.dart';
import '../data/skills.dart';
import '../game/game_balance.dart';
import 'creature_rarity.dart';
import 'enums.dart';
import 'item.dart';
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
    this.rarity,
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

  /// Rarity tier of the underlying creature, if known (mobs and summonable
  /// heroes). May be null for ad-hoc fighters built directly in tests.
  CreatureRarity? rarity;
  AiType aiType;
  int level = 1;
  int xp = 0;
  final List<StatusEffect> effects = [];

  /// Equipped items, one per slot (helmet/gloves/chest/weapon). Their stat
  /// bonuses are baked into the fighter's stats at equip time; the ids are
  /// kept for display, replacement math and dynamic effects.
  final Map<ItemSlot, String> equipment = {};

  /// Stackable relic item ids (including boss items).
  final List<String> relics = [];

  bool get isAlive => hp > 0;

  int get itemCount => equipment.length + relics.length;

  /// Definitions of everything currently held (equipment + relics).
  Iterable<ItemDef> get heldItems sync* {
    for (final id in equipment.values) {
      final def = itemById(id);
      if (def != null) yield def;
    }
    for (final id in relics) {
      final def = itemById(id);
      if (def != null) yield def;
    }
  }

  /// Chance (0..1) to strike a second time, summed over held items.
  double get extraAttackChance {
    final total = heldItems.fold<double>(
      0,
      (sum, item) => sum + item.extraAttackChance,
    );
    return min(total, GameBalance.extraAttackChanceCap);
  }

  /// Fraction of dealt damage returned as healing, summed over held items.
  double get lifesteal =>
      heldItems.fold<double>(0, (sum, item) => sum + item.lifesteal);

  /// Fraction (0..1) by which this fighter reduces an attacker's lifesteal.
  double get lifestealResist => heldItems
      .fold<double>(0, (sum, item) => sum + item.lifestealResist)
      .clamp(0.0, 1.0);

  /// True if a held resist matches DoT [type] (its own type, or [generic]).
  Iterable<DotResist> _resistsFor(DotType type) => heldItems
      .map((item) => item.dotResist)
      .whereType<DotResist>()
      .where((r) => r.type == type || r.type == DotType.generic);

  /// Flat damage removed from each tick of a [type] DoT (summed over items).
  double dotFlatReduction(DotType type) =>
      _resistsFor(type).fold<double>(0, (sum, r) => sum + r.flatReduction);

  /// Combined chance (0..1) to negate a single [type] DoT tick.
  double dotNegateChance(DotType type) =>
      combinedProcChance(_resistsFor(type).map((r) => r.negateChance));

  /// All on-hit effects carried by held items.
  Iterable<ItemOnHit> get onHitEffects =>
      heldItems.map((item) => item.onHit).whereType<ItemOnHit>();

  double get defence => baseDefence + _buffSum((effect) => effect.defenceBonus);

  /// Attack power including temporary buff effects (used for all damage).
  double get attack => attackPower + _buffSum((effect) => effect.attackBonus);

  /// Critical-hit chance (0..1): base rate, plus item and buff bonuses.
  double get critChance {
    final itemBonus = heldItems.fold<double>(
      0,
      (sum, item) => sum + item.critChanceBonus,
    );
    final total =
        GameBalance.baseCritChance +
        itemBonus +
        _buffSum((effect) => effect.critChanceBonus);
    return total.clamp(0.0, 1.0);
  }

  double _buffSum(double Function(StatusEffect effect) selector) {
    return effects
        .where((effect) => effect.kind == EffectKind.buff)
        .fold<double>(0, (sum, effect) => sum + selector(effect));
  }

  String get statusLabel {
    if (effects.isEmpty) return '';
    return effects
        .map((effect) => '${effect.name} ${effect.duration}')
        .join(' | ');
  }

  /// XP required to advance from the current level to the next.
  int get xpCap => GameBalance.xpForLevel(level);

  Fighter copy({String? renamed}) {
    Fighter newFighter = Fighter(
      name: renamed ?? name,
      maxHp: maxHp,
      attackPower: attackPower,
      baseDefence: baseDefence,
      skill: skill == null ? null : skillFactoryFrom(skill!),
      value: value,
      isHero: isHero,
      isBoss: isBoss,
      rarity: rarity,
      aiType: aiType,
    );
    if (isHero) {
      newFighter.xp = xp;
      newFighter.level = level;
    }
    newFighter.equipment.addAll(equipment);
    newFighter.relics.addAll(relics);
    return newFighter;
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
      'rarity': rarity?.name,
      'aiType': aiType.name,
      'level': level,
      'xp': xp,
      'effects': effects.map((effect) => effect.toJson()).toList(),
      'equipment': equipment.map((slot, id) => MapEntry(slot.name, id)),
      'relics': relics,
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
      rarity: _rarityFromName(json['rarity'] as String?),
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
    // Stat bonuses are already baked into the saved stats; only restore ids.
    final equipment = json['equipment'] as Map<String, dynamic>? ?? const {};
    for (final entry in equipment.entries) {
      final slot = ItemSlot.values.firstWhere(
        (slot) => slot.name == entry.key,
        orElse: () => ItemSlot.relic,
      );
      final id = entry.value as String?;
      if (slot != ItemSlot.relic && id != null && itemById(id) != null) {
        fighter.equipment[slot] = id;
      }
    }
    fighter.relics.addAll(
      (json['relics'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .where((id) => itemById(id) != null),
    );
    return fighter;
  }

  static CreatureRarity? _rarityFromName(String? name) {
    if (name == null) return null;
    for (final rarity in CreatureRarity.values) {
      if (rarity.name == name) return rarity;
    }
    return null;
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
