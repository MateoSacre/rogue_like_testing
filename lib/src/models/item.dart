import '../l10n/app_language.dart';
import 'enums.dart';

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
    required this.duration,
    this.damage = 0,
    this.atkRatio = 0,
    this.dotType = DotType.generic,
  });

  final String name;
  final double chance;
  final int duration;

  /// Flat per-tick damage, plus [atkRatio] × the attacker's ATK at proc time.
  final double damage;

  /// Fraction of the attacker's (buffed, item-boosted) ATK added to each tick.
  final double atkRatio;

  /// DoT family the inflicted effect belongs to (for resistance targeting).
  final DotType dotType;

  /// Per-tick DoT damage when proc'd by [attackerAttack] (its `attack` getter).
  double tickDamage(double attackerAttack) => damage + attackerAttack * atkRatio;
}

/// A resistance carried by a relic against one DoT [type]. [flatReduction] is
/// subtracted from each tick; [negateChance] (0..1) is rolled per effect per
/// tick to cancel that tick entirely (1.0 = full immunity).
class DotResist {
  const DotResist({
    required this.type,
    this.flatReduction = 0,
    this.negateChance = 0,
  });

  final DotType type;
  final double flatReduction;
  final double negateChance;
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
    this.critChanceBonus = 0,
    this.lifesteal = 0,
    this.onHit,
    this.dotResist,
    this.lifestealResist = 0,
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

  /// Added to the holder's critical-hit chance (0..1).
  final double critChanceBonus;

  /// Fraction (0..1) of damage dealt returned as healing.
  final double lifesteal;

  final ItemOnHit? onHit;

  /// DoT resistance granted to the holder, if any.
  final DotResist? dotResist;

  /// Fraction (0..1) by which this relic reduces an attacker's lifesteal when
  /// they hit the holder (grievous-wounds style).
  final double lifestealResist;

  bool get isRelic => slot == ItemSlot.relic;
}

/// A dropped item waiting for the player to pick its recipient (manual mode).
class PendingItemDrop {
  const PendingItemDrop(this.def);

  final ItemDef def;
}

/// Chance that at least one of several independent procs triggers
/// (1 − Π(1 − cᵢ)). Used to display the effective on-hit chance when a hero
/// holds several copies of the same relic.
double combinedProcChance(Iterable<double> chances) {
  var missAll = 1.0;
  for (final chance in chances) {
    missAll *= (1 - chance).clamp(0.0, 1.0);
  }
  return 1 - missAll;
}
