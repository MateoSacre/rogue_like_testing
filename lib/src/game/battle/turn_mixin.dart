import 'dart:math';

import '../../models/enums.dart';
import '../../models/team.dart';
import '../../settings/game_settings.dart';
import '../game_balance.dart';
import '../targeting.dart';
import 'battle_state.dart';

/// Manages the turn cycle: hero actions, mob turn, wave transitions,
/// and the hero-phase setup at the start of each round.
mixin TurnMixin on BattleControllerBase {
  // ── Hero action ───────────────────────────────────────────────────────────

  Future<void> performSelectedAction({
    required Future<void> Function() pause,
    required void Function() notify,
    required LevelUpMode levelUpMode,
  }) async {
    if (!canAct || selectedHero == null) return;
    currentLevelUpMode = levelUpMode;
    final hero = selectedHero!;
    applyEffectsOnTurnStart(hero);
    if (!hero.isAlive) {
      actedHeroes.add(hero);
      await _afterHeroActed(pause: pause, notify: notify, levelUpMode: levelUpMode);
      return;
    }

    if (actionMode == ActionMode.skill && hero.skill != null) {
      final skill = hero.skill!;
      final targets = resolveManualTargets(hero, skill);
      skill.apply(this, hero, targets);
      rewardDefeatedMobs(hero);
      skill.startCooldown();
      hero.skill?.tickCooldown();
    } else {
      final target = selectedTarget ?? autoTargetFor(hero) ?? mobs.alive.first;
      basicAttack(hero, target);
      hero.skill?.tickCooldown();
    }

    actedHeroes.add(hero);
    await _afterHeroActed(pause: pause, notify: notify, levelUpMode: levelUpMode);
  }

  Future<void> _afterHeroActed({
    required Future<void> Function() pause,
    required void Function() notify,
    required LevelUpMode levelUpMode,
  }) async {
    selectedTarget = null;
    actionMode = ActionMode.attack;

    if (mobs.isDefeated) {
      finishWave(levelUpMode);
      return;
    }
    if (availableHeroes.isEmpty) {
      selectedHero = null;
      await mobTurn(pause: pause, notify: notify);
    } else {
      selectedHero = availableHeroes.first;
      actionMode = selectedHero?.skill?.isReady == true
          ? ActionMode.skill
          : ActionMode.attack;
    }
  }

  // ── Mob turn ──────────────────────────────────────────────────────────────

  @override
  Future<void> mobTurn({
    required Future<void> Function() pause,
    required void Function() notify,
  }) async {
    isAnimating = true;
    roundsThisWave++;
    selectedHero = null;
    selectedTarget = null;
    notify();

    for (final mob in mobs.alive) {
      if (heroes.isDefeated) break;
      applyEffectsOnTurnStart(mob);
      if (!mob.isAlive) {
        rewardDotKill(mob);
        continue;
      }

      final skill = mob.skill;
      if (skill != null && skill.isReady) {
        final targets = autoTargetsForSkill(mob, skill, mobs, heroes);
        final shouldUse = skill.shouldUse?.call(mob, targets) ?? true;
        if (targets.isNotEmpty && shouldUse) {
          activeMob = mob;
          activeMobTarget = targets.first;
          notify();
          await pause();
          skill.apply(this, mob, targets);
          skill.startCooldown();
          skill.tickCooldown();
          activeMob = null;
          activeMobTarget = null;
          notify();
          continue;
        }
      }

      final target = pickMobTargets(mob, heroes.alive, 1).firstOrNull;
      if (target != null) {
        activeMob = mob;
        activeMobTarget = target;
        notify();
        await pause();
        basicAttack(mob, target);
      }
      mob.skill?.tickCooldown();
      activeMob = null;
      activeMobTarget = null;
      notify();
    }

    removeBuffs(heroes);
    removeBuffs(mobs);
    isAnimating = false;
    activeMob = null;
    activeMobTarget = null;

    if (heroes.isDefeated) {
      _triggerGameOver('Game over at wave $waveCounter');
      notify();
      return;
    }
    if (!mobs.isDefeated &&
        roundsThisWave >= GameBalance.maxRoundsPerWave) {
      _resolveWaveByHpRatio();
      notify();
      return;
    }
    _startHeroPhase();
    notify();
  }

  /// Tie-break for a wave still unresolved after [GameBalance.maxRoundsPerWave]
  /// rounds: the team with the highest HP ratio wins. Heroes win the wave (and
  /// collect its rewards); mobs winning ends the run.
  void _resolveWaveByHpRatio() {
    final heroRatio = teamHpRatio(heroes);
    final mobRatio = teamHpRatio(mobs);
    final heroPct = (heroRatio * 100).round();
    final mobPct = (mobRatio * 100).round();
    if (heroRatio >= mobRatio) {
      addLog(
        'Wave $waveCounter decided on HP after '
        '${GameBalance.maxRoundsPerWave} rounds: heroes win '
        '($heroPct% vs $mobPct%)',
      );
      finishWave(currentLevelUpMode);
    } else {
      _triggerGameOver(
        'Wave $waveCounter lost on HP after '
        '${GameBalance.maxRoundsPerWave} rounds ($heroPct% vs $mobPct%)',
      );
    }
  }

  double teamHpRatio(Team team) {
    var hp = 0.0;
    var maxHp = 0.0;
    for (final fighter in team.members) {
      hp += fighter.hp;
      maxHp += fighter.maxHp;
    }
    return maxHp <= 0 ? 0 : hp / maxHp;
  }

  void _triggerGameOver(String reason) {
    gameOver = true;
    autoAttackWasEnabledOnGameOver = autoAttackEnabled;
    autoAttackEnabled = false;
    gems += max(1, waveCounter ~/ GameBalance.finalThemeWaveRewardMultiplier);
    addLog(reason);
  }

  // ── Auto-attack control ───────────────────────────────────────────────────

  @override
  void stopAutoAttack() {
    autoAttackEnabled = false;
    resumeAutoAttackAfterMerchant = false;
  }

  // ── Wave transitions ──────────────────────────────────────────────────────

  @override
  void finishWave(LevelUpMode levelUpMode) {
    final clearedBossWave = waveInfo.finalWaveInTheme;
    _rewardWave(levelUpMode);
    if (clearedBossWave &&
        random.nextInt(GameBalance.merchantChanceDivisor) == 0) {
      merchantAvailable = true;
      resumeAutoAttackAfterMerchant = autoAttackEnabled;
      selectedHero = null;
      selectedTarget = null;
      addLog('A merchant appears');
      return;
    }
    startNextWave();
  }

  @override
  void startNextWave() {
    waveCounter++;
    roundCounter = 1;
    roundsThisWave = 0;
    rewardedMobs.clear();
    waveInfo = waveGenerator.generate(waveCounter + GameBalance.waveValueOffset);
    addLog(
      'Wave $waveCounter: ${waveInfo.category.label}'
      '${waveInfo.finalWaveInTheme ? ' final' : ''}',
    );
    if (waveInfo.finalWaveInTheme) {
      addLog('Boss wave: stay sharp');
    } else if (bossWaveIncoming) {
      addLog('Warning: boss wave next');
    }
    _startHeroPhase();
  }

  void _startHeroPhase() {
    roundCounter++;
    actedHeroes.clear();
    selectedHero = availableHeroes.firstOrNull;
    selectedTarget = null;
    actionMode = selectedHero?.skill?.isReady == true
        ? ActionMode.skill
        : ActionMode.attack;
  }

  // ── Wave reward ───────────────────────────────────────────────────────────

  void _rewardWave(LevelUpMode levelUpMode) {
    final aliveHeroes = heroes.alive;
    if (aliveHeroes.isEmpty) return;
    var waveXp =
        ((waveCounter + GameBalance.waveValueOffset) *
            GameBalance.waveRewardMultiplier) ~/
        aliveHeroes.length;
    if (waveInfo.finalWaveInTheme) {
      waveXp *= GameBalance.finalThemeWaveRewardMultiplier;
    }
    for (final hero in aliveHeroes) {
      gainXp(hero, waveXp, levelUpMode);
      hero.heal(hero.maxHp * GameBalance.postWaveHealRatio);
    }
    addLog('Wave $waveCounter cleared. Reward: $waveXp xp per hero');
  }
}
