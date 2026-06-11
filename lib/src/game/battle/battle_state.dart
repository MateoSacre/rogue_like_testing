import 'dart:math';

import '../../models/battle_actions.dart';
import '../../models/enums.dart';
import '../../models/fighter.dart';
import '../../models/level_up_stat.dart';
import '../../models/skill.dart';
import '../../models/team.dart';
import '../../models/wave_info.dart';
import '../../settings/game_settings.dart';
import '../game_balance.dart';
import '../wave_generator.dart';

/// Holds all mutable state for [BattleController] and declares the
/// cross-mixin interface that the individual mixins implement.
///
/// Keeping state here means each mixin can safely read/write shared
/// fields through `this` without carrying its own storage.
abstract class BattleControllerBase implements BattleActions {
  BattleControllerBase({this.seedString = ''});

  // ── RNG ───────────────────────────────────────────────────────────────────
  String seedString;
  late Random random;

  // ── Wave management ───────────────────────────────────────────────────────
  late ThemedWaveGenerator waveGenerator;
  late WaveInfo waveInfo;
  int waveCounter = 0;
  int roundCounter = 1;

  /// Rounds elapsed on the current wave (reset each wave). Used to trigger the
  /// HP-ratio tie-break once it reaches [GameBalance.maxRoundsPerWave].
  int roundsThisWave = 0;

  // ── Combatants ────────────────────────────────────────────────────────────
  late Team heroes;

  // ── Turn tracking ─────────────────────────────────────────────────────────
  final List<PendingLevelUp> pendingLevelUps = [];
  final Set<Fighter> actedHeroes = {};
  final Set<Fighter> rewardedMobs = {};

  // ── UI / selection state ──────────────────────────────────────────────────
  Fighter? selectedHero;
  Fighter? selectedTarget;
  Fighter? activeMob;
  Fighter? activeMobTarget;
  ActionMode actionMode = ActionMode.attack;
  LevelUpMode currentLevelUpMode = LevelUpMode.manual;

  // ── Economy ───────────────────────────────────────────────────────────────
  int gold = 0;
  int gems = 0;
  int healingPotionStock = 0;
  int teamPotionStock = 0;
  int specialPotionStock = 0;

  // ── Game-state flags ──────────────────────────────────────────────────────
  bool gameOver = false;
  bool merchantAvailable = false;
  bool resumeAutoAttackAfterMerchant = false;
  bool isAnimating = false;
  bool autoAttackEnabled = false;
  bool isAutoAttackRunning = false;
  bool autoAttackWasEnabledOnGameOver = false;
  bool devMode = false;

  // ── Log ───────────────────────────────────────────────────────────────────
  final List<String> log = [];

  // ── Derived getters ───────────────────────────────────────────────────────

  Team get mobs => waveInfo.team;

  bool get bossWaveIncoming =>
      !waveInfo.finalWaveInTheme && waveGenerator.wavesRemainingInTheme == 1;

  List<Fighter> get availableHeroes =>
      heroes.alive.where((hero) => !actedHeroes.contains(hero)).toList();

  bool get canBuySinglePotion => gold >= GameBalance.singlePotionCost;
  bool get canBuyTeamPotion => gold >= GameBalance.teamPotionCost;
  bool get canBuySmallXpPotion => gold >= GameBalance.smallXpPotionCost;
  bool get canBuyLargeXpPotion => gold >= GameBalance.largeXpPotionCost;
  bool get canBuySuperXpPotion => gold >= GameBalance.superXpPotionCost;
  bool get canBuySpecialPotion => gold >= GameBalance.specialPotionCost;
  bool get canBuySpecialBarUpgrade => gold >= GameBalance.specialBarUpgradeCost;
  bool get hasInjuredHero => heroes.alive.any((hero) => hero.hp < hero.maxHp);
  List<Fighter> get allFighters => [...heroes.members, ...mobs.members];

  // ── Cross-mixin interface ─────────────────────────────────────────────────
  // Declared here so mixin methods can call each other through `this`
  // while remaining statically type-safe. Each method is implemented
  // by the mixin named in the comment above it.

  // CombatMixin
  double computeAttackDamage(Fighter attacker, Fighter target, {double modifier = 1});
  double computeDamagePreview(Fighter attacker, Fighter target, {double modifier = 1});
  void applyEffectsOnTurnStart(Fighter fighter);
  void removeBuffs(Team team);
  void rewardDefeatedMobs(Fighter attacker);

  // LevelingMixin
  void gainXp(Fighter hero, int xp, LevelUpMode levelUpMode);

  // TurnMixin
  Future<void> mobTurn({
    required Future<void> Function() pause,
    required void Function() notify,
  });
  void stopAutoAttack();
  void finishWave(LevelUpMode levelUpMode);
  void startNextWave();

  // AutoAttackMixin
  Fighter? autoTargetFor(Fighter hero);

  // InventoryMixin
  int autoBuyHealingItems();
  void continueAfterMerchant();
  bool useHealingPotion(Fighter hero);
  bool useTeamPotion();

  // SelectionMixin
  bool get canAct;
  List<Fighter> resolveManualTargets(Fighter caster, Skill skill);
}
