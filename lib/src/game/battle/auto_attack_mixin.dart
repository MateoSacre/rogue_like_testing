import '../../models/enums.dart';
import '../../models/fighter.dart';
import '../targeting.dart';
import 'battle_state.dart';

/// Drives the auto-attack loop and contains the AI helpers that decide
/// which hero acts next, which target to pick, and whether to use a skill.
mixin AutoAttackMixin on BattleControllerBase {
  // ── Auto-attack loop ──────────────────────────────────────────────────────

  Future<void> performAutoAttack({
    required Future<void> Function() pause,
    required void Function() notify,
    required bool useSkills,
    required bool autoBuyHealingItems,
    required bool useHealingItems,
  }) async {
    autoAttackEnabled = true;
    if (isAutoAttackRunning || gameOver) return;
    isAutoAttackRunning = true;

    try {
      while (autoAttackEnabled && !gameOver) {
        if (merchantAvailable) {
          if (autoBuyHealingItems) {
            this.autoBuyHealingItems();
            continueAfterMerchant();
            notify();
            continue;
          }
          break;
        }

        if (mobs.isDefeated) {
          finishWave();
          notify();
          continue;
        }

        if (availableHeroes.isEmpty) {
          selectedHero = null;
          selectedTarget = null;
          await mobTurn(pause: pause, notify: notify);
          continue;
        }

        final hero = _nextAutoHero();
        final target = autoTargetFor(hero);
        if (target == null) break;

        selectedHero = hero;
        selectedTarget = _autoVisualTargetFor(hero, target, useSkills: useSkills);
        actionMode = ActionMode.attack;
        notify();
        await pause();

        if (!autoAttackEnabled || gameOver) break;

        applyEffectsOnTurnStart(hero);
        if (useHealingItems) useAutoHealingItems();
        if (hero.isAlive && target.isAlive) {
          _performAutoHeroAction(hero, target, useSkills: useSkills);
        }
        actedHeroes.add(hero);
        selectedTarget = null;
        if (useHealingItems) useAutoHealingItems();
        notify();
      }
    } finally {
      isAutoAttackRunning = false;
      if (gameOver) autoAttackEnabled = false;
      selectedTarget = null;
      if (!autoAttackEnabled && !isAnimating) {
        selectedHero = availableHeroes.firstOrNull;
        actionMode = selectedHero?.skill?.isReady == true
            ? ActionMode.skill
            : ActionMode.attack;
      }
      notify();
    }
  }

  // ── Auto-healing ──────────────────────────────────────────────────────────

  int useAutoHealingItems() {
    var used = 0;
    if (_shouldUseTeamPotionAutomatically()) {
      if (useTeamPotion()) used++;
    }
    for (final hero in heroes.alive) {
      if (healingPotionStock <= 0) break;
      if (_needsAutoHealing(hero) && useHealingPotion(hero)) used++;
    }
    return used;
  }

  bool _shouldUseTeamPotionAutomatically() {
    final alive = heroes.alive;
    if (alive.length <= 1 || teamPotionStock <= 0) return false;
    return alive.every(_needsAutoHealing);
  }

  bool _needsAutoHealing(Fighter hero) =>
      hero.isAlive && hero.hp <= hero.maxHp * .25 && hero.hp < hero.maxHp;

  // ── Target / hero selection AI ────────────────────────────────────────────

  Fighter _nextAutoHero() {
    final ordered = [...availableHeroes];
    ordered.sort((a, b) {
      return _bestDamageAgainstAliveMob(b).compareTo(_bestDamageAgainstAliveMob(a));
    });
    return ordered.first;
  }

  @override
  Fighter? autoTargetFor(Fighter hero) {
    final alive = mobs.alive;
    if (alive.isEmpty) return null;
    final killable = alive
        .where((mob) => computeAttackDamage(hero, mob) >= mob.hp)
        .toList()
      ..sort((a, b) => b.hp.compareTo(a.hp));
    if (killable.isNotEmpty) return killable.first;
    return ([...alive]..sort((a, b) => b.hp.compareTo(a.hp))).first;
  }

  Fighter _autoVisualTargetFor(
    Fighter hero,
    Fighter attackTarget, {
    required bool useSkills,
  }) {
    final skill = hero.skill;
    if (!useSkills || skill == null || !skill.isReady) return attackTarget;
    final targets = autoTargetsForSkill(hero, skill, heroes, mobs);
    return targets.isEmpty ? attackTarget : targets.first;
  }

  double _bestDamageAgainstAliveMob(Fighter hero) {
    if (mobs.alive.isEmpty) return 0;
    return mobs.alive.map((mob) => computeDamagePreview(hero, mob)).reduce(
      (a, b) => a > b ? a : b,
    );
  }

  // ── Hero action execution ─────────────────────────────────────────────────

  void _performAutoHeroAction(
    Fighter hero,
    Fighter target, {
    required bool useSkills,
  }) {
    final skill = hero.skill;
    if (useSkills && skill != null && skill.isReady) {
      final targets = autoTargetsForSkill(hero, skill, heroes, mobs);
      final shouldUse =
          targets.isNotEmpty && (skill.shouldUse?.call(hero, targets) ?? true);
      if (shouldUse) {
        skill.apply(this, hero, targets);
        rewardDefeatedMobs(hero);
        skill.startCooldown();
        skill.tickCooldown();
        return;
      }
    }
    basicAttack(hero, target);
    hero.skill?.tickCooldown();
  }
}
