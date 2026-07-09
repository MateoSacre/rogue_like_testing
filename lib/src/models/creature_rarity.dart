/// Creature rarity, expressed in stars (1★ … 6★). A creature's rarity is
/// **fixed** (assigned, not rolled) and drives its stat budget, its summon
/// drop weight, its sell/reward [value] and its display colour.
///
/// Bosses are always [mythic]. The six classic heroes are [rare] (3★).
enum CreatureRarity {
  common(1),
  uncommon(2),
  rare(3),
  epic(4),
  legendary(5),
  mythic(6);

  const CreatureRarity(this.stars);

  /// 1..6 — also the display star count.
  final int stars;

  /// Looks a rarity up by its star count (1..6), clamped to the valid range.
  static CreatureRarity fromStars(int stars) {
    final clamped = stars.clamp(1, 6);
    return CreatureRarity.values[clamped - 1];
  }
}

/// Per-creature stat weights, multiplied onto the rarity stat anchors to keep
/// each creature's identity (a tank leans HP/DEF, a caster leans ATK). Weights
/// nominally average ~1 so that **rarity** stays the dominant power lever; the
/// presets in [CreatureRole] follow that convention.
class StatWeights {
  const StatWeights({this.hp = 1, this.atk = 1, this.def = 1});

  final double hp;
  final double atk;
  final double def;
}

/// Named [StatWeights] presets describing combat archetypes. Tune identities
/// here; tune the overall power curve via the rarity anchors in `GameBalance`.
class CreatureRole {
  const CreatureRole._();

  /// Even spread — no particular lean.
  static const balanced = StatWeights();

  /// High ATK with solid HP, light armour (Warrior, Dire Wolf, young giants).
  static const bruiser = StatWeights(hp: 1.0, atk: 1.25, def: 0.85);

  /// Wall: lots of HP/DEF, weak offence (Paladin, Bonehide, Stone Giant).
  static const tank = StatWeights(hp: 1.45, atk: 0.55, def: 1.55);

  /// Fragile striker: high ATK, low HP/DEF (Assassin, Archer, Cutpurse).
  static const skirmisher = StatWeights(hp: 0.85, atk: 1.35, def: 0.75);

  /// Glass cannon: top ATK, very low survivability (Mage, Artificier, mages).
  static const caster = StatWeights(hp: 0.8, atk: 1.4, def: 0.7);

  /// Backline support: tanky-ish, low ATK (Priest, Acolyte, healers).
  static const support = StatWeights(hp: 1.15, atk: 0.7, def: 1.0);
}
