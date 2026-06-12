import 'fighter.dart';

abstract interface class BattleActions {
  void addLog(String message);

  void basicAttack(Fighter attacker, Fighter target, {double modifier = 1});

  /// Damage [attacker] would deal to [target] with [modifier], capped at the
  /// target's current HP. Used by skill preview builders.
  double computeDamagePreview(
    Fighter attacker,
    Fighter target, {
    double modifier = 1,
  });
}
