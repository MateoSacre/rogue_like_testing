import 'fighter.dart';

abstract interface class BattleActions {
  void addLog(String message);

  void basicAttack(Fighter attacker, Fighter target, {double modifier = 1});
}
