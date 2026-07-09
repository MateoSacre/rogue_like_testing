import '../models/enums.dart';
import '../models/item.dart';

/// Item catalog.
///
/// Standard pool: 5 items (3 armor pieces, 1 weapon, 1 relic) per rarity tier.
/// Boss items: one stackable relic per mob category, themed on that boss,
/// dropped only when its boss dies.
final List<ItemDef> itemCatalog = [
  // ── Common (white) ────────────────────────────────────────────────────────
  const ItemDef(
    id: 'chest_common',
    slot: ItemSlot.chest,
    rarity: ItemRarity.common,
    name: LocalizedText('Plastron usé', 'Worn Breastplate'),
    description: LocalizedText('+6 PV max', '+6 max HP'),
    hpBonus: 6,
  ),
  const ItemDef(
    id: 'gloves_common',
    slot: ItemSlot.gloves,
    rarity: ItemRarity.common,
    name: LocalizedText('Gants de cuir', 'Leather Gloves'),
    description: LocalizedText('+2 ATK', '+2 ATK'),
    atkBonus: 2,
  ),
  const ItemDef(
    id: 'helmet_common',
    slot: ItemSlot.helmet,
    rarity: ItemRarity.common,
    name: LocalizedText('Casque rouillé', 'Rusty Helm'),
    description: LocalizedText('+2 DEF', '+2 DEF'),
    defBonus: 2,
  ),
  const ItemDef(
    id: 'weapon_common',
    slot: ItemSlot.weapon,
    rarity: ItemRarity.common,
    name: LocalizedText('Dague rapide', 'Swift Dagger'),
    description: LocalizedText(
      '+1 ATK, 10% de double frappe',
      '+1 ATK, 10% double strike',
    ),
    atkBonus: 1,
    extraAttackChance: .10,
  ),
  const ItemDef(
    id: 'relic_fang',
    slot: ItemSlot.relic,
    rarity: ItemRarity.common,
    name: LocalizedText('Croc de loup', 'Wolf Fang'),
    description: LocalizedText(
      '25% de saignement à l\'attaque (10% ATK/tour, 3 tours)',
      '25% bleed on hit (10% ATK/turn, 3 turns)',
    ),
    onHit: ItemOnHit(
      name: 'Bleed',
      chance: .25,
      atkRatio: .10,
      duration: 3,
      dotType: DotType.bleed,
    ),
  ),

  // ── Uncommon (green) ──────────────────────────────────────────────────────
  const ItemDef(
    id: 'chest_uncommon',
    slot: ItemSlot.chest,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Cuirasse renforcée', 'Reinforced Cuirass'),
    description: LocalizedText('+15 PV max', '+15 max HP'),
    hpBonus: 15,
  ),
  const ItemDef(
    id: 'gloves_uncommon',
    slot: ItemSlot.gloves,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Poings cloutés', 'Studded Fists'),
    description: LocalizedText('+5 ATK', '+5 ATK'),
    atkBonus: 5,
  ),
  const ItemDef(
    id: 'helmet_uncommon',
    slot: ItemSlot.helmet,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Heaume d\'acier', 'Steel Helm'),
    description: LocalizedText('+5 DEF', '+5 DEF'),
    defBonus: 5,
  ),
  const ItemDef(
    id: 'weapon_uncommon',
    slot: ItemSlot.weapon,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Lames jumelles', 'Twin Blades'),
    description: LocalizedText(
      '+3 ATK, 20% de double frappe',
      '+3 ATK, 20% double strike',
    ),
    atkBonus: 3,
    extraAttackChance: .20,
  ),
  const ItemDef(
    id: 'relic_venom',
    slot: ItemSlot.relic,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Fiole de venin', 'Venom Vial'),
    description: LocalizedText(
      '30% de poison à l\'attaque (12% ATK/tour, 4 tours)',
      '30% poison on hit (12% ATK/turn, 4 turns)',
    ),
    onHit: ItemOnHit(
      name: 'Poison',
      chance: .30,
      atkRatio: .12,
      duration: 4,
      dotType: DotType.poison,
    ),
  ),

  // ── Legendary (red) ───────────────────────────────────────────────────────
  const ItemDef(
    id: 'chest_legendary',
    slot: ItemSlot.chest,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Armure du colosse', 'Colossus Plate'),
    description: LocalizedText('+35 PV max', '+35 max HP'),
    hpBonus: 35,
  ),
  const ItemDef(
    id: 'gloves_legendary',
    slot: ItemSlot.gloves,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Poigne du berserker', 'Berserker Grip'),
    description: LocalizedText('+11 ATK', '+11 ATK'),
    atkBonus: 11,
  ),
  const ItemDef(
    id: 'helmet_legendary',
    slot: ItemSlot.helmet,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Couronne de garde', 'Warden Crown'),
    description: LocalizedText('+11 DEF', '+11 DEF'),
    defBonus: 11,
  ),
  const ItemDef(
    id: 'weapon_legendary',
    slot: ItemSlot.weapon,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Fauchard du chaos', 'Chaos Glaive'),
    description: LocalizedText(
      '+6 ATK, 40% de double frappe',
      '+6 ATK, 40% double strike',
    ),
    atkBonus: 6,
    extraAttackChance: .40,
  ),
  const ItemDef(
    id: 'relic_vampire',
    slot: ItemSlot.relic,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Cœur vampirique', 'Vampiric Heart'),
    description: LocalizedText(
      'Soigne 20% des dégâts infligés',
      'Heals for 20% of damage dealt',
    ),
    lifesteal: .20,
  ),

  // ── Resistance & crit relics (dilute the powerful-relic pool) ─────────────
  // Common: flat DoT reduction (strong early, fades late) and a small crit bump.
  const ItemDef(
    id: 'relic_poison_ward',
    slot: ItemSlot.relic,
    rarity: ItemRarity.common,
    name: LocalizedText('Amulette anti-venin', 'Antivenom Charm'),
    description: LocalizedText(
      '-4 dégâts de poison par tour',
      '-4 poison damage per turn',
    ),
    dotResist: DotResist(type: DotType.poison, flatReduction: 4),
  ),
  const ItemDef(
    id: 'relic_bleed_ward',
    slot: ItemSlot.relic,
    rarity: ItemRarity.common,
    name: LocalizedText('Bandages', 'Bandages'),
    description: LocalizedText(
      '-4 dégâts de saignement par tour',
      '-4 bleed damage per turn',
    ),
    dotResist: DotResist(type: DotType.bleed, flatReduction: 4),
  ),
  const ItemDef(
    id: 'relic_crit_minor',
    slot: ItemSlot.relic,
    rarity: ItemRarity.common,
    name: LocalizedText('Œil affûté', 'Keen Eye'),
    description: LocalizedText('+3% de chance critique', '+3% crit chance'),
    critChanceBonus: .03,
  ),

  // Uncommon: a chance to negate DoT ticks, partial grievous wounds, more crit.
  const ItemDef(
    id: 'relic_poison_guard',
    slot: ItemSlot.relic,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Sérum purificateur', 'Cleansing Serum'),
    description: LocalizedText(
      '30% d\'annuler chaque dégât de poison',
      '30% to negate each poison tick',
    ),
    dotResist: DotResist(type: DotType.poison, negateChance: .30),
  ),
  const ItemDef(
    id: 'relic_bleed_guard',
    slot: ItemSlot.relic,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Garrot runique', 'Runic Tourniquet'),
    description: LocalizedText(
      '30% d\'annuler chaque dégât de saignement',
      '30% to negate each bleed tick',
    ),
    dotResist: DotResist(type: DotType.bleed, negateChance: .30),
  ),
  const ItemDef(
    id: 'relic_grievous',
    slot: ItemSlot.relic,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Sceau de plaies', 'Grievous Seal'),
    description: LocalizedText(
      'Réduit de 50% le vol de vie des attaquants',
      'Reduces attackers\' lifesteal by 50%',
    ),
    lifestealResist: .50,
  ),
  const ItemDef(
    id: 'relic_crit',
    slot: ItemSlot.relic,
    rarity: ItemRarity.uncommon,
    name: LocalizedText('Lentille de précision', 'Precision Lens'),
    description: LocalizedText('+8% de chance critique', '+8% crit chance'),
    critChanceBonus: .08,
  ),

  // Legendary: full DoT immunity, full grievous wounds, big crit.
  const ItemDef(
    id: 'relic_poison_immunity',
    slot: ItemSlot.relic,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Cœur d\'antidote', 'Antidote Core'),
    description: LocalizedText('Immunité au poison', 'Immune to poison'),
    dotResist: DotResist(type: DotType.poison, negateChance: 1),
  ),
  const ItemDef(
    id: 'relic_bleed_immunity',
    slot: ItemSlot.relic,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Peau de fer', 'Ironskin'),
    description: LocalizedText('Immunité au saignement', 'Immune to bleed'),
    dotResist: DotResist(type: DotType.bleed, negateChance: 1),
  ),
  const ItemDef(
    id: 'relic_null_lifesteal',
    slot: ItemSlot.relic,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Stigmate mortel', 'Mortal Stigma'),
    description: LocalizedText(
      'Annule totalement le vol de vie des attaquants',
      'Fully negates attackers\' lifesteal',
    ),
    lifestealResist: 1,
  ),
  const ItemDef(
    id: 'relic_crit_major',
    slot: ItemSlot.relic,
    rarity: ItemRarity.legendary,
    name: LocalizedText('Couronne du bourreau', 'Executioner Crown'),
    description: LocalizedText('+18% de chance critique', '+18% crit chance'),
    critChanceBonus: .18,
  ),

  // ── Boss items (yellow) — one per category, themed on its boss ────────────
  const ItemDef(
    id: 'boss_monsters',
    slot: ItemSlot.relic,
    rarity: ItemRarity.boss,
    name: LocalizedText('Croc du Fossoyeur de mondes', 'World Ender\'s Fang'),
    description: LocalizedText(
      '+6 ATK, 35% de poison à l\'attaque (18% ATK/tour, 4 tours)',
      '+6 ATK, 35% poison on hit (18% ATK/turn, 4 turns)',
    ),
    atkBonus: 6,
    onHit: ItemOnHit(
      name: 'Poison',
      chance: .35,
      atkRatio: .18,
      duration: 4,
      dotType: DotType.poison,
    ),
  ),
  const ItemDef(
    id: 'boss_bandits',
    slot: ItemSlot.relic,
    rarity: ItemRarity.boss,
    name: LocalizedText('Lame du Tyran', 'Tyrant\'s Blade'),
    description: LocalizedText(
      '+20% de double frappe, 25% de saignement (15% ATK/tour, 3 tours)',
      '+20% double strike, 25% bleed (15% ATK/turn, 3 turns)',
    ),
    extraAttackChance: .20,
    onHit: ItemOnHit(
      name: 'Bleed',
      chance: .25,
      atkRatio: .15,
      duration: 3,
      dotType: DotType.bleed,
    ),
  ),
  const ItemDef(
    id: 'boss_cultists',
    slot: ItemSlot.relic,
    rarity: ItemRarity.boss,
    name: LocalizedText('Hymne virulent', 'Virulent Hymn'),
    description: LocalizedText(
      '50% de poison à l\'attaque (22% ATK/tour, 5 tours)',
      '50% poison on hit (22% ATK/turn, 5 turns)',
    ),
    onHit: ItemOnHit(
      name: 'Poison',
      chance: .50,
      atkRatio: .22,
      duration: 5,
      dotType: DotType.poison,
    ),
  ),
  const ItemDef(
    id: 'boss_mages',
    slot: ItemSlot.relic,
    rarity: ItemRarity.boss,
    name: LocalizedText('Cendres du Cataclysme', 'Cataclysm Ash'),
    description: LocalizedText(
      '35% de brûlure à l\'attaque (20% ATK/tour, 3 tours)',
      '35% burn on hit (20% ATK/turn, 3 turns)',
    ),
    onHit: ItemOnHit(
      name: 'Burn',
      chance: .35,
      atkRatio: .20,
      duration: 3,
      dotType: DotType.burn,
    ),
  ),
  const ItemDef(
    id: 'boss_empire',
    slot: ItemSlot.relic,
    rarity: ItemRarity.boss,
    name: LocalizedText('Égide impériale', 'Imperial Aegis'),
    description: LocalizedText('+8 DEF, +15 PV max', '+8 DEF, +15 max HP'),
    defBonus: 8,
    hpBonus: 15,
  ),
  const ItemDef(
    id: 'boss_ghosts',
    slot: ItemSlot.relic,
    rarity: ItemRarity.boss,
    name: LocalizedText('Couronne du Roi-liche', 'Lich King\'s Crown'),
    description: LocalizedText(
      'Soigne 30% des dégâts infligés',
      'Heals for 30% of damage dealt',
    ),
    lifesteal: .30,
  ),
  const ItemDef(
    id: 'boss_giants',
    slot: ItemSlot.relic,
    rarity: ItemRarity.boss,
    name: LocalizedText('Cœur de titan', 'Titan Heart'),
    description: LocalizedText('+30 PV max, +6 DEF', '+30 max HP, +6 DEF'),
    hpBonus: 30,
    defBonus: 6,
  ),
];

final Map<String, ItemDef> _itemsById = {
  for (final item in itemCatalog) item.id: item,
};

ItemDef? itemById(String id) => _itemsById[id];

/// Standard drop pool for a rarity (boss items excluded).
List<ItemDef> itemsOfRarity(ItemRarity rarity) {
  return itemCatalog
      .where((item) => item.rarity == rarity && rarity != ItemRarity.boss)
      .toList();
}

/// The unique boss item for a mob category.
ItemDef? bossItemFor(MobCategory category) => itemById('boss_${category.name}');

int itemSellValue(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => 25,
    ItemRarity.uncommon => 60,
    ItemRarity.legendary => 150,
    ItemRarity.boss => 250,
  };
}
