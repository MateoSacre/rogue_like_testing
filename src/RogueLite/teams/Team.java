package RogueLite.teams;

import RogueLite.characters.Character;
import java.util.List;

public interface Team<T extends Character> {
  String getName();

  List<T> getMembers();

  List<T> getAliveMembers();

  T pickFirstAlive();

  T pickFirstAlive(T exclude);

  int livingCount();

  int size();

  boolean isDefeated();
}