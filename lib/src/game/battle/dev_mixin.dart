import '../../models/fighter.dart';
import '../../models/status_effect.dart';
import 'battle_state.dart';

/// Dev-mode tools: instant gold/gems injection, effect application,
/// and forced merchant opening. All methods are no-ops when [devMode] is false.
mixin DevMixin on BattleControllerBase {
  void devAddGold([int amount = 9999]) {
    if (!devMode || amount <= 0) return;
    gold += amount;
    addLog('Dev mode: +$amount gold');
  }

  void devAddGems([int amount = 999]) {
    if (!devMode || amount <= 0) return;
    gems += amount;
    addLog('Dev mode: +$amount gems');
  }

  void devApplyEffect(Fighter target, StatusEffect effect) {
    if (!devMode || !allFighters.contains(target)) return;
    target.effects.removeWhere((e) => e.name == effect.name);
    target.effects.add(effect.copy());
    addLog('Dev mode: ${effect.name} applied to ${target.name}');
  }

  void devOpenMerchant() {
    if (!devMode || gameOver || isAnimating) return;
    stopAutoAttack();
    merchantAvailable = true;
    selectedHero = null;
    selectedTarget = null;
    activeMob = null;
    activeMobTarget = null;
    addLog('Dev mode: merchant opened');
  }
}
