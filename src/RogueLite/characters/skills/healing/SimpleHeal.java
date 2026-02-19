package RogueLite.characters.skills.healing;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import java.util.List;

public class SimpleHeal implements Skill {

  TargetType targetType = TargetType.ALLY_SINGLE_LOWEST_HP;
  String name = "Heal";
  int cooldownValue = 3;
  int cooldownRemaining = 3;
  Double healed;
  Boolean isPercentage;

  public SimpleHeal() {}

  public SimpleHeal(
      TargetType targetType, String name, int cooldownValue, Double healed, Boolean isPercentage) {
    this.targetType = targetType;
    this.name = name;
    this.cooldownValue = cooldownValue;
    this.cooldownRemaining = cooldownValue;
    this.healed = healed;
    this.isPercentage = isPercentage;
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
  public boolean shouldUse(
      RogueLite.characters.Character caster, List<RogueLite.characters.Character> targets) {
    return targets.getFirst().getHp() != targets.getFirst().getMaxHp();
  }

  @Override
  public void use(
      RogueLite.characters.Character caster, List<RogueLite.characters.Character> targets) {
    for (Character target : targets) {
      double healValue;
      if (isPercentage != null && healed != null) {
        if (isPercentage) {
          healValue = target.getMaxHp() * healed / 100;
        } else {
          healValue = healed;
        }
      } else {
        healValue = target.getMaxHp() * 1 / 4;
      }
      double heal = target.heal(healValue);
      System.out.println(
          caster.getName()
              + " heals "
              + target.getName()
              + " with "
              + name
              + " for "
              + heal
              + " hp "
              + target);
    }
  }

  @Override
  public Skill newInstance() {
    return new SimpleHeal(targetType, name, cooldownValue, healed, isPercentage);
  }
}
