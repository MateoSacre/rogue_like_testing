import '../../models/fighter.dart';
import '../game_balance.dart';
import 'battle_state.dart';

/// XP gain and the single persistent level. There is no stat-allocation
/// choice anymore: every level multiplies all base stats by a degressive
/// bonus. The level carries across runs (synced into PlayerProgress by the UI).
mixin LevelingMixin on BattleControllerBase {
  @override
  void gainXp(Fighter hero, int xp) {
    if (xp <= 0 || hero.level >= GameBalance.maxHeroLevel) return;
    hero.xp += xp;
    addLog('${hero.name} gains $xp xp');
    while (hero.level < GameBalance.maxHeroLevel && hero.xp >= hero.xpCap) {
      hero.xp -= hero.xpCap;
      hero.level++;
      _applyLevelGrowth(hero);
      addLog('${hero.name} reaches level ${hero.level}');
    }
    if (hero.level >= GameBalance.maxHeroLevel) hero.xp = 0;
  }

  /// Adds the level's degressive stat increment on top of current stats,
  /// so item bonuses already baked in are preserved.
  void _applyLevelGrowth(Fighter hero) {
    final delta =
        GameBalance.statBonusForLevel(hero.level) -
        GameBalance.statBonusForLevel(hero.level - 1);
    hero.maxHp += hero.initialMaxHp * delta;
    hero.attackPower += hero.initialAttackPower * delta;
    hero.baseDefence += hero.initialBaseDefence * delta;
    hero.hp = hero.maxHp;
  }
}
