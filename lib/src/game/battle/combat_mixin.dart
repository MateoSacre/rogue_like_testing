import 'dart:developer' as developer;
import 'dart:math' hide log;

import '../../models/enums.dart';
import '../../models/fighter.dart';
import '../../models/status_effect.dart';
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

  /// Guards the double-strike proc so an extra attack cannot chain another.
  bool _extraAttackInProgress = false;

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
    if (attacker.isHero && dealt > 0) {
      _applyItemProcs(attacker, target, dealt);
    }
    if (!target.isAlive) {
      addLog('${target.name} is defeated');
      if (attacker.isHero && target.value > 0) rewardMobKill(attacker, target);
    }
    _maybeExtraAttack(attacker, target, modifier);
  }

  @override
  double skillDamage(Fighter attacker, Fighter target, double amount) {
    final dealt = target.takeDamage(amount);
    if (attacker.isHero && dealt > 0) {
      _applyItemProcs(attacker, target, dealt);
    }
    return dealt;
  }

  void _applyItemProcs(Fighter attacker, Fighter target, double dealt) {
    final steal = attacker.lifesteal;
    if (steal > 0) {
      final healed = attacker.heal(dealt * steal);
      if (healed > 0) {
        addLog('${attacker.name} drains ${fmt(healed)} hp');
      }
    }
    if (!target.isAlive) return;
    for (final onHit in attacker.onHitEffects) {
      if (random.nextDouble() >= onHit.chance) continue;
      final alreadyAffected = target.effects.any(
        (effect) => effect.name == onHit.name,
      );
      if (alreadyAffected) continue;
      target.effects.add(
        StatusEffect(
          name: onHit.name,
          kind: EffectKind.recurrent,
          duration: onHit.duration,
          damage: onHit.damage,
        ),
      );
      addLog('${target.name} suffers ${onHit.name}');
    }
  }

  void _maybeExtraAttack(Fighter attacker, Fighter target, double modifier) {
    if (_extraAttackInProgress ||
        !attacker.isHero ||
        !attacker.isAlive ||
        !target.isAlive) {
      return;
    }
    final chance = attacker.extraAttackChance;
    if (chance <= 0 || random.nextDouble() >= chance) return;
    _extraAttackInProgress = true;
    addLog('${attacker.name} strikes again');
    basicAttack(attacker, target, modifier: modifier);
    _extraAttackInProgress = false;
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
    rollItemDrop(mob);
  }

  /// Rewards a mob killed by a damage-over-time tick (no direct attacker):
  /// the kill credit goes to a random living hero.
  @override
  void rewardDotKill(Fighter mob) {
    final alive = heroes.alive;
    if (alive.isEmpty || mob.value <= 0) return;
    addLog('${mob.name} succumbs to its wounds');
    rewardMobKill(alive[random.nextInt(alive.length)], mob);
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
