import '../l10n/app_language.dart';

/// Rarity tiers, Risk of Rain 2 style. Drives drop weights, sell value and
/// display color. [boss] items only drop from category bosses.
enum ItemRarity { common, uncommon, legendary, boss }

/// Where an item sits on a hero. The four equipment slots hold at most one
/// item each (replacing sells the old one); relics stack without limit.
enum ItemSlot { helmet, gloves, chest, weapon, relic }

/// A small FR/EN text pair for item names and descriptions.
/// Items are content, so their strings live with their definition instead of
/// the global K dictionary.
class LocalizedText {
  const LocalizedText(this.fr, this.en);

  final String fr;
  final String en;

  String of(AppLanguage language) => language == AppLanguage.fr ? fr : en;
}

/// Chance-based effect applied to the target when the holder lands a hit.
/// [name] doubles as the status-effect name (and dedup key on the target).
class ItemOnHit {
  const ItemOnHit({
    required this.name,
    required this.chance,
    required this.damage,
    required this.duration,
  });

  final String name;
  final double chance;
  final double damage;
  final int duration;
}

/// Immutable definition of a droppable item. Stat bonuses (hp/atk/def) are
/// baked into the hero's stats when equipped; [extraAttackChance], [lifesteal]
/// and [onHit] are evaluated dynamically during combat.
class ItemDef {
  const ItemDef({
    required this.id,
    required this.slot,
    required this.rarity,
    required this.name,
    required this.description,
    this.hpBonus = 0,
    this.atkBonus = 0,
    this.defBonus = 0,
    this.extraAttackChance = 0,
    this.lifesteal = 0,
    this.onHit,
  });

  final String id;
  final ItemSlot slot;
  final ItemRarity rarity;
  final LocalizedText name;
  final LocalizedText description;
  final double hpBonus;
  final double atkBonus;
  final double defBonus;

  /// Chance (0..1) to immediately strike a second time after a basic attack.
  final double extraAttackChance;

  /// Fraction (0..1) of damage dealt returned as healing.
  final double lifesteal;

  final ItemOnHit? onHit;

  bool get isRelic => slot == ItemSlot.relic;
}

/// A dropped item waiting for the player to pick its recipient (manual mode).
class PendingItemDrop {
  const PendingItemDrop(this.def);

  final ItemDef def;
}
