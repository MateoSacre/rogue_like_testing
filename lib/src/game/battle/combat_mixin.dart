import 'dart:developer' as developer;
import 'dart:math' hide log;

import '../../models/enums.dart';
import '../../models/fighter.dart';
import '../../models/team.dart';
import '../../utils/format.dart';
import '../game_balance.dart';
import 'battle_state.dart';

/// Handles damage computation, status-effect ticks, kill rewards,
/// and the combat log.
mixin CombatMixin on BattleControllerBase {
  // ── Logging ───────────────────────────────────────────────────────────────

  @override
  void addLog(String message) {
    log.insert(0, message);
    if (devMode) developer.log(message, name: 'BattleLog');
    if (log.length > GameBalance.maxLogEntries) log.removeLast();
  }

  // ── Attacks ───────────────────────────────────────────────────────────────

  @override
  void basicAttack(Fighter attacker, Fighter target, {double modifier = 1}) {
    if (!attacker.isAlive || !target.isAlive) return;
    var damageModifier = modifier;
    if (random.nextInt(GameBalance.criticalHitChanceDivisor) == 0) {
      damageModifier *= GameBalance.criticalHitModifier;
      addLog('Critical hit: ${attacker.name}');
    }
    final damage = computeAttackDamage(attacker, target, modifier: damageModifier);
    final dealt = target.takeDamage(damage);
    addLog('${attacker.name} attacks ${target.name} for ${fmt(dealt)} dmg');
    if (!target.isAlive) {
      addLog('${target.name} is defeated');
      if (attacker.isHero && target.value > 0) rewardMobKill(attacker, target);
    }
  }

  // ── Damage helpers ────────────────────────────────────────────────────────

  @override
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

  @override
  double computeDamagePreview(
    Fighter attacker,
    Fighter target, {
    double modifier = 1,
  }) {
    return min(target.hp, computeAttackDamage(attacker, target, modifier: modifier));
  }

  // ── Kill rewards ──────────────────────────────────────────────────────────

  @override
  void rewardDefeatedMobs(Fighter attacker) {
    if (!attacker.isHero) return;
    for (final mob in mobs.members.where((m) => !m.isAlive && m.value > 0)) {
      rewardMobKill(attacker, mob);
    }
  }

  void rewardMobKill(Fighter attacker, Fighter mob) {
    if (rewardedMobs.contains(mob)) return;
    rewardedMobs.add(mob);
    final droppedGold = mob.value * GameBalance.goldPerMobValue;
    gold += droppedGold;
    addLog('${mob.name} drops $droppedGold gold');
    gainXp(attacker, (mob.value / GameBalance.killXpDivisor).ceil(), currentLevelUpMode);
  }

  // ── Status effects ────────────────────────────────────────────────────────

  @override
  void applyEffectsOnTurnStart(Fighter fighter) {
    final recurrent = fighter.effects
        .where((e) => e.kind == EffectKind.recurrent)
        .toList();
    for (final effect in recurrent) {
      final dealt = fighter.takeDamage(effect.damage);
      addLog('${effect.name} hits ${fighter.name} for ${fmt(dealt)}');
      effect.duration--;
    }
    fighter.effects.removeWhere((e) => e.duration <= 0);
  }

  @override
  void removeBuffs(Team team) {
    for (final fighter in team.alive) {
      for (final effect in fighter.effects.where((e) => e.kind == EffectKind.buff)) {
        effect.duration--;
      }
      fighter.effects.removeWhere((e) => e.duration <= 0);
    }
  }
}
