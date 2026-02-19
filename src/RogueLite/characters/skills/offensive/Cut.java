package RogueLite.characters.skills.offensive;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import RogueLite.statuseffect.recurrent.Bleed;
import java.util.List;

public class Cut implements Skill {

  TargetType targetType = TargetType.ENNEMY_SINGLE;
  String name = "Cut";
  int cooldownValue = 4;
  int cooldownRemaining = 4;
  Integer bleedDuration;
  Double bleedDamage;

  public Cut(
      TargetType targetType,
      String name,
      int cooldownValue,
      int bleedDuration,
      double bleedDamage) {
    this.targetType = targetType;
    this.name = name;
    this.cooldownValue = cooldownValue;
    this.cooldownRemaining = cooldownValue;
    this.bleedDuration = bleedDuration;
    this.bleedDamage = bleedDamage;
  }

  public Cut() {}

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
    for (Character target : targets) {
      caster.attack(target);
      Bleed bleed;
      if (bleedDamage != null && bleedDuration != null) {
        bleed = new Bleed(name, bleedDuration, bleedDamage);
      } else {
        bleed = new Bleed();
      }
      target.getStatusEffects().stream()
          .filter(e -> e.getName().equals(name))
          .toList()
          .forEach(
              targetStatusEffects -> targetStatusEffects.setDuration(bleed.getDuration()));
      target.addEffect(bleed);
      System.out.println(caster.getName() + " apply " + getName() + " effect on " + target);
    }
  }

  @Override
  public Skill newInstance() {
    return new Cut(targetType,name,cooldownValue,bleedDuration,bleedDamage);
  }
}
