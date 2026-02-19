package RogueLite.teams;

import RogueLite.characters.hero.Hero;

import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class HeroTeam implements Team<Hero> {

  final String name;
  final List<Hero> members;

  public HeroTeam(String name, List<Hero> members) {
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

  public List<Hero> getMembers() {
    return Collections.unmodifiableList(members);
  }

  public List<Hero> getAliveMembers() {
    return members.stream().filter(Hero::isAlive).collect(Collectors.toUnmodifiableList());
  }

  public Hero pickFirstAlive() {
    return members.stream().filter(Hero::isAlive).findFirst().orElse(null);
  }

  public Hero pickFirstAlive(Hero exclude) {
    return members.stream()
        .filter(Hero::isAlive)
        .filter(c -> !c.equals(exclude))
        .findFirst()
        .orElse(null);
  }

  public int livingCount() {
    return (int) members.stream().filter(Hero::isAlive).count();
  }

  public int size() {
    return members.size();
  }

  public boolean isDefeated() {
    return members.stream().noneMatch(Hero::isAlive);
  }
}