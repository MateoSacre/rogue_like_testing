package RogueLite.teams;

import RogueLite.characters.mobs.Mob;

import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class MobTeam implements Team<Mob> {

  final String name;
  final List<Mob> members;

  public MobTeam(String name, List<Mob> members) {
    if (name == null || name.isBlank()) {
      throw new IllegalArgumentException("Name is null or blank");
    }
    if (members == null || members.isEmpty() || members.stream().anyMatch(Objects::isNull)) {
      throw new IllegalArgumentException("Members list is null, empty or contains a null Character");
    }
    this.name = name;
    this.members = members;
  }

  public String getName() {
    return name;
  }

  public List<Mob> getMembers() {
    return Collections.unmodifiableList(members);
  }

  public List<Mob> getAliveMembers() {
    return members.stream().filter(Mob::isAlive).collect(Collectors.toUnmodifiableList());
  }

  public Mob pickFirstAlive() {
    return members.stream().filter(Mob::isAlive).findFirst().orElse(null);
  }

  public Mob pickFirstAlive(Mob exclude) {
    return members.stream()
        .filter(Mob::isAlive)
        .filter(c -> !c.equals(exclude))
        .findFirst()
        .orElse(null);
  }

  public int livingCount() {
    return (int) members.stream().filter(Mob::isAlive).count();
  }

  public int size() {
    return members.size();
  }

  public boolean isDefeated() {
    return members.stream().noneMatch(Mob::isAlive);
  }
}