import 'package:flutter/widgets.dart';

import '../models/enums.dart';
import '../models/item.dart';
import '../settings/game_settings.dart';
import 'app_language.dart';

/// Translation keys. Every visible UI string maps to one of these.
///
/// Strings can contain positional placeholders `{0}`, `{1}`, ... which are
/// filled by the arguments passed to [AppLocalizations.t] / `context.tr`.
///
/// Out of scope on purpose (kept as data, not translated): hero/skill names
/// and skill descriptions (data layer), dev-only effect presets, and the
/// combat log (not rendered).
enum K {
  // App / shared
  appTitle,
  settings,
  cancel,
  apply,
  close,
  max,
  gold, // word "or"/"gold"
  gems, // word "gemmes"/"gems"

  // Start screen — tabs & header
  tabRun,
  tabHeroes,
  tabLevels,
  gemsCount, // 'Gemmes: {0}'
  startTeamTitle,
  heroesSelected, // '{0}/{1} héros sélectionnés'
  chooseFirstHero,
  launchRun,
  continueSavedRun,
  buyHeroesTitle,
  gemsPerHero, // '{0} gemmes par héros'
  unlocked,
  statsButton,
  upgradeHeroesTitle,
  upgradeSubtitle, // '... {0} gemmes ...'
  unlockHeroFirst,
  gemsCost, // '{0} gemmes'
  choose,
  heroNameLevel, // '{0} Niv {1}'

  // Hero progress tile
  tileStatLine, // 'Niv {0}  PV {1}  ATK {2}  DEF {3}'
  tilePermanentPoints, // '+{0} PV  +{1} ATK  +{2} DEF  {3} libres'

  // Stat allocation dialog
  statsOf, // 'Stats de {0}'
  levelUnassigned, // 'Niveau {0} — Points non attribués : {1}'
  statRow, // '{0} : {1}'
  remove,
  add,

  // Settings
  darkTheme,
  language,
  autoAttackSpeedTitle,
  autoUseSkills,
  autoUseSkillsDesc,
  autoBuyHealing,
  autoBuyHealingDesc,
  autoUseHealing,
  autoUseHealingDesc,
  devMode,
  devModeDesc,
  devAutoRestart,
  devAutoRestartDesc,
  seedLabel,
  seedHint,
  levelUpTitle,
  resetProgress,
  resetProgressConfirm,
  reset,

  // Game — app bar & summary
  waveTitle, // 'Vague {0} — {1}'
  heroesPanel,
  enemiesPanel,
  restart,
  round, // 'Tour {0}'
  roundShort, // 'T{0}'
  heroesAlive, // '{0}/{1} héros en vie'
  enemiesAlive, // '{0}/{1} ennemis en vie'
  heroesShort, // 'H {0}/{1}'
  enemiesShort, // 'E {0}/{1}'
  goldGems, // 'Or : {0}   Gemmes : {1}'
  goldShort, // 'O {0}'
  gemsShort, // 'Gem {0}'
  enemyFaction, // 'Faction ennemie : {0}'
  inventory,
  inventoryCount, // 'Inventaire {0}'
  bossIncoming,
  bossDoubleReward,

  // Game — hero action panel
  heroAction,
  attack,
  skill,
  skillChargeLine, // '{0} : {1} — Charge {2}/{3}'
  chooseHero,
  actWith, // 'Agir avec {0}'
  heroShort,
  actShort,
  autoOn,
  autoOff,
  autoOnShort,
  autoShort,
  restartRun,
  openShop,
  skipShop,

  // Game — dev tools
  devShort,
  devTools,
  addGold,
  addGoldShort,
  addGems,
  addGemsShort,
  applyEffect,
  effectShort,
  openMerchant,
  shopShort,
  applyDevEffect,
  effectLabel,
  targetLabel,
  ally,
  enemy,
  targetOption, // '{0} — {1}'

  // Game — merchant
  merchant,
  goldAmount, // 'Or : {0}'
  potionSmallXp,
  potionLargeXp,
  potionSuperXp,
  xpAmount, // '+{0} XP'
  potionHealing,
  useOnInjured,
  stockHealing, // 'Stocker une potion de soin — {0}'
  potionTeam,
  useOnAllInjured,
  stockTeam,
  potionSpecial,
  useRecharge,
  stockSpecial,
  specialBarUpgrade,
  specialBarUpgradeDesc,
  continueLabel,
  costGold, // '{0} {or}'

  // Game — hero picker / inventory
  level, // 'Niveau {0}'
  xpValue, // 'XP {0}/{1}'
  dropOnHero,
  invHealing,
  invTeam,
  invSpecial,
  invItemCount, // '{0} x{1}'
  specialCount, // '{0}/{1} spécial'

  // Fighter card
  hp, // 'PV {0}/{1}'
  atkDef, // 'ATK {0}   DEF {1}'
  statLineCompact, // 'PV {0}/{1}  ATK {2}  DEF {3}'
  aiInfo, // 'IA {0}'
  lvlXpCompact, // 'NIV {0} {1}/{2}'
  lvlLabel, // 'NIV {0}'

  // Level-up dialog
  levelUpHeroTitle, // '{0} gagne un niveau'
  statChange, // '{0} ({1} → {2})'

  // Stats (short)
  statHp,
  statAtk,
  statDef,

  // Status effect tooltip
  fxDamagePerTurn, // 'Inflige {0} dégâts par tour'
  fxIgnoresArmor,
  fxDefence, // '{0} défense'
  fxTurnRemaining, // singular
  fxTurnsRemaining, // '{0} tours restants'
  fxLine, // '{0} : {1}. {2}.'

  // Target previews
  previewDamage, // 'DMG {0}'
  previewDamageDot, // 'DMG {0} + {1} {2}/tour'
  previewHeal, // 'SOIN {0}'
  previewDefence, // '+{0} DEF'
  dotBleed,
  dotPoison,

  // Character sheet
  sheetStats, // 'Statistiques'
  sheetCombat, // 'Stats de combat'
  sheetEffects, // 'Effets actifs'
  sheetNoEffects,
  sheetEquipment, // 'Équipement'
  sheetNoItems,
  sheetSkill, // 'Compétence'
  sheetCrit, // 'Critique : {0}% (dégâts ×{1})'
  sheetDoubleStrike, // 'Double frappe : {0}%'
  sheetLifesteal, // 'Vol de vie : {0}%'
  sheetOnHit, // '{0} à l'attaque : {1}% ({2} dégâts/tour, {3} tours)'
  sheetCumulative, // 'Cumulé ×{0} :'
  dotBurn,

  // Items
  itemFound, // 'Objet trouvé !'
  itemGiveTo, // 'Donner à un héros :'
  itemReplaces, // 'Remplace : {0}'
  itemSlotEmpty, // 'Emplacement libre'
  itemRelicCount, // 'Reliques : {0}'
  itemSellFor, // 'Vendre — {0} or'
  slotHelmet,
  slotGloves,
  slotChest,
  slotWeapon,
  slotRelic,
  rarityCommon,
  rarityUncommon,
  rarityLegendary,
  rarityBoss,
}

const Map<K, String> _fr = {
  K.appTitle: 'RogueLite',
  K.settings: 'Réglages',
  K.cancel: 'Annuler',
  K.apply: 'Appliquer',
  K.close: 'Fermer',
  K.max: 'Max',
  K.gold: 'or',
  K.gems: 'gemmes',

  K.tabRun: 'Partie',
  K.tabHeroes: 'Héros',
  K.tabLevels: 'Niveaux',
  K.gemsCount: 'Gemmes : {0}',
  K.startTeamTitle: 'Équipe de départ',
  K.heroesSelected: '{0}/{1} héros sélectionnés',
  K.chooseFirstHero: 'Choisis ton premier héros gratuitement',
  K.launchRun: 'Lancer une partie',
  K.continueSavedRun: 'Continuer la partie sauvegardée',
  K.buyHeroesTitle: 'Acheter des héros',
  K.gemsPerHero: '{0} gemmes par héros',
  K.unlocked: 'Débloqué',
  K.statsButton: 'Stats',
  K.upgradeHeroesTitle: 'Améliorer les héros',
  K.upgradeSubtitle:
      'Achète des points. Le prix augmente de {0} gemmes à chaque niveau.',
  K.unlockHeroFirst: 'Débloque d\'abord un héros pour l\'améliorer.',
  K.gemsCost: '{0} gemmes',
  K.choose: 'Choisir',
  K.heroNameLevel: '{0} Niv {1}',

  K.tileStatLine: 'Niv {0}  PV {1}  ATK {2}  DEF {3}',
  K.tilePermanentPoints: '+{0} PV  +{1} ATK  +{2} DEF  {3} libres',

  K.statsOf: 'Stats de {0}',
  K.levelUnassigned: 'Niveau {0} — Points non attribués : {1}',
  K.statRow: '{0} : {1}',
  K.remove: 'Retirer',
  K.add: 'Ajouter',

  K.darkTheme: 'Thème sombre',
  K.language: 'Langue',
  K.autoAttackSpeedTitle: 'Vitesse attaque auto',
  K.autoUseSkills: 'Compétences en auto',
  K.autoUseSkillsDesc:
      'Les héros utilisent leurs capacités quand elles sont prêtes.',
  K.autoBuyHealing: 'Achat auto soins',
  K.autoBuyHealingDesc: 'Le marchand stocke des soins avec l\'or disponible.',
  K.autoUseHealing: 'Soins auto',
  K.autoUseHealingDesc:
      'Les potions stockées sont utilisées à 25% PV ou moins.',
  K.devMode: 'Mode dev',
  K.devModeDesc: 'Affiche progressivement des informations de débogage.',
  K.devAutoRestart: 'Auto-redémarrage après défaite',
  K.devAutoRestartDesc:
      'Relance automatiquement une partie quand l\'équipe tombe.',
  K.seedLabel: 'Seed',
  K.seedHint: 'ex : test-build-1',
  K.levelUpTitle: 'Montée de niveau',
  K.resetProgress: 'Réinitialiser la progression',
  K.resetProgressConfirm:
      'Toutes les gemmes, héros débloqués, améliorations et parties '
      'sauvegardées seront supprimés.',
  K.reset: 'Réinitialiser',

  K.waveTitle: 'Vague {0} — {1}',
  K.heroesPanel: 'Héros',
  K.enemiesPanel: 'Ennemis',
  K.restart: 'Redémarrer',
  K.round: 'Tour {0}',
  K.roundShort: 'T{0}',
  K.heroesAlive: '{0}/{1} héros en vie',
  K.enemiesAlive: '{0}/{1} ennemis en vie',
  K.heroesShort: 'H {0}/{1}',
  K.enemiesShort: 'E {0}/{1}',
  K.goldGems: 'Or : {0}   Gemmes : {1}',
  K.goldShort: 'O {0}',
  K.gemsShort: 'Gem {0}',
  K.enemyFaction: 'Faction ennemie : {0}',
  K.inventory: 'Inventaire',
  K.inventoryCount: 'Inventaire {0}',
  K.bossIncoming: 'Vague de boss à la prochaine',
  K.bossDoubleReward: 'Vague de boss : récompense doublée',

  K.heroAction: 'Action du héros',
  K.attack: 'Attaque',
  K.skill: 'Compétence',
  K.skillChargeLine: '{0} : {1} — Charge {2}/{3}',
  K.chooseHero: 'Choisis un héros',
  K.actWith: 'Agir avec {0}',
  K.heroShort: 'Héros',
  K.actShort: 'Agir',
  K.autoOn: 'Attaque auto ON',
  K.autoOff: 'Attaque auto OFF',
  K.autoOnShort: 'Auto ON',
  K.autoShort: 'Auto',
  K.restartRun: 'Relancer la partie',
  K.openShop: 'Ouvrir la boutique',
  K.skipShop: 'Passer la boutique',

  K.devShort: 'Dev',
  K.devTools: 'Outils dev',
  K.addGold: '+9999 or',
  K.addGoldShort: '+Or',
  K.addGems: '+999 gemmes',
  K.addGemsShort: '+Gemmes',
  K.applyEffect: 'Appliquer effet',
  K.effectShort: 'Effet',
  K.openMerchant: 'Ouvrir marchand',
  K.shopShort: 'Boutique',
  K.applyDevEffect: 'Appliquer un effet dev',
  K.effectLabel: 'Effet',
  K.targetLabel: 'Cible',
  K.ally: 'Allié',
  K.enemy: 'Ennemi',
  K.targetOption: '{0} — {1}',

  K.merchant: 'Marchand',
  K.goldAmount: 'Or : {0}',
  K.potionSmallXp: 'Petite potion d\'XP',
  K.potionLargeXp: 'Grande potion d\'XP',
  K.potionSuperXp: 'Super potion d\'XP',
  K.xpAmount: '+{0} XP',
  K.potionHealing: 'Potion de soin',
  K.useOnInjured: 'Utiliser sur un héros blessé',
  K.stockHealing: 'Stocker une potion de soin — {0}',
  K.potionTeam: 'Potion d\'équipe',
  K.useOnAllInjured: 'Utiliser sur tous les héros blessés',
  K.stockTeam: 'Stocker une potion d\'équipe — {0}',
  K.potionSpecial: 'Potion d\'attaque spéciale',
  K.useRecharge: 'Recharge entièrement une spéciale',
  K.stockSpecial: 'Stocker une potion spéciale — {0}',
  K.specialBarUpgrade: 'Barre spéciale supplémentaire',
  K.specialBarUpgradeDesc: 'Ajoute une barre de charge spéciale',
  K.continueLabel: 'Continuer',
  K.costGold: '{0} {1}',

  K.level: 'Niveau {0}',
  K.xpValue: 'XP {0}/{1}',
  K.dropOnHero: 'Déposer sur un héros',
  K.invHealing: 'Soin',
  K.invTeam: 'Équipe',
  K.invSpecial: 'Spéciale',
  K.invItemCount: '{0} x{1}',
  K.specialCount: '{0}/{1} spéciale',

  K.hp: 'PV {0}/{1}',
  K.atkDef: 'ATK {0}   DEF {1}',
  K.statLineCompact: 'PV {0}/{1}  ATK {2}  DEF {3}',
  K.aiInfo: 'IA {0}',
  K.lvlXpCompact: 'NIV {0} {1}/{2}',
  K.lvlLabel: 'NIV {0}',

  K.levelUpHeroTitle: '{0} gagne un niveau',
  K.statChange: '{0} ({1} → {2})',

  K.statHp: 'PV',
  K.statAtk: 'ATK',
  K.statDef: 'DEF',

  K.fxDamagePerTurn: 'Inflige {0} dégâts par tour',
  K.fxIgnoresArmor: 'Ignore l\'armure',
  K.fxDefence: '{0} défense',
  K.fxTurnRemaining: '1 tour restant',
  K.fxTurnsRemaining: '{0} tours restants',
  K.fxLine: '{0} : {1}. {2}.',

  K.previewDamage: 'DMG {0}',
  K.previewDamageDot: 'DMG {0} + {1} {2}/tour',
  K.previewHeal: 'SOIN {0}',
  K.previewDefence: '+{0} DEF',
  K.dotBleed: 'saignement',
  K.dotPoison: 'poison',

  K.sheetStats: 'Statistiques',
  K.sheetCombat: 'Stats de combat',
  K.sheetEffects: 'Effets actifs',
  K.sheetNoEffects: 'Aucun effet actif',
  K.sheetEquipment: 'Équipement',
  K.sheetNoItems: 'Aucun objet',
  K.sheetSkill: 'Compétence',
  K.sheetCrit: 'Critique : {0}% (dégâts ×{1})',
  K.sheetDoubleStrike: 'Double frappe : {0}%',
  K.sheetLifesteal: 'Vol de vie : {0}%',
  K.sheetOnHit: '{0} à l\'attaque : {1}% ({2} dégâts/tour, {3} tours)',
  K.sheetCumulative: 'Cumulé ×{0} :',
  K.dotBurn: 'brûlure',

  K.itemFound: 'Objet trouvé !',
  K.itemGiveTo: 'Donner à un héros :',
  K.itemReplaces: 'Remplace : {0}',
  K.itemSlotEmpty: 'Emplacement libre',
  K.itemRelicCount: 'Reliques : {0}',
  K.itemSellFor: 'Vendre — {0} or',
  K.slotHelmet: 'Casque',
  K.slotGloves: 'Gants',
  K.slotChest: 'Armure',
  K.slotWeapon: 'Arme',
  K.slotRelic: 'Relique',
  K.rarityCommon: 'Commun',
  K.rarityUncommon: 'Rare',
  K.rarityLegendary: 'Légendaire',
  K.rarityBoss: 'Boss',
};

const Map<K, String> _en = {
  K.appTitle: 'RogueLite',
  K.settings: 'Settings',
  K.cancel: 'Cancel',
  K.apply: 'Apply',
  K.close: 'Close',
  K.max: 'Max',
  K.gold: 'gold',
  K.gems: 'gems',

  K.tabRun: 'Run',
  K.tabHeroes: 'Heroes',
  K.tabLevels: 'Levels',
  K.gemsCount: 'Gems: {0}',
  K.startTeamTitle: 'Starting team',
  K.heroesSelected: '{0}/{1} heroes selected',
  K.chooseFirstHero: 'Choose your first hero for free',
  K.launchRun: 'Start a run',
  K.continueSavedRun: 'Continue saved run',
  K.buyHeroesTitle: 'Buy heroes',
  K.gemsPerHero: '{0} gems per hero',
  K.unlocked: 'Unlocked',
  K.statsButton: 'Stats',
  K.upgradeHeroesTitle: 'Upgrade heroes',
  K.upgradeSubtitle:
      'Buy points. The price rises by {0} gems each level.',
  K.unlockHeroFirst: 'Unlock a hero first to upgrade it.',
  K.gemsCost: '{0} gems',
  K.choose: 'Choose',
  K.heroNameLevel: '{0} Lv {1}',

  K.tileStatLine: 'Lv {0}  HP {1}  ATK {2}  DEF {3}',
  K.tilePermanentPoints: '+{0} HP  +{1} ATK  +{2} DEF  {3} free',

  K.statsOf: '{0} stats',
  K.levelUnassigned: 'Level {0} — Unassigned points: {1}',
  K.statRow: '{0}: {1}',
  K.remove: 'Remove',
  K.add: 'Add',

  K.darkTheme: 'Dark theme',
  K.language: 'Language',
  K.autoAttackSpeedTitle: 'Auto attack speed',
  K.autoUseSkills: 'Auto skills',
  K.autoUseSkillsDesc: 'Heroes use their abilities when they are ready.',
  K.autoBuyHealing: 'Auto buy healing',
  K.autoBuyHealingDesc: 'The merchant stocks healing with available gold.',
  K.autoUseHealing: 'Auto healing',
  K.autoUseHealingDesc: 'Stocked potions are used at 25% HP or less.',
  K.devMode: 'Dev mode',
  K.devModeDesc: 'Progressively shows debug information.',
  K.devAutoRestart: 'Auto restart after defeat',
  K.devAutoRestartDesc: 'Automatically restarts a run when the team falls.',
  K.seedLabel: 'Seed',
  K.seedHint: 'e.g. test-build-1',
  K.levelUpTitle: 'Level-up',
  K.resetProgress: 'Reset progress',
  K.resetProgressConfirm:
      'All gems, unlocked heroes, upgrades and saved runs will be deleted.',
  K.reset: 'Reset',

  K.waveTitle: 'Wave {0} — {1}',
  K.heroesPanel: 'Heroes',
  K.enemiesPanel: 'Enemies',
  K.restart: 'Restart',
  K.round: 'Round {0}',
  K.roundShort: 'R{0}',
  K.heroesAlive: '{0}/{1} heroes alive',
  K.enemiesAlive: '{0}/{1} enemies alive',
  K.heroesShort: 'H {0}/{1}',
  K.enemiesShort: 'E {0}/{1}',
  K.goldGems: 'Gold: {0}   Gems: {1}',
  K.goldShort: 'G {0}',
  K.gemsShort: 'Gem {0}',
  K.enemyFaction: 'Enemy faction: {0}',
  K.inventory: 'Inventory',
  K.inventoryCount: 'Inventory {0}',
  K.bossIncoming: 'Boss wave incoming next',
  K.bossDoubleReward: 'Boss wave: double reward',

  K.heroAction: 'Hero action',
  K.attack: 'Attack',
  K.skill: 'Skill',
  K.skillChargeLine: '{0}: {1} — Charge {2}/{3}',
  K.chooseHero: 'Choose a hero',
  K.actWith: 'Act with {0}',
  K.heroShort: 'Hero',
  K.actShort: 'Act',
  K.autoOn: 'Auto attack ON',
  K.autoOff: 'Auto attack OFF',
  K.autoOnShort: 'Auto ON',
  K.autoShort: 'Auto',
  K.restartRun: 'Restart run',
  K.openShop: 'Open shop',
  K.skipShop: 'Skip shop',

  K.devShort: 'Dev',
  K.devTools: 'Dev tools',
  K.addGold: '+9999 gold',
  K.addGoldShort: '+Gold',
  K.addGems: '+999 gems',
  K.addGemsShort: '+Gems',
  K.applyEffect: 'Apply effect',
  K.effectShort: 'Effect',
  K.openMerchant: 'Open merchant',
  K.shopShort: 'Shop',
  K.applyDevEffect: 'Apply dev effect',
  K.effectLabel: 'Effect',
  K.targetLabel: 'Target',
  K.ally: 'Ally',
  K.enemy: 'Enemy',
  K.targetOption: '{0} — {1}',

  K.merchant: 'Merchant',
  K.goldAmount: 'Gold: {0}',
  K.potionSmallXp: 'Small XP potion',
  K.potionLargeXp: 'Large XP potion',
  K.potionSuperXp: 'Super XP potion',
  K.xpAmount: '+{0} XP',
  K.potionHealing: 'Healing potion',
  K.useOnInjured: 'Use now on an injured hero',
  K.stockHealing: 'Stock healing potion — {0}',
  K.potionTeam: 'Team potion',
  K.useOnAllInjured: 'Use now on all injured heroes',
  K.stockTeam: 'Stock team potion — {0}',
  K.potionSpecial: 'Special attack potion',
  K.useRecharge: 'Use now to fully recharge a special',
  K.stockSpecial: 'Stock special potion — {0}',
  K.specialBarUpgrade: 'Special bar upgrade',
  K.specialBarUpgradeDesc: 'Adds one extra special charge bar',
  K.continueLabel: 'Continue',
  K.costGold: '{0} {1}',

  K.level: 'Level {0}',
  K.xpValue: 'XP {0}/{1}',
  K.dropOnHero: 'Drop on a hero',
  K.invHealing: 'Healing',
  K.invTeam: 'Team',
  K.invSpecial: 'Special',
  K.invItemCount: '{0} x{1}',
  K.specialCount: '{0}/{1} special',

  K.hp: 'HP {0}/{1}',
  K.atkDef: 'ATK {0}   DEF {1}',
  K.statLineCompact: 'HP {0}/{1}  ATK {2}  DEF {3}',
  K.aiInfo: 'AI {0}',
  K.lvlXpCompact: 'LVL {0} {1}/{2}',
  K.lvlLabel: 'LVL {0}',

  K.levelUpHeroTitle: '{0} reaches a new level',
  K.statChange: '{0} ({1} → {2})',

  K.statHp: 'HP',
  K.statAtk: 'ATK',
  K.statDef: 'DEF',

  K.fxDamagePerTurn: 'Inflicts {0} damage each turn',
  K.fxIgnoresArmor: 'Ignores armor',
  K.fxDefence: '{0} defence',
  K.fxTurnRemaining: '1 turn remaining',
  K.fxTurnsRemaining: '{0} turns remaining',
  K.fxLine: '{0}: {1}. {2}.',

  K.previewDamage: 'DMG {0}',
  K.previewDamageDot: 'DMG {0} + {1} {2}/turn',
  K.previewHeal: 'HEAL {0}',
  K.previewDefence: '+{0} DEF',
  K.dotBleed: 'bleed',
  K.dotPoison: 'poison',

  K.sheetStats: 'Statistics',
  K.sheetCombat: 'Combat stats',
  K.sheetEffects: 'Active effects',
  K.sheetNoEffects: 'No active effect',
  K.sheetEquipment: 'Equipment',
  K.sheetNoItems: 'No items',
  K.sheetSkill: 'Skill',
  K.sheetCrit: 'Critical: {0}% (damage ×{1})',
  K.sheetDoubleStrike: 'Double strike: {0}%',
  K.sheetLifesteal: 'Lifesteal: {0}%',
  K.sheetOnHit: '{0} on hit: {1}% ({2} damage/turn, {3} turns)',
  K.sheetCumulative: 'Combined ×{0}:',
  K.dotBurn: 'burn',

  K.itemFound: 'Item found!',
  K.itemGiveTo: 'Give to a hero:',
  K.itemReplaces: 'Replaces: {0}',
  K.itemSlotEmpty: 'Empty slot',
  K.itemRelicCount: 'Relics: {0}',
  K.itemSellFor: 'Sell — {0} gold',
  K.slotHelmet: 'Helmet',
  K.slotGloves: 'Gloves',
  K.slotChest: 'Armor',
  K.slotWeapon: 'Weapon',
  K.slotRelic: 'Relic',
  K.rarityCommon: 'Common',
  K.rarityUncommon: 'Uncommon',
  K.rarityLegendary: 'Legendary',
  K.rarityBoss: 'Boss',
};

const Map<AppLanguage, Map<K, String>> _dictionaries = {
  AppLanguage.fr: _fr,
  AppLanguage.en: _en,
};

/// Provides the current [AppLanguage] and string lookups to the widget tree.
///
/// Access with `AppLocalizations.of(context)` or, more concisely, the
/// `context.tr(...)` extension below.
class AppLocalizations extends InheritedWidget {
  const AppLocalizations({
    required this.language,
    required super.child,
    super.key,
  });

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    final localizations = context
        .dependOnInheritedWidgetOfExactType<AppLocalizations>();
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }

  /// Looks up [key] for the current language and fills positional `{i}`
  /// placeholders with [args]. Falls back to English, then the key name.
  String t(K key, [List<Object?> args = const []]) {
    final template =
        _dictionaries[language]?[key] ?? _en[key] ?? key.name;
    if (args.isEmpty) return template;
    var result = template;
    for (var i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', '${args[i]}');
    }
    return result;
  }

  // ── Enum label helpers ──────────────────────────────────────────────────

  String mobCategory(MobCategory category) {
    final key = switch (category) {
      MobCategory.monsters => _CategoryKeys.monsters,
      MobCategory.bandits => _CategoryKeys.bandits,
      MobCategory.cultists => _CategoryKeys.cultists,
      MobCategory.mages => _CategoryKeys.mages,
      MobCategory.empire => _CategoryKeys.empire,
      MobCategory.ghosts => _CategoryKeys.ghosts,
      MobCategory.giants => _CategoryKeys.giants,
    };
    return language == AppLanguage.fr ? key.fr : key.en;
  }

  String autoAttackSpeed(AutoAttackSpeed speed) {
    if (language != AppLanguage.fr) {
      return switch (speed) {
        AutoAttackSpeed.instant => 'Instant',
        AutoAttackSpeed.fast => 'Fast',
        AutoAttackSpeed.normal => 'Normal',
        AutoAttackSpeed.slow => 'Slow',
      };
    }
    return speed.label;
  }

  /// Resolves an item's FR/EN text pair for the current language.
  String localized(LocalizedText text) => text.of(language);

  String itemSlot(ItemSlot slot) {
    return switch (slot) {
      ItemSlot.helmet => t(K.slotHelmet),
      ItemSlot.gloves => t(K.slotGloves),
      ItemSlot.chest => t(K.slotChest),
      ItemSlot.weapon => t(K.slotWeapon),
      ItemSlot.relic => t(K.slotRelic),
    };
  }

  String itemRarity(ItemRarity rarity) {
    return switch (rarity) {
      ItemRarity.common => t(K.rarityCommon),
      ItemRarity.uncommon => t(K.rarityUncommon),
      ItemRarity.legendary => t(K.rarityLegendary),
      ItemRarity.boss => t(K.rarityBoss),
    };
  }

  @override
  bool updateShouldNotify(AppLocalizations oldWidget) {
    return oldWidget.language != language;
  }
}

/// Concise access: `context.tr(K.attack)` or `context.tr(K.waveTitle, [n, x])`.
extension AppLocalizationsX on BuildContext {
  String tr(K key, [List<Object?> args = const []]) {
    return AppLocalizations.of(this).t(key, args);
  }

  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Small holder for the two translations of a mob category name.
class _CategoryKeys {
  const _CategoryKeys(this.fr, this.en);
  final String fr;
  final String en;

  static const monsters = _CategoryKeys('Monstres', 'Monsters');
  static const bandits = _CategoryKeys('Bandits', 'Bandits');
  static const cultists = _CategoryKeys('Cultistes', 'Cultists');
  static const mages = _CategoryKeys('Mages', 'Mages');
  static const empire = _CategoryKeys('Empire', 'Empire');
  static const ghosts = _CategoryKeys('Fantômes', 'Ghosts');
  static const giants = _CategoryKeys('Géants', 'Giants');
}
