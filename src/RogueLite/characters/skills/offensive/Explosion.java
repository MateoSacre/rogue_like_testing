package RogueLite.characters.skills.offensive;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class Explosion implements Skill {

  TargetType targetType = TargetType.ENNEMY_TEAM;
  String name = "Explosion";
  int cooldownValue = 5;
  int cooldownRemaining = 5;
  Integer nbTargets;
  Double explosionDamages;
  Boolean isMultiplier;

  public Explosion() {}

  public Explosion(
      TargetType targetType,
      String name,
      int cooldownValue,
      Integer nbTargets,
      Double explosionDamages,
      Boolean isMultiplier) {
    this.targetType = targetType;
    this.name = name;
    this.cooldownValue = cooldownValue;
    this.cooldownRemaining = cooldownValue;
    this.nbTargets = nbTargets;
    this.explosionDamages = explosionDamages;
    this.isMultiplier = isMultiplier;
  }

  public String getName() {
    return name;
  }

  public int getCooldownValue() {
    return cooldownValue;
  }

  public int getCooldownRemaining() {
    return cooldownRemaining;
  }

  public TargetType getTargetType() {
    return targetType;
  }

  public void initiateCooldown() {
    cooldownRemaining = cooldownValue;
  }

  @Override
  public void applySkillCooldown() {
    if (cooldownRemaining > 0) {
      cooldownRemaining--;
    }
  }

  @Override
  public boolean shouldUse(Character caster, List<Character> targets) {
    return targets.size() > 1;
  }

  @Override
  public void use(Character caster, List<Character> targets) {
    List<Character> trueTargets = new ArrayList<>();
    if (targetType.equals(TargetType.ENNEMY_MULTI_TARGET)
        && nbTargets != null
        && targets.size() >= nbTargets) {
      trueTargets.addAll(targets.subList(0, nbTargets));
    } else {
      trueTargets.addAll(targets);
    }
    for (Character target : trueTargets) {
      double theoriticalDamages;
      if (isMultiplier != null && isMultiplier && explosionDamages != null) {
        theoriticalDamages = caster.getAttackPower() * explosionDamages;
      } else {
        theoriticalDamages =
            Objects.requireNonNullElseGet(explosionDamages, () -> caster.getAttackPower() * 1.5);
      }
      double damages = target.takeDamage(theoriticalDamages);
      System.out.println(
          caster.getName()
              + " attacks "
              + target.getName()
              + " with "
              + name
              + " for "
              + damages
              + " dmg "
              + target);
    }
  }

  @Override
  public Skill newInstance() {
    return new Explosion(
        targetType, name, cooldownValue, nbTargets, explosionDamages, isMultiplier);
  }
}
