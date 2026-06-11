import 'dart:math' hide log;

import '../data/heroes.dart';
import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/team.dart';
import '../models/wave_info.dart';
import 'battle/auto_attack_mixin.dart';
import 'battle/battle_state.dart';
import 'battle/combat_mixin.dart';
import 'battle/dev_mixin.dart';
import 'battle/inventory_mixin.dart';
import 'battle/leveling_mixin.dart';
import 'battle/selection_mixin.dart';
import 'battle/turn_mixin.dart';
import 'game_balance.dart';
import 'wave_generator.dart';

/// The central game-logic object.
///
/// State lives in [BattleControllerBase]. The seven mixins each own a
/// logical slice of behaviour:
///   - [CombatMixin]      — damage, effects, kill rewards, log
///   - [TurnMixin]        — hero/mob turn cycle, wave transitions
///   - [AutoAttackMixin]  — auto-attack loop and AI helpers
///   - [LevelingMixin]    — XP gain and level-up application
///   - [InventoryMixin]   — potions, XP potions, skill upgrades, merchant
///   - [SelectionMixin]   — UI selection state and canAct queries
///   - [DevMixin]         — dev-mode utilities
class BattleController extends BattleControllerBase
    with
        CombatMixin,
        LevelingMixin,
        TurnMixin,
        AutoAttackMixin,
        InventoryMixin,
        SelectionMixin,
        DevMixin {
  BattleController({
    List<Fighter>? heroes,
    int gems = 0,
    super.seedString = '',
  }) {
    resetGame(heroes: heroes, gems: gems);
  }

  BattleController.fromJson(Map<String, dynamic> json, {String seedString = ''})
    : super(
        seedString: seedString.isEmpty
            ? (json['seedString'] as String? ?? '')
            : seedString,
      ) {
    _resetRandom();
    loadFromJson(json);
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  void resetGame({List<Fighter>? heroes, int? gems}) {
    _resetRandom();
    waveGenerator = ThemedWaveGenerator(random);
    this.heroes = Team(
      'Base Team',
      (heroes == null || heroes.isEmpty)
          ? buildBaseTeam()
          : heroes.map((h) => h.copy()).toList(),
    );
    waveCounter = 0;
    roundCounter = 1;
    roundsThisWave = 0;
    gold = 0;
    this.gems = gems ?? this.gems;
    healingPotionStock = 0;
    teamPotionStock = 0;
    specialPotionStock = 0;
    gameOver = false;
    merchantAvailable = false;
    resumeAutoAttackAfterMerchant = false;
    actedHeroes.clear();
    rewardedMobs.clear();
    selectedHero = null;
    selectedTarget = null;
    activeMob = null;
    activeMobTarget = null;
    isAnimating = false;
    autoAttackEnabled = false;
    isAutoAttackRunning = false;
    autoAttackWasEnabledOnGameOver = false;
    log.clear();
    pendingLevelUps.clear();
    startNextWave();
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'waveCounter': waveCounter,
      'roundCounter': roundCounter,
      'roundsThisWave': roundsThisWave,
      'gold': gold,
      'gems': gems,
      'healingPotionStock': healingPotionStock,
      'teamPotionStock': teamPotionStock,
      'specialPotionStock': specialPotionStock,
      'seedString': seedString,
      'gameOver': gameOver,
      'merchantAvailable': merchantAvailable,
      'resumeAutoAttackAfterMerchant': resumeAutoAttackAfterMerchant,
      'category': waveInfo.category.name,
      'finalWaveInTheme': waveInfo.finalWaveInTheme,
      'wavesRemainingInTheme': waveGenerator.wavesRemainingInTheme,
      'heroes': heroes.members.map((h) => h.toJson()).toList(),
      'mobs': mobs.members.map((m) => m.toJson()).toList(),
      'log': log.take(GameBalance.maxLogEntries).toList(),
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    waveGenerator = ThemedWaveGenerator(random);
    final category = MobCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => MobCategory.monsters,
    );
    waveGenerator.currentCategory = category;
    waveGenerator.wavesRemainingInTheme =
        json['wavesRemainingInTheme'] as int? ?? 0;

    heroes = Team(
      'Base Team',
      _fighterListFromJson(json['heroes'])
          .where((f) => f.isHero)
          .toList(),
    );
    if (heroes.members.isEmpty) {
      heroes = Team('Base Team', buildBaseTeam());
    }

    final loadedMobs = _fighterListFromJson(json['mobs'])
        .where((f) => !f.isHero)
        .toList();
    final savedMerchantAvailable = json['merchantAvailable'] == true;
    waveInfo = WaveInfo(
      team: Team('Wave', loadedMobs),
      category: category,
      finalWaveInTheme: json['finalWaveInTheme'] == true,
    );
    if (waveInfo.team.members.isEmpty && !savedMerchantAvailable) {
      waveInfo = waveGenerator.generate(GameBalance.waveValueOffset + 1);
    }

    waveCounter = json['waveCounter'] as int? ?? 1;
    roundCounter = json['roundCounter'] as int? ?? 1;
    roundsThisWave = json['roundsThisWave'] as int? ?? 0;
    gold = json['gold'] as int? ?? 0;
    gems = json['gems'] as int? ?? 0;
    healingPotionStock = json['healingPotionStock'] as int? ?? 0;
    teamPotionStock = json['teamPotionStock'] as int? ?? 0;
    specialPotionStock = json['specialPotionStock'] as int? ?? 0;
    gameOver = json['gameOver'] == true;
    merchantAvailable = savedMerchantAvailable;
    resumeAutoAttackAfterMerchant =
        json['resumeAutoAttackAfterMerchant'] == true;
    actedHeroes.clear();
    rewardedMobs.clear();
    selectedHero = availableHeroes.firstOrNull;
    selectedTarget = null;
    activeMob = null;
    activeMobTarget = null;
    isAnimating = false;
    autoAttackEnabled = false;
    isAutoAttackRunning = false;
    autoAttackWasEnabledOnGameOver = false;
    pendingLevelUps.clear();
    log
      ..clear()
      ..addAll((json['log'] as List<dynamic>? ?? const []).whereType<String>());
  }

  // ── RNG helpers ───────────────────────────────────────────────────────────

  void _resetRandom() {
    random = seedString.isEmpty
        ? Random()
        : Random(_seedFromString(seedString));
  }

  int _seedFromString(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  List<Fighter> _fighterListFromJson(Object? raw) {
    return (raw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Fighter.fromJson)
        .toList();
  }
}
