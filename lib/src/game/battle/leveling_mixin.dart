import 'dart:math';

import '../../models/fighter.dart';
import '../../models/level_up_stat.dart';
import '../../settings/game_settings.dart';
import '../../utils/format.dart';
import '../../data/skills.dart';
import '../game_balance.dart';
import 'battle_state.dart';

/// Manages XP gain, level-up stat choices, and applying level bonuses.
mixin LevelingMixin on BattleControllerBase {
  // ── XP ────────────────────────────────────────────────────────────────────

  @override
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

  // ── Level-up stat selection ───────────────────────────────────────────────

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

  // ── Level-up application ──────────────────────────────────────────────────

  double levelUpIncreaseFor(Fighter hero, LevelUpStat stat) =>
      levelIncrease(stat.currentValue(hero));

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
}
