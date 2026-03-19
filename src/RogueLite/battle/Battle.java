package RogueLite.battle;

import RogueLite.Debug;
import RogueLite.characters.Character;
import RogueLite.characters.mobs.Mob;
import RogueLite.characters.mobs.MobAiType;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import RogueLite.statuseffect.EffectActivation;
import RogueLite.statuseffect.EffectType;
import RogueLite.statuseffect.StatusEffect;
import RogueLite.teams.Team;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Random;
import java.util.Scanner;

public class Battle {

  private static final Random random = new Random();
  private static final Scanner scanner = new Scanner(System.in);

  public static Team fight(Team team1, Team team2) {
    return fight(team1, team2, false);
  }

  public static Team fight(Team team1, Team team2, boolean manualTeam1) {
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
      attackTeam(team1, team2, manualTeam1);
      attackTeam(team2, team1, false);
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

  private static void printAvailableCharacters(String label, List<? extends Character> characters) {
    System.out.println(label + ":");
    for (int i = 0; i < characters.size(); i++) {
      System.out.println("  " + (i + 1) + ". " + describeCharacterForSelection(characters.get(i)));
    }
  }

  private static void attackTeam(
      Team<? extends Character> attacker,
      Team<? extends Character> defender,
      boolean manualControl) {
    if (manualControl) {
      handleManualTurn(attacker, defender);
      return;
    }

    for (Character c : attacker.getAliveMembers()) {
      if (defender.isDefeated()) return;

      applyEffectsOnTurnStart(c);

      Character target = pickAttackTarget(c, defender);
      if (c instanceof Mob mob) {
        Debug.log("Battle", mob.getName() + " basic target=" + target.getName() + " ai=" + mob.getAiType());
      }

      if (c.canUseSkill()) {
        List<Character> targets = getTargetsForSkill(c, attacker, defender);
        if (c instanceof Mob mob) {
          Debug.log("Battle", mob.getName() + " skill targets=" + targets.stream().map(Character::getName).toList() + " ai=" + mob.getAiType());
        }
        if (c.getSkill().shouldUse(c, targets)) {
          c.useSkill(targets);
          c.initiateSkillCooldown();
          continue;
        }
        c.applySkillCooldown();
      }

      double damages = c.attack(target);
      if(c instanceof Mob){
        System.out.println(
            c.getName() + "["+((Mob) c).getAiType()+"]" + " attacks " + target.getName() + " for " + damages + " dmg " + target);
      }else{
        System.out.println(
            c.getName() + " attacks " + target.getName() + " for " + damages + " dmg " + target);
      }
      c.applySkillCooldown();
    }
  }

  private static void handleManualTurn(
      Team<? extends Character> attacker, Team<? extends Character> defender) {
    List<Character> availableAttackers =
        new ArrayList<>(attacker.getAliveMembers().stream().map(Character.class::cast).toList());

    while (!availableAttackers.isEmpty() && !defender.isDefeated()) {
      printAvailableCharacters("Heroes ready", availableAttackers);
      Character actingHero =
          availableAttackers.get(
              readChoice("Choose a hero to act", availableAttackers.size()) - 1);

      applyEffectsOnTurnStart(actingHero);
      if (!actingHero.isAlive()) {
        System.out.println(actingHero.getName() + " can no longer act.");
        availableAttackers.remove(actingHero);
        continue;
      }

      List<? extends Character> availableTargets = defender.getAliveMembers();
      int action = readHeroAction(actingHero);
      if (action == 2) {
        List<Character> skillTargets = getManualTargetsForSkill(actingHero, attacker, defender);
        Debug.log(
            "Battle",
            "Player selected "
                + actingHero.getName()
                + " -> skill "
                + actingHero.getSkill().getName()
                + " on "
                + skillTargets.stream().map(Character::getName).toList());
        actingHero.useSkill(skillTargets);
        actingHero.initiateSkillCooldown();
      } else {
        printAvailableCharacters("Targets", availableTargets);
        Character target =
            availableTargets.get(readChoice("Choose a target", availableTargets.size()) - 1);

        Debug.log("Battle", "Player selected " + actingHero.getName() + " -> " + target.getName());
        double damages = actingHero.attack(target);
        System.out.println(
            actingHero.getName() + " attacks " + target.getName() + " for " + damages + " dmg " + target);
      }
      actingHero.applySkillCooldown();
      availableAttackers.remove(actingHero);
    }
  }

  private static String describeCharacterForSelection(Character character) {
    Skill skill = character.getSkill();
    if (skill == null) {
      return character.toString() + " | Skill: none";
    }
    return character.toString() + " | Skill: " + formatSkillStatus(skill);
  }

  private static String formatSkillStatus(Skill skill) {
    if (skill.getCooldownRemaining() == 0) {
      return skill.getName() + " [READY]";
    }
    return skill.getName()
        + " [CD "
        + skill.getCooldownRemaining()
        + "/"
        + skill.getCooldownValue()
        + "]";
  }

  private static int readHeroAction(Character hero) {
    Skill skill = hero.getSkill();
    if (skill == null) {
      System.out.println(hero.getName() + " has no skill. Basic attack only.");
      return 1;
    }
    if (!hero.canUseSkill()) {
      System.out.println(hero.getName() + " skill unavailable: " + formatSkillStatus(skill));
      return 1;
    }
    System.out.println(
        hero.getName()
            + " action: 1. Attack  2. Skill ("
            + skill.getName()
            + ", "
            + formatTargetType(skill.getTargetType())
            + ")");
    return readChoice("Choose an action", 2);
  }

  private static String formatTargetType(TargetType targetType) {
    return switch (targetType) {
      case SELF -> "self";
      case ALLY_SINGLE, ALLY_SINGLE_LOWEST_HP, ALLY_SINGLE_HIGHEST_HP -> "single ally";
      case ALLY_MULTI_TARGET, ALLY_TEAM -> "all allies";
      case ENNEMY_SINGLE, ENNEMY_SINGLE_LOWEST_HP, ENNEMY_SINGLE_HIGHEST_HP -> "single enemy";
      case ENNEMY_MULTI_TARGET, ENNEMY_TEAM -> "all enemies";
      case ALL -> "everyone";
    };
  }

  private static List<Character> getManualTargetsForSkill(
      Character caster, Team<? extends Character> attacker, Team<? extends Character> defender) {
    return switch (caster.getSkill().getTargetType()) {
      case SELF -> List.of(caster);
      case ALLY_SINGLE, ALLY_SINGLE_LOWEST_HP, ALLY_SINGLE_HIGHEST_HP ->
          List.of(selectTarget("Allies", attacker.getAliveMembers()));
      case ALLY_MULTI_TARGET, ALLY_TEAM ->
          new ArrayList<>(attacker.getAliveMembers().stream().map(Character.class::cast).toList());
      case ENNEMY_SINGLE, ENNEMY_SINGLE_LOWEST_HP, ENNEMY_SINGLE_HIGHEST_HP ->
          List.of(selectTarget("Targets", defender.getAliveMembers()));
      case ENNEMY_MULTI_TARGET, ENNEMY_TEAM ->
          new ArrayList<>(defender.getAliveMembers().stream().map(Character.class::cast).toList());
      case ALL -> {
        List<Character> allTargets = new ArrayList<>();
        allTargets.addAll(attacker.getAliveMembers().stream().map(Character.class::cast).toList());
        allTargets.addAll(defender.getAliveMembers().stream().map(Character.class::cast).toList());
        yield allTargets;
      }
    };
  }

  private static Character selectTarget(String label, List<? extends Character> availableTargets) {
    printAvailableCharacters(label, availableTargets);
    return availableTargets.get(readChoice("Choose a target", availableTargets.size()) - 1);
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
    if (c instanceof Mob mob && c.getSkill().targetsEnemies()) {
      return getEnemyTargetsForMobSkill(mob, defender);
    }

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

  private static Character pickAttackTarget(
      Character attacker, Team<? extends Character> defender) {
    if (attacker instanceof Mob mob) {
      return pickEnemyTargetsByAi(mob, defender.getAliveMembers(), 1).getFirst();
    }
    return defender.pickFirstAlive();
  }

  private static List<Character> getEnemyTargetsForMobSkill(
      Mob mob, Team<? extends Character> defender) {
    List<? extends Character> aliveDefenders = defender.getAliveMembers();
    return switch (mob.getSkill().getTargetType()) {
      case ENNEMY_SINGLE,
          ENNEMY_SINGLE_LOWEST_HP,
          ENNEMY_SINGLE_HIGHEST_HP -> pickEnemyTargetsByAi(mob, aliveDefenders, 1);
      case ENNEMY_MULTI_TARGET, ENNEMY_TEAM -> pickEnemyTargetsByAi(mob, aliveDefenders, aliveDefenders.size());
      default -> throw new IllegalArgumentException(
          "Mob AI cannot handle target type " + mob.getSkill().getTargetType());
    };
  }

  private static List<Character> pickEnemyTargetsByAi(
      Mob attacker, List<? extends Character> candidates, int maximumTargets) {
    List<Character> orderedTargets = new ArrayList<>(candidates);
    if (orderedTargets.isEmpty()) {
      return List.of();
    }

    switch (attacker.getAiType()) {
      case DUMB -> {
        // Keep battle order.
      }
      case RANDOM -> {
        List<Character> shuffledTargets = new ArrayList<>();
        while (!orderedTargets.isEmpty()) {
          shuffledTargets.add(orderedTargets.remove(random.nextInt(orderedTargets.size())));
        }
        orderedTargets = shuffledTargets;
      }
      case KILLER ->
          orderedTargets.sort(Comparator.comparingDouble(target -> target.getHp() / target.getMaxHp()));
      case DAMAGER -> orderedTargets.sort(Comparator.comparingDouble(Character::getDefence));
      case EFFECT_DEALER ->
          orderedTargets = prioritizeByEffectPresence(orderedTargets, false);
      case EFFECT_STACKER ->
          orderedTargets = prioritizeByEffectPresence(orderedTargets, true);
      default -> throw new IllegalArgumentException("Unknown AI type " + attacker.getAiType());
    }

    Debug.log(
        "Battle",
        attacker.getName() + " ai=" + attacker.getAiType() + " ordered targets="
            + orderedTargets.stream().map(Character::getName).toList());

    return List.copyOf(orderedTargets.subList(0, Math.min(maximumTargets, orderedTargets.size())));
  }

  private static List<Character> prioritizeByEffectPresence(
      List<Character> orderedTargets, boolean shouldHaveEffect) {
    List<Character> preferredTargets =
        orderedTargets.stream()
            .filter(target -> hasNegativeEffect(target) == shouldHaveEffect)
            .sorted(Comparator.comparingDouble(target -> target.getHp() / target.getMaxHp()))
            .toList();

    List<Character> fallbackTargets =
        orderedTargets.stream()
            .filter(target -> hasNegativeEffect(target) != shouldHaveEffect)
            .sorted(Comparator.comparingDouble(target -> target.getHp() / target.getMaxHp()))
            .toList();

    List<Character> prioritizedTargets = new ArrayList<>(preferredTargets);
    prioritizedTargets.addAll(fallbackTargets);
    return prioritizedTargets;
  }

  private static boolean hasNegativeEffect(Character target) {
    return target.getStatusEffects().stream().anyMatch(effect -> effect.getType() == EffectType.RECURRENT);
  }

  private static int readChoice(String prompt, int maxValue) {
    while (true) {
      System.out.print(prompt + " [1-" + maxValue + "]: ");
      String rawValue = scanner.nextLine();
      try {
        int choice = Integer.parseInt(rawValue.trim());
        if (choice >= 1 && choice <= maxValue) {
          return choice;
        }
      } catch (NumberFormatException ignored) {
        // Retry below.
      }
      System.out.println("Invalid choice. Try again.");
    }
  }
}
