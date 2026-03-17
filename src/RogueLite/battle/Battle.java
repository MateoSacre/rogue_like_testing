package RogueLite.battle;

import RogueLite.characters.Character;
import RogueLite.characters.skills.TargetType;
import RogueLite.statuseffect.EffectActivation;
import RogueLite.statuseffect.EffectType;
import RogueLite.statuseffect.StatusEffect;
import RogueLite.teams.Team;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class Battle {

  public static Team fight(Team team1, Team team2) {
    if (team1 == (null) || team2 == (null)) {
      throw new IllegalArgumentException("Teams cannot be null");
    }
    System.out.println("Battle: " + team1.getName() + " vs " + team2.getName());
    System.out.println();
    printTeam("TEAM A", team1);
    printTeam("TEAM B", team2);
    System.out.println();

    int roundIndex = 1;
    while (true) {
      System.out.println("-- Round " + roundIndex + "--");
      attackTeam(team1, team2);
      attackTeam(team2, team1);
      removeBuffs(team1);
      removeBuffs(team2);
      if (team1.isDefeated()) {
        return team2;
      } else if (team2.isDefeated()) {
        return team1;
      }
      roundIndex++;
    }
  }

  private static void removeBuffs(Team<? extends Character> team) {
    for (Character c : team.getAliveMembers()) {
      for (StatusEffect s :
          c.getStatusEffects().stream().filter(s -> s.getType().equals(EffectType.BUFF)).toList()) {
        s.tick();
      }
      c.removeEffectsIfNeeded();
    }
  }

  private static void printTeam(String label, Team<? extends Character> team) {
    System.out.println(
        "[" + label + "] " + team.getName() + " | alive=" + team.livingCount() + "/" + team.size());

    for (Character c : team.getMembers()) {
      System.out.println("  - " + c);
    }
  }

  private static void attackTeam(
      Team<? extends Character> attacker, Team<? extends Character> defender) {
    for (Character c : attacker.getAliveMembers()) {
      if (defender.isDefeated()) return;

      applyEffectsOnTurnStart(c);

      Character target = defender.pickFirstAlive();

      if (c.canUseSkill()) {
        List<Character> targets = getTargetsForSkill(c, attacker, defender);
        if (c.getSkill().shouldUse(c, targets)) {
          c.useSkill(targets);
          c.initiateSkillCooldown();
          continue;
        }
        c.applySkillCooldown();
      }

      double damages = c.attack(target);
      System.out.println(
          c.getName() + " attacks " + target.getName() + " for " + damages + " dmg " + target);
      c.applySkillCooldown();
    }
  }

  private static void applyEffectsOnTurnStart(Character character) {
    for (StatusEffect statusEffect :
        character.getStatusEffects().stream()
            .filter(
                se ->
                    se.getActivation().equals(EffectActivation.EVERY_TURN)
                        && se.getType().equals(EffectType.RECURRENT))
            .toList()) {
      statusEffect.applyEffect(character);
      statusEffect.tick();
    }
    character.removeEffectsIfNeeded();
  }

  private static List<Character> getTargetsForSkill(
      Character c, Team<? extends Character> attacker, Team<? extends Character> defender) {
    switch (c.getSkill().getTargetType()) {
      case SELF:
        return List.of(c);

      case ALLY_SINGLE:
        return List.of(Objects.requireNonNull(pickFirstAliveExcluding(attacker, c)));

      case ALLY_SINGLE_LOWEST_HP:
        if (attacker.getAliveMembers().size() == 1) {
          return List.of(attacker.pickFirstAlive());
        }
        return List.of(
            Objects.requireNonNull(
                attacker.getAliveMembers().stream()
                    .map(Character.class::cast)
                    .filter(x -> x != c)
                    .min(Comparator.comparingDouble(x -> x.getHp() / x.getMaxHp()))
                    .orElseGet(() -> pickFirstAliveExcluding(attacker, c))));

      case ALLY_SINGLE_HIGHEST_HP:
        return List.of(
            Objects.requireNonNull(
                attacker.getAliveMembers().stream()
                    .map(Character.class::cast)
                    .filter(x -> x != c)
                    .max(Comparator.comparingDouble(x -> x.getHp() / x.getMaxHp()))
                    .orElseGet(() -> pickFirstAliveExcluding(attacker, c))));

      case ALLY_MULTI_TARGET:
      case ALLY_TEAM:
        return new ArrayList<>(attacker.getAliveMembers());

      case ENNEMY_SINGLE:
        return List.of(defender.pickFirstAlive());

      case ENNEMY_SINGLE_LOWEST_HP:
        return List.of(
            Objects.requireNonNull(
                defender.getAliveMembers().stream()
                    .map(Character.class::cast)
                    .filter(x -> x != c)
                    .min(Comparator.comparingDouble(x -> x.getHp() / x.getMaxHp()))
                    .orElseGet(() -> pickFirstAliveExcluding(defender, c))));

      case ENNEMY_SINGLE_HIGHEST_HP:
        return List.of(
            Objects.requireNonNull(
                defender.getAliveMembers().stream()
                    .map(Character.class::cast)
                    .filter(x -> x != c)
                    .max(Comparator.comparingDouble(x -> x.getHp() / x.getMaxHp()))
                    .orElseGet(() -> pickFirstAliveExcluding(defender, c))));

      case ENNEMY_MULTI_TARGET:
      case ENNEMY_TEAM:
        return new ArrayList<>(defender.getAliveMembers());

      case ALL:
        List<Character> all = new ArrayList<>();
        all.addAll(attacker.getAliveMembers());
        all.addAll(defender.getAliveMembers());
        return List.copyOf(all);

      default:
        throw new IllegalArgumentException(
            "Invalid target type [" + c.getSkill().getTargetType() + "] should not exist");
    }
  }

  private static Character pickFirstAliveExcluding(
      Team<? extends Character> team, Character exclude) {
    for (Character x : team.getAliveMembers()) {
      if (x != null && x != exclude) {
        return x;
      }
    }
    return null;
  }
}
