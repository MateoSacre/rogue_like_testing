import 'dart:math';

import '../game/game_balance.dart';
import '../models/creature_rarity.dart';
import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/item.dart';
import '../models/skill.dart';
import 'heroes.dart';
import 'mobs.dart';
import 'skills.dart';

/// Unified catalog of everything that can be summoned and played as a hero:
/// the six classic starters (3★) plus every bestiary mob (1★ → 4★ + 6★ bosses).
///
/// A summoned creature always enters the roster as a hero (it levels, gains XP
/// and persists in `PlayerProgress`); its base stats come from its rarity and
/// weights exactly like the enemy form. Display names live here (FR/EN), so
/// this catalog is the single source of truth for resolving any creature id —
/// including wave-spawned mobs — to its localized name.
class CreatureDef {
  const CreatureDef({
    required this.id,
    required this.name,
    required this.rarity,
    required this.buildBase,
    this.category,
    this.isStarter = false,
    this.summonable = true,
    this.portraitAsset,
  });

  /// Stable identity key — matches `Fighter.name`, the save/progress key and
  /// the combat-log token. Never localized.
  final String id;

  /// Localized display name (FR/EN).
  final LocalizedText name;

  final CreatureRarity rarity;

  /// Bestiary faction, or null for the classic heroes.
  final MobCategory? category;

  /// True for the six starters offered by the free first summon.
  final bool isStarter;

  /// Whether this creature can be obtained from the summon pool. Evolution-only
  /// forms are false (reachable only by evolving their base).
  final bool summonable;

  /// Optional portrait image asset path (e.g. `assets/creatures/slime.png`).
  /// No art is bundled yet, so this is null for every entry — tiles fall back
  /// to a placeholder. Set it per creature once art exists; nothing else
  /// needs to change.
  final String? portraitAsset;

  /// Builds a fresh level-1 hero form of this creature.
  final Fighter Function() buildBase;
}

/// Localized names for the six classic heroes, keyed by id.
const Map<String, LocalizedText> _heroDisplayNames = {
  'Paladin': LocalizedText('Paladin', 'Paladin'),
  'Warrior': LocalizedText('Guerrier', 'Warrior'),
  'Artificier': LocalizedText('Artificier', 'Artificer'),
  'Archer': LocalizedText('Archer', 'Archer'),
  'Priest': LocalizedText('Prêtre', 'Priest'),
  'Mage': LocalizedText('Mage', 'Mage'),
};

/// Localized names for every bestiary mob, keyed by id (English name).
const Map<String, LocalizedText> _mobDisplayNames = {
  'Slime': LocalizedText('Gluant', 'Slime'),
  'Dire Wolf': LocalizedText('Loup sinistre', 'Dire Wolf'),
  'Venommaw': LocalizedText('Gueule-venin', 'Venommaw'),
  'Bonehide': LocalizedText('Carcasse', 'Bonehide'),
  'World Ender': LocalizedText('Fin du Monde', 'World Ender'),
  'Cutpurse': LocalizedText('Coupe-bourse', 'Cutpurse'),
  'Highway Scout': LocalizedText('Éclaireur de route', 'Highway Scout'),
  'Assassin': LocalizedText('Assassin', 'Assassin'),
  'War Wagon': LocalizedText('Char de guerre', 'War Wagon'),
  'Tyrant of Knives': LocalizedText('Tyran des Lames', 'Tyrant of Knives'),
  'Initiate': LocalizedText('Initié', 'Initiate'),
  'Acolyte': LocalizedText('Acolyte', 'Acolyte'),
  'Plague Cantor': LocalizedText('Chantre de peste', 'Plague Cantor'),
  'Void Caller': LocalizedText('Invocateur du Vide', 'Void Caller'),
  'Apocalypse Choir': LocalizedText('Chœur de l\'Apocalypse', 'Apocalypse Choir'),
  'Spark Familiar': LocalizedText('Familier d\'étincelles', 'Spark Familiar'),
  'Rune Adept': LocalizedText('Adepte des runes', 'Rune Adept'),
  'Pyromancer': LocalizedText('Pyromancien', 'Pyromancer'),
  'Chrono Mage': LocalizedText('Chronomage', 'Chrono Mage'),
  'Cataclysm Sage': LocalizedText('Sage du Cataclysme', 'Cataclysm Sage'),
  'Recruit': LocalizedText('Recrue', 'Recruit'),
  'Legionnaire': LocalizedText('Légionnaire', 'Legionnaire'),
  'War Priest': LocalizedText('Prêtre de guerre', 'War Priest'),
  'Siege Engineer': LocalizedText('Ingénieur de siège', 'Siege Engineer'),
  'Emperor Wrath': LocalizedText('Courroux de l\'Empereur', 'Emperor Wrath'),
  'Wisp': LocalizedText('Feu follet', 'Wisp'),
  'Haunter': LocalizedText('Spectre', 'Haunter'),
  'Crypt Lord': LocalizedText('Seigneur des cryptes', 'Crypt Lord'),
  'Soul Reaper': LocalizedText('Faucheur d\'âmes', 'Soul Reaper'),
  'Lich King': LocalizedText('Roi-Liche', 'Lich King'),
  'Pebbleling': LocalizedText('Caillouton', 'Pebbleling'),
  'Young Giant': LocalizedText('Jeune géant', 'Young Giant'),
  'Stone Giant': LocalizedText('Géant de pierre', 'Stone Giant'),
  'Storm Giant': LocalizedText('Géant des tempêtes', 'Storm Giant'),
  'Ancient Titan': LocalizedText('Titan ancien', 'Ancient Titan'),
  // Evolution forms (mob lines).
  'Gros Slime': LocalizedText('Gros Slime', 'Big Slime'),
  'Roi Slime': LocalizedText('Roi Slime', 'Slime King'),
  'Brigand': LocalizedText('Brigand', 'Brigand'),
  'Bandit Chief': LocalizedText('Chef de bande', 'Bandit Chief'),
  'Zealot': LocalizedText('Fanatique', 'Zealot'),
  'High Zealot': LocalizedText('Grand Fanatique', 'High Zealot'),
  'Flame Familiar': LocalizedText('Familier de flammes', 'Flame Familiar'),
  'Inferno Familiar': LocalizedText('Familier d\'inferno', 'Inferno Familiar'),
  'Soldier': LocalizedText('Soldat', 'Soldier'),
  'Veteran': LocalizedText('Vétéran', 'Veteran'),
  'Shade': LocalizedText('Ombre', 'Shade'),
  'Wraith': LocalizedText('Apparition', 'Wraith'),
  'Boulderkin': LocalizedText('Rocaille', 'Boulderkin'),
  'Rockfist': LocalizedText('Poing-de-roche', 'Rockfist'),
};

/// Title-escalation evolution forms of the six starters (4★ then 5★). Hero-only
/// (never spawn in waves), not summonable, reachable only by evolving.
class _HeroEvoSpec {
  const _HeroEvoSpec(
    this.id,
    this.name,
    this.rarity,
    this.weights,
    this.buildSkill,
  );

  final String id;
  final LocalizedText name;
  final CreatureRarity rarity;
  final StatWeights weights;
  final Skill Function() buildSkill;
}

final List<_HeroEvoSpec> _heroEvolutions = [
  _HeroEvoSpec('Crusader', const LocalizedText('Croisé', 'Crusader'),
      CreatureRarity.epic, CreatureRole.tank, protectSkill),
  _HeroEvoSpec('Holy Champion',
      const LocalizedText('Champion sacré', 'Holy Champion'),
      CreatureRarity.legendary, CreatureRole.tank, protectSkill),
  _HeroEvoSpec('Berserker', const LocalizedText('Berserker', 'Berserker'),
      CreatureRarity.epic, CreatureRole.bruiser, deepCutSkill),
  _HeroEvoSpec('Warlord', const LocalizedText('Seigneur de guerre', 'Warlord'),
      CreatureRarity.legendary, CreatureRole.bruiser, deepCutSkill),
  _HeroEvoSpec('Master Engineer',
      const LocalizedText('Ingénieur d\'élite', 'Master Engineer'),
      CreatureRarity.epic, CreatureRole.caster, nukeSkill),
  _HeroEvoSpec('Arch-Machinist',
      const LocalizedText('Maître mécaniste', 'Arch-Machinist'),
      CreatureRarity.legendary, CreatureRole.caster, nukeSkill),
  _HeroEvoSpec('Marksman', const LocalizedText('Franc-tireur', 'Marksman'),
      CreatureRarity.epic, CreatureRole.skirmisher, poisonArrowSkill),
  _HeroEvoSpec('Hawkeye', const LocalizedText('Œil-de-faucon', 'Hawkeye'),
      CreatureRarity.legendary, CreatureRole.skirmisher, poisonArrowSkill),
  _HeroEvoSpec('Bishop', const LocalizedText('Évêque', 'Bishop'),
      CreatureRarity.epic, CreatureRole.support, magicHealingSkill),
  _HeroEvoSpec('High Priest', const LocalizedText('Grand prêtre', 'High Priest'),
      CreatureRarity.legendary, CreatureRole.support, magicHealingSkill),
  _HeroEvoSpec('Archmage', const LocalizedText('Archimage', 'Archmage'),
      CreatureRarity.epic, CreatureRole.caster, tripleBeamSkill),
  _HeroEvoSpec('Grand Archmage',
      const LocalizedText('Archimage suprême', 'Grand Archmage'),
      CreatureRarity.legendary, CreatureRole.caster, tripleBeamSkill),
];

/// Evolution chains: each id maps to the next, stronger form (one rarity tier
/// up). Terminal forms are absent from the map. Mob lines (1★→2★→3★) and
/// starter title lines (3★→4★→5★).
const Map<String, String> _evolutionChains = {
  // Mob lines.
  'Slime': 'Gros Slime', 'Gros Slime': 'Roi Slime',
  'Cutpurse': 'Brigand', 'Brigand': 'Bandit Chief',
  'Initiate': 'Zealot', 'Zealot': 'High Zealot',
  'Spark Familiar': 'Flame Familiar', 'Flame Familiar': 'Inferno Familiar',
  'Recruit': 'Soldier', 'Soldier': 'Veteran',
  'Wisp': 'Shade', 'Shade': 'Wraith',
  'Pebbleling': 'Boulderkin', 'Boulderkin': 'Rockfist',
  // Starter title lines.
  'Paladin': 'Crusader', 'Crusader': 'Holy Champion',
  'Warrior': 'Berserker', 'Berserker': 'Warlord',
  'Artificier': 'Master Engineer', 'Master Engineer': 'Arch-Machinist',
  'Archer': 'Marksman', 'Marksman': 'Hawkeye',
  'Priest': 'Bishop', 'Bishop': 'High Priest',
  'Mage': 'Archmage', 'Archmage': 'Grand Archmage',
};

/// Turns a bestiary mob into its summoned hero form: same derived stats, skill
/// and rarity, but flagged as a hero with no enemy-only traits (boss flag,
/// kill value, AI).
Fighter _mobHeroBase(String id) {
  final template = mobRoster.firstWhere((m) => m.name == id);
  final fighter = template.build(template.name, Random())
    ..isHero = true
    ..isBoss = false
    ..value = 0
    ..aiType = AiType.dumb;
  return fighter;
}

Fighter _starterHeroBase(String id) =>
    buildBaseTeam().firstWhere((hero) => hero.name == id);

final Map<String, _HeroEvoSpec> _heroEvoById = {
  for (final spec in _heroEvolutions) spec.id: spec,
};

/// Builds a starter-evolution hero form from its [_HeroEvoSpec].
Fighter _evoHeroBase(String id) {
  final spec = _heroEvoById[id]!;
  return Fighter(
    name: id,
    maxHp: GameBalance.creatureHp(spec.rarity, spec.weights),
    attackPower: GameBalance.creatureAttack(spec.rarity, spec.weights),
    baseDefence: GameBalance.creatureDefence(spec.rarity, spec.weights),
    skill: spec.buildSkill(),
    isHero: true,
    rarity: spec.rarity,
  );
}

List<CreatureDef> _buildCatalog() {
  final catalog = <CreatureDef>[];

  // Starters first, in roster order, so team building keeps the classic order.
  for (final hero in buildBaseTeam()) {
    final id = hero.name;
    catalog.add(
      CreatureDef(
        id: id,
        name: _heroDisplayNames[id] ?? LocalizedText(id, id),
        rarity: hero.rarity ?? CreatureRarity.rare,
        isStarter: true,
        buildBase: () => _starterHeroBase(id),
      ),
    );
  }

  for (final template in mobRoster) {
    final id = template.name;
    catalog.add(
      CreatureDef(
        id: id,
        name: _mobDisplayNames[id] ?? LocalizedText(id, id),
        rarity: template.rarity,
        category: template.category,
        summonable: template.summonable,
        buildBase: () => _mobHeroBase(id),
      ),
    );
  }

  // Starter title-escalation forms (hero-only, evolution-reachable, never
  // summoned or spawned in waves).
  for (final spec in _heroEvolutions) {
    catalog.add(
      CreatureDef(
        id: spec.id,
        name: spec.name,
        rarity: spec.rarity,
        summonable: false,
        buildBase: () => _evoHeroBase(spec.id),
      ),
    );
  }

  return catalog;
}

/// Every summonable creature (starters + bestiary), starters first.
final List<CreatureDef> creatureCatalog = _buildCatalog();

final Map<String, CreatureDef> _catalogById = {
  for (final def in creatureCatalog) def.id: def,
};

/// Catalog entry for [id], or null if unknown (e.g. an ad-hoc test fighter).
CreatureDef? creatureById(String id) => _catalogById[id];

/// The six starters offered by the free first summon.
List<CreatureDef> get starterCreatures =>
    creatureCatalog.where((c) => c.isStarter).toList();

/// All creatures of a given rarity (summonable or not — includes evolution
/// forms). Use [summonableByRarity] for the actual summon pool.
List<CreatureDef> creaturesByRarity(CreatureRarity rarity) =>
    creatureCatalog.where((c) => c.rarity == rarity).toList();

/// Summon pool for a given rarity (excludes evolution-only forms).
List<CreatureDef> summonableByRarity(CreatureRarity rarity) =>
    creatureCatalog.where((c) => c.summonable && c.rarity == rarity).toList();

/// Catalog id of the creature [id] evolves into, or null if it is a terminal
/// form (or unknown).
String? evolutionTargetId(String id) => _evolutionChains[id];

/// Builds a run team from the player's selection and persisted progress,
/// resolving each selected id through the unified catalog (so summoned mobs
/// play exactly like classic heroes). Catalog order is preserved.
List<Fighter> buildTeamFromProgress({
  required Iterable<String> selectedHeroNames,
  required int Function(String heroName) levelFor,
  required int Function(String heroName) xpFor,
}) {
  final selected = selectedHeroNames.toSet();
  return creatureCatalog
      .where((c) => selected.contains(c.id))
      .map((c) => heroAtLevel(c.buildBase(), levelFor(c.id), xp: xpFor(c.id)))
      .toList();
}
