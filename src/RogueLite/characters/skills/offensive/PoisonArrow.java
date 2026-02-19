package RogueLite.characters.skills.defensive;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import RogueLite.statuseffect.recurrent.Poison;
import java.util.List;

public class PoisonArrow implements Skill {

  TargetType targetType = TargetType.ENNEMY_SINGLE;
  String name = "PoisonArrow";
  int cooldownValue = 3;
  int cooldownRemaining = 3;
  Integer poisonDuration;
  Double poisonDamage;

  public PoisonArrow() {}

  public PoisonArrow(
      TargetType targetType,
      String name,
      int cooldownValue,
      Integer poisonDuration,
      double poisonDamage) {
    this.targetType = targetType;
    this.name = name;
    this.cooldownValue = cooldownValue;
    this.cooldownRemaining = cooldownValue;
    this.poisonDuration = poisonDuration;
    this.poisonDamage = poisonDamage;
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
    return true;
  }

  @Override
  public void use(Character caster, List<Character> targets) {
    for (Character target :
        targets.stream()
            .filter(t -> t.getStatusEffects().stream().noneMatch(s -> s.getName().equals(name)))
            .toList()) {
      caster.attack(target);
      Poison poison;
      if (poisonDamage != null && poisonDuration != null) {
        poison = new Poison(name, poisonDuration, poisonDamage);
      } else {
        poison = new Poison();
      }
      target.addEffect(poison);
      System.out.println(caster.getName() + " uses " + getName() + " on " + target);
    }
  }

  @Override
  public Skill newInstance() {
    return new PoisonArrow(targetType, name, cooldownValue, poisonDuration, poisonDamage);
  }
}
