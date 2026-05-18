import 'fighter.dart';

class Team {
  Team(this.name, this.members);

  final String name;
  final List<Fighter> members;

  List<Fighter> get alive {
    return members.where((fighter) => fighter.isAlive).toList();
  }

  bool get isDefeated => alive.isEmpty;
}
