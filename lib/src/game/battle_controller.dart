import 'dart:developer' as developer;
import 'dart:math';

import '../data/heroes.dart';
import '../data/skills.dart';
import '../models/battle_actions.dart';
import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/level_up_stat.dart';
import '../models/skill.dart';
import '../models/team.dart';
import '../models/wave_info.dart';
import '../settings/game_settings.dart';
import '../utils/format.dart';
import 'game_balance.dart';
import 'targeting.dart';
import 'wave_generator.dart';

class BattleController implements BattleActions {
  BattleController({List<Fighter>? heroes, int gems = 0}) {
    resetGame(heroes: heroes, gems: gems);
  }

  BattleController.fromJson(Map<String, dynamic> json) {
    loadFromJson(json);
  }

  final Random random = Random();
  late ThemedWaveGenerator waveGenerator;
  late Team heroes;
  late WaveInfo waveInfo;
  int waveCounter = 0;
  int roundCounter = 1;
  final List<String> log = [];
  final List<PendingLevelUp> pendingLevelUps = [];
  final Set<Fighter> actedHeroes = {};
  final Set<Fighter> rewardedMobs = {};
  Fighter? selectedHero;
  Fighter? selectedTarget;
  Fighter? activeMob;
  Fighter? activeMobTarget;
  ActionMode actionMode = ActionMode.attack;
  int gold = 0;
  int gems = 0;
  int healingPotionStock = 0;
  int teamPotionStock = 0;
  int specialPotionStock = 0;
  bool gameOver = false;
  bool merchantAvailable = false;
  bool resumeAutoAttackAfterMerchant = false;
  bool isAnimating = false;
  bool autoAttackEnabled = false;
  bool isAutoAttackRunning = false;
  bool devMode = false;
  LevelUpMode currentLevelUpMode = LevelUpMode.manual;

  Team get mobs => waveInfo.team;

  bool get bossWaveIncoming {
    return !waveInfo.finalWaveInTheme &&
        waveGenerator.wavesRemainingInTheme == 1;
  }

  List<Fighter> get availableHeroes {
    return heroes.alive.where((hero) => !actedHeroes.contains(hero)).toList();
  }

  bool get canBuySinglePotion => gold >= GameBalance.singlePotionCost;

  bool get canBuyTeamPotion => gold >= GameBalance.teamPotionCost;

  bool get canBuySmallXpPotion => gold >= GameBalance.smallXpPotionCost;

  bool get canBuyLargeXpPotion => gold >= GameBalance.largeXpPotionCost;

  bool get canBuySuperXpPotion => gold >= GameBalance.superXpPotionCost;

  bool get canBuySpecialPotion => gold >= GameBalance.specialPotionCost;

  bool get canBuySpecialBarUpgrade => gold >= GameBalance.specialBarUpgradeCost;

  bool get hasInjuredHero => heroes.alive.any((hero) => hero.hp < hero.maxHp);

  void resetGame({List<Fighter>? heroes, int? gems}) {
    waveGenerator = ThemedWaveGenerator(random);
    this.heroes = Team(
      'Base Team',
      (heroes == null || heroes.isEmpty)
          ? buildBaseTeam()
          : heroes.map((hero) => hero.copy()).toList(),
    );
    waveCounter = 0;
    roundCounter = 1;
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
    log.clear();
    pendingLevelUps.clear();
    _startNextWave();
  }

  Map<String, dynamic> toJson() {
    return {
      'waveCounter': waveCounter,
      'roundCounter': roundCounter,
      'gold': gold,
      'gems': gems,
      'healingPotionStock': healingPotionStock,
      'teamPotionStock': teamPotionStock,
      'specialPotionStock': specialPotionStock,
      'gameOver': gameOver,
      'merchantAvailable': merchantAvailable,
      'resumeAutoAttackAfterMerchant': resumeAutoAttackAfterMerchant,
      'category': waveInfo.category.name,
      'finalWaveInTheme': waveInfo.finalWaveInTheme,
      'wavesRemainingInTheme': waveGenerator.wavesRemainingInTheme,
      'heroes': heroes.members.map((hero) => hero.toJson()).toList(),
      'mobs': mobs.members.map((mob) => mob.toJson()).toList(),
      'log': log.take(GameBalance.maxLogEntries).toList(),
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    waveGenerator = ThemedWaveGenerator(random);
    final category = MobCategory.values.firstWhere(
      (category) => category.name == json['category'],
      orElse: () => MobCategory.monsters,
    );
    waveGenerator.currentCategory = category;
    waveGenerator.wavesRemainingInTheme =
        json['wavesRemainingInTheme'] as int? ?? 0;

    heroes = Team(
      'Base Team',
      _fighterListFromJson(
        json['heroes'],
      ).where((fighter) => fighter.isHero).toList(),
    );
    if (heroes.members.isEmpty) {
      heroes = Team('Base Team', buildBaseTeam());
    }

    final loadedMobs = _fighterListFromJson(
      json['mobs'],
    ).where((fighter) => !fighter.isHero).toList();
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
    pendingLevelUps.clear();
    log
      ..clear()
      ..addAll((json['log'] as List<dynamic>? ?? const []).whereType<String>());
  }

  List<Fighter> _fighterListFromJson(Object? raw) {
    return (raw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Fighter.fromJson)
        .toList();
  }

  void selectHero(Fighter hero) {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return;
    selectedHero = hero;
    selectedTarget = null;
    actionMode = hero.skill?.isReady == true
        ? ActionMode.skill
        : ActionMode.attack;
  }

  void setAction(ActionMode action) {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return;
    actionMode = action;
  }

  bool canToggleEnemyTarget(Fighter target) {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return false;
    if (!target.isAlive || !mobs.members.contains(target)) return false;
    if (actionMode == ActionMode.skill &&
        selectedHero?.skill?.targetType != TargetType.enemySingle) {
      return false;
    }
    return targetsForSelectedAction().contains(target);
  }

  void toggleEnemyTarget(Fighter target) {
    if (!canToggleEnemyTarget(target)) return;
    selectedTarget = selectedTarget == target ? null : target;
  }

  List<Fighter> targetsForSelectedAction() {
    final hero = selectedHero;
    if (hero == null) return [];
    if (actionMode == ActionMode.attack) return mobs.alive;
    final skill = hero.skill;
    if (skill == null || !skill.isReady) return [];
    if (_targetTypeNeedsNoManualTarget()) {
      return resolveManualTargets(hero, skill);
    }
    return manualTargetsForSkill(hero, skill, heroes, mobs);
  }

  String previewForTarget(Fighter target) {
    final hero = selectedHero;
    if (hero == null) return '';
    if (actionMode == ActionMode.attack) {
      return 'DMG ${fmt(computeDamagePreview(hero, target))}';
    }

    final skill = hero.skill;
    if (skill == null || !skill.isReady) return '';

    return switch (skill.name) {
      'Power slash' =>
        'DMG ${fmt(computeDamagePreview(hero, target, modifier: 3))}',
      'Power Strike' =>
        'DMG ${fmt(computeDamagePreview(hero, target, modifier: 2))}',
      'Deep cut' =>
        'DMG ${fmt(computeDamagePreview(hero, target))} + bleed 5/turn',
      'Poison Arrow' =>
        'DMG ${fmt(computeDamagePreview(hero, target))} + poison 2/turn',
      'Nuke' => 'DMG ${fmt(min(target.hp, hero.attackPower * 3))}',
      'Triple Beam' => 'DMG ${fmt(min(target.hp, 16))}',
      'Magic Healing' => 'HEAL ${fmt(target.maxHp * .30)}',
      'Protect' => '+10 DEF',
      _ =>
        skill.targetsEnemies
            ? 'DMG ${fmt(computeDamagePreview(hero, target))}'
            : '',
    };
  }

  bool get canAct {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return false;
    final hero = selectedHero;
    if (hero == null || !hero.isAlive || actedHeroes.contains(hero)) {
      return false;
    }
    if (actionMode == ActionMode.skill && hero.skill?.isReady != true) {
      return false;
    }
    final targets = targetsForSelectedAction();
    if (targets.isEmpty) return false;
    if (selectedTarget != null) return targets.contains(selectedTarget);
    if (_targetTypeNeedsNoManualTarget()) {
      return true;
    }
    return actionMode == ActionMode.attack ||
        hero.skill?.targetType == TargetType.enemySingle;
  }

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
      await _afterHeroActed(
        pause: pause,
        notify: notify,
        levelUpMode: levelUpMode,
      );
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
      final target = selectedTarget ?? _autoTargetFor(hero) ?? mobs.alive.first;
      basicAttack(hero, target);
      hero.skill?.tickCooldown();
    }

    actedHeroes.add(hero);
    await _afterHeroActed(
      pause: pause,
      notify: notify,
      levelUpMode: levelUpMode,
    );
  }

  Future<void> performAutoAttack({
    required Future<void> Function() pause,
    required void Function() notify,
    required bool useSkills,
    required bool autoBuyHealingItems,
    required bool useHealingItems,
    required LevelUpMode levelUpMode,
  }) async {
    currentLevelUpMode = levelUpMode;
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
          _finishWave(levelUpMode);
          notify();
          continue;
        }

        if (availableHeroes.isEmpty) {
          selectedHero = null;
          selectedTarget = null;
          await mobTurn(pause: pause, notify: notify);
          if (pendingLevelUps.isNotEmpty) {
            autoAttackEnabled = false;
          }
          continue;
        }

        final hero = _nextAutoHero();
        final target = _autoTargetFor(hero);
        if (target == null) break;

        selectedHero = hero;
        selectedTarget = _autoVisualTargetFor(
          hero,
          target,
          useSkills: useSkills,
        );
        actionMode = ActionMode.attack;
        notify();
        await pause();

        if (!autoAttackEnabled || gameOver) break;

        applyEffectsOnTurnStart(hero);
        if (useHealingItems) {
          useAutoHealingItems();
        }
        if (hero.isAlive && target.isAlive) {
          _performAutoHeroAction(
            hero,
            target,
            useSkills: useSkills,
            levelUpMode: levelUpMode,
          );
        }
        actedHeroes.add(hero);
        if (pendingLevelUps.isNotEmpty) {
          autoAttackEnabled = false;
        }
        selectedTarget = null;
        if (useHealingItems) {
          useAutoHealingItems();
        }
        notify();
      }
    } finally {
      isAutoAttackRunning = false;
      if (gameOver) {
        autoAttackEnabled = false;
      }
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

  void stopAutoAttack() {
    autoAttackEnabled = false;
    resumeAutoAttackAfterMerchant = false;
  }

  @override
  void basicAttack(Fighter attacker, Fighter target, {double modifier = 1}) {
    if (!attacker.isAlive || !target.isAlive) return;
    var damageModifier = modifier;
    if (random.nextInt(GameBalance.criticalHitChanceDivisor) == 0) {
      damageModifier *= GameBalance.criticalHitModifier;
      addLog('Critical hit: ${attacker.name}');
    }
    final damage = computeAttackDamage(
      attacker,
      target,
      modifier: damageModifier,
    );
    final dealt = target.takeDamage(damage);
    addLog('${attacker.name} attacks ${target.name} for ${fmt(dealt)} dmg');
    if (!target.isAlive) {
      addLog('${target.name} is defeated');
      if (attacker.isHero && target.value > 0) {
        rewardMobKill(attacker, target);
      }
    }
  }

  void rewardDefeatedMobs(Fighter attacker) {
    if (!attacker.isHero) return;
    for (final mob in mobs.members.where(
      (mob) => !mob.isAlive && mob.value > 0,
    )) {
      rewardMobKill(attacker, mob);
    }
  }

  void rewardMobKill(Fighter attacker, Fighter mob) {
    if (rewardedMobs.contains(mob)) return;
    rewardedMobs.add(mob);
    final droppedGold = mob.value * GameBalance.goldPerMobValue;
    gold += droppedGold;
    addLog('${mob.name} drops $droppedGold gold');
    gainXp(
      attacker,
      (mob.value / GameBalance.killXpDivisor).ceil(),
      currentLevelUpMode,
    );
  }

  double computeAttackDamage(
    Fighter attacker,
    Fighter target, {
    double modifier = 1,
  }) {
    return max(
      GameBalance.minimumDamage,
      attacker.attackPower * modifier - target.defence,
    );
  }

  double computeDamagePreview(
    Fighter attacker,
    Fighter target, {
    double modifier = 1,
  }) {
    return min(
      target.hp,
      computeAttackDamage(attacker, target, modifier: modifier),
    );
  }

  @override
  void addLog(String message) {
    log.insert(0, message);
    if (devMode) {
      developer.log(message, name: 'BattleLog');
    }
    if (log.length > GameBalance.maxLogEntries) {
      log.removeLast();
    }
  }

  void applyEffectsOnTurnStart(Fighter fighter) {
    final effects = fighter.effects
        .where((effect) => effect.kind == EffectKind.recurrent)
        .toList();
    for (final effect in effects) {
      final dealt = fighter.takeDamage(effect.damage);
      addLog('${effect.name} hits ${fighter.name} for ${fmt(dealt)}');
      effect.duration--;
    }
    fighter.effects.removeWhere((effect) => effect.duration <= 0);
  }

  void removeBuffs(Team team) {
    for (final fighter in team.alive) {
      for (final effect in fighter.effects.where(
        (e) => e.kind == EffectKind.buff,
      )) {
        effect.duration--;
      }
      fighter.effects.removeWhere((effect) => effect.duration <= 0);
    }
  }

  Future<void> mobTurn({
    required Future<void> Function() pause,
    required void Function() notify,
  }) async {
    isAnimating = true;
    selectedHero = null;
    selectedTarget = null;
    notify();

    for (final mob in mobs.alive) {
      if (heroes.isDefeated) break;
      applyEffectsOnTurnStart(mob);
      if (!mob.isAlive) continue;

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
      gameOver = true;
      autoAttackEnabled = false;
      gems += max(1, waveCounter ~/ GameBalance.finalThemeWaveRewardMultiplier);
      addLog('Game over at wave $waveCounter');
      notify();
      return;
    }
    _startHeroPhase();
    notify();
  }

  int useAutoHealingItems() {
    var used = 0;
    if (_shouldUseTeamPotionAutomatically()) {
      if (useTeamPotion()) used++;
    }
    for (final hero in heroes.alive) {
      if (healingPotionStock <= 0) break;
      if (_needsAutoHealing(hero) && useHealingPotion(hero)) {
        used++;
      }
    }
    return used;
  }

  bool _shouldUseTeamPotionAutomatically() {
    final aliveHeroes = heroes.alive;
    if (aliveHeroes.length <= 1 || teamPotionStock <= 0) return false;
    return aliveHeroes.every(_needsAutoHealing);
  }

  bool _needsAutoHealing(Fighter hero) {
    return hero.isAlive && hero.hp <= hero.maxHp * .25 && hero.hp < hero.maxHp;
  }

  void gainXp(Fighter hero, int xp, LevelUpMode levelUpMode) {
    hero.xp += xp;
    addLog('${hero.name} gains $xp xp');
    while (hero.xp >= xpCap(hero.level)) {
      hero.xp -= xpCap(hero.level);
      hero.level++;
      addLog('${hero.name} reaches level ${hero.level}');
      if (levelUpMode == LevelUpMode.manual) {
        pendingLevelUps.add(PendingLevelUp(hero));
        autoAttackEnabled = false;
      } else {
        applyLevelUpBonus(hero, chooseLevelUpStat(hero, levelUpMode));
      }
    }
  }

  LevelUpStat chooseLevelUpStat(Fighter hero, LevelUpMode mode) {
    return switch (mode) {
      LevelUpMode.manual => LevelUpStat.maxHp,
      LevelUpMode.random =>
        LevelUpStat.values[random.nextInt(LevelUpStat.values.length)],
      LevelUpMode.strongest => LevelUpStat.values.reduce(
        (best, stat) =>
            stat.currentValue(hero) > best.currentValue(hero) ? stat : best,
      ),
      LevelUpMode.balanced => LevelUpStat.values.reduce((best, stat) {
        final bestRatio = best.currentValue(hero) / best.baseValue(hero);
        final statRatio = stat.currentValue(hero) / stat.baseValue(hero);
        return statRatio < bestRatio ? stat : best;
      }),
    };
  }

  double levelUpIncreaseFor(Fighter hero, LevelUpStat stat) {
    return levelIncrease(stat.currentValue(hero));
  }

  void applyLevelUpBonus(Fighter hero, LevelUpStat stat) {
    final increase = levelUpIncreaseFor(hero, stat);
    switch (stat) {
      case LevelUpStat.maxHp:
        hero.maxHp += increase;
      case LevelUpStat.attack:
        hero.attackPower += increase;
      case LevelUpStat.defence:
        hero.baseDefence += increase;
    }
    hero.hp = hero.maxHp;
    addLog('${hero.name} gains +${fmt(increase)} ${stat.label}');
  }

  void resolvePendingLevelUp(PendingLevelUp pending, LevelUpStat stat) {
    pendingLevelUps.remove(pending);
    applyLevelUpBonus(pending.hero, stat);
  }

  int xpCap(int level) {
    var cap = GameBalance.baseXpCap;
    for (var i = 1; i < level; i++) {
      cap *=
          GameBalance.xpCapBaseMultiplier +
          GameBalance.xpCapCurveMultiplier *
              exp(-GameBalance.xpCapSlopeModifier * i);
    }
    return cap.round();
  }

  List<Fighter> resolveManualTargets(Fighter caster, Skill skill) {
    return switch (skill.targetType) {
      TargetType.self => [caster],
      TargetType.allySingle => [selectedTarget ?? heroes.alive.first],
      TargetType.allySingleLowestHp => [lowestHp(heroes.alive)],
      TargetType.allyTeam => heroes.alive,
      TargetType.enemySingle => [
        selectedTarget ?? _autoTargetFor(caster) ?? mobs.alive.first,
      ],
      TargetType.enemySingleHighestHp => [highestHp(mobs.alive)],
      TargetType.enemyMultiTarget => mobs.alive.take(3).toList(),
      TargetType.enemyTeam => mobs.alive,
    };
  }

  Future<void> _afterHeroActed({
    required Future<void> Function() pause,
    required void Function() notify,
    required LevelUpMode levelUpMode,
  }) async {
    selectedTarget = null;
    actionMode = ActionMode.attack;

    if (mobs.isDefeated) {
      _finishWave(levelUpMode);
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

  Fighter _nextAutoHero() {
    final ordered = [...availableHeroes];
    ordered.sort((a, b) {
      final aDamage = _bestDamageAgainstAliveMob(a);
      final bDamage = _bestDamageAgainstAliveMob(b);
      return bDamage.compareTo(aDamage);
    });
    return ordered.first;
  }

  Fighter? _autoTargetFor(Fighter hero) {
    final aliveMobs = mobs.alive;
    if (aliveMobs.isEmpty) return null;
    final killable =
        aliveMobs
            .where((mob) => computeAttackDamage(hero, mob) >= mob.hp)
            .toList()
          ..sort((a, b) => b.hp.compareTo(a.hp));
    if (killable.isNotEmpty) return killable.first;

    final byHp = [...aliveMobs]..sort((a, b) => b.hp.compareTo(a.hp));
    return byHp.first;
  }

  Fighter _autoVisualTargetFor(
    Fighter hero,
    Fighter attackTarget, {
    required bool useSkills,
  }) {
    final skill = hero.skill;
    if (!useSkills || skill == null || !skill.isReady) return attackTarget;
    final targets = autoTargetsForSkill(hero, skill, heroes, mobs);
    if (targets.isEmpty) return attackTarget;
    return targets.first;
  }

  double _bestDamageAgainstAliveMob(Fighter hero) {
    if (mobs.alive.isEmpty) return 0;
    return mobs.alive.map((mob) => computeDamagePreview(hero, mob)).reduce(max);
  }

  void _performAutoHeroAction(
    Fighter hero,
    Fighter target, {
    required bool useSkills,
    required LevelUpMode levelUpMode,
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

  void _finishWave(LevelUpMode levelUpMode) {
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
    _startNextWave();
  }

  void continueAfterMerchant() {
    if (!merchantAvailable) return;
    merchantAvailable = false;
    autoAttackEnabled = resumeAutoAttackAfterMerchant;
    resumeAutoAttackAfterMerchant = false;
    _startNextWave();
  }

  int autoBuyHealingItems() {
    if (!merchantAvailable) return 0;
    var bought = 0;
    if (_shouldBuyTeamPotionAutomatically() && buyTeamPotionStock()) {
      bought++;
    }
    while (buySinglePotionStock()) {
      bought++;
    }
    return bought;
  }

  bool _shouldBuyTeamPotionAutomatically() {
    final aliveHeroes = heroes.alive;
    return aliveHeroes.length > 1 &&
        aliveHeroes.every((hero) => hero.hp < hero.maxHp) &&
        gold >= GameBalance.teamPotionCost;
  }

  bool buySinglePotion(Fighter hero) {
    if (!merchantAvailable ||
        !hero.isAlive ||
        hero.hp >= hero.maxHp ||
        gold < GameBalance.singlePotionCost) {
      return false;
    }
    gold -= GameBalance.singlePotionCost;
    healingPotionStock++;
    addLog('Bought healing potion');
    return useHealingPotion(hero);
  }

  bool buySinglePotionStock() {
    if (!merchantAvailable || gold < GameBalance.singlePotionCost) return false;
    gold -= GameBalance.singlePotionCost;
    healingPotionStock++;
    addLog('Stored healing potion');
    return true;
  }

  bool useHealingPotion(Fighter hero) {
    if (!hero.isAlive || hero.hp >= hero.maxHp || healingPotionStock <= 0) {
      return false;
    }
    healingPotionStock--;
    final healed = hero.heal(hero.maxHp * GameBalance.singlePotionHealRatio);
    addLog('Healing potion on ${hero.name}: +${fmt(healed)} HP');
    return true;
  }

  bool buyTeamPotion() {
    if (!merchantAvailable ||
        !hasInjuredHero ||
        gold < GameBalance.teamPotionCost) {
      return false;
    }
    gold -= GameBalance.teamPotionCost;
    teamPotionStock++;
    addLog('Bought team potion');
    return useTeamPotion();
  }

  bool buyTeamPotionStock() {
    if (!merchantAvailable || gold < GameBalance.teamPotionCost) return false;
    gold -= GameBalance.teamPotionCost;
    teamPotionStock++;
    addLog('Stored team potion');
    return true;
  }

  bool useTeamPotion() {
    if (teamPotionStock <= 0 || !hasInjuredHero) return false;
    teamPotionStock--;
    for (final hero in heroes.alive) {
      hero.heal(hero.maxHp * GameBalance.teamPotionHealRatio);
    }
    addLog('Team potion used');
    return true;
  }

  bool buyXpPotion(
    Fighter hero, {
    required int xp,
    required int cost,
    required String label,
  }) {
    if (!merchantAvailable || !hero.isAlive || gold < cost) return false;
    gold -= cost;
    gainXp(hero, xp, currentLevelUpMode);
    addLog('$label used on ${hero.name}');
    return true;
  }

  bool buySpecialPotionStock() {
    if (!merchantAvailable || gold < GameBalance.specialPotionCost) {
      return false;
    }
    gold -= GameBalance.specialPotionCost;
    specialPotionStock++;
    addLog('Stored special potion');
    return true;
  }

  bool buySpecialPotion(Fighter hero) {
    final skill = hero.skill;
    if (!hero.isAlive || skill == null || skill.charge >= skill.maxCharge) {
      return false;
    }
    if (!buySpecialPotionStock()) return false;
    return useSpecialPotion(hero);
  }

  bool useSpecialPotion(Fighter hero) {
    final skill = hero.skill;
    if (!hero.isAlive ||
        skill == null ||
        skill.charge >= skill.maxCharge ||
        specialPotionStock <= 0) {
      return false;
    }
    specialPotionStock--;
    skill.fullyRecharge();
    actionMode = selectedHero?.skill?.isReady == true
        ? ActionMode.skill
        : ActionMode.attack;
    addLog('Special potion recharges ${hero.name}');
    return true;
  }

  bool buySpecialBarUpgrade(Fighter hero) {
    final skill = hero.skill;
    if (!merchantAvailable ||
        !hero.isAlive ||
        skill == null ||
        gold < GameBalance.specialBarUpgradeCost) {
      return false;
    }
    gold -= GameBalance.specialBarUpgradeCost;
    skill.chargeBars++;
    addLog('${hero.name} gains a special charge bar');
    return true;
  }

  void _startNextWave() {
    waveCounter++;
    roundCounter = 1;
    rewardedMobs.clear();
    waveInfo = waveGenerator.generate(
      waveCounter + GameBalance.waveValueOffset,
    );
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

  bool _targetTypeNeedsNoManualTarget() {
    final skill = selectedHero?.skill;
    if (actionMode == ActionMode.attack || skill == null) return false;
    return switch (skill.targetType) {
      TargetType.self ||
      TargetType.allySingleLowestHp ||
      TargetType.allyTeam ||
      TargetType.enemySingleHighestHp ||
      TargetType.enemyMultiTarget ||
      TargetType.enemyTeam => true,
      TargetType.allySingle || TargetType.enemySingle => false,
    };
  }
}
