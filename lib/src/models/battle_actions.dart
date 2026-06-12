import 'fighter.dart';

abstract interface class BattleActions {
  void addLog(String message);

  void basicAttack(Fighter attacker, Fighter target, {double modifier = 1});

  /// Deals direct, defence-ignoring damage from a skill and triggers the
  /// attacker's item procs (lifesteal, on-hit effects) exactly like a basic
  /// attack — only the weapon double-strike stays exclusive to basic attacks.
  /// Returns the damage actually dealt.
  double skillDamage(Fighter attacker, Fighter target, double amount);

  /// Damage [attacker] would deal to [target] with [modifier], capped at the
  /// target's current HP. Used by skill preview builders.
  double computeDamagePreview(
    Fighter attacker,
    Fighter target, {
    double modifier = 1,
  });
}
