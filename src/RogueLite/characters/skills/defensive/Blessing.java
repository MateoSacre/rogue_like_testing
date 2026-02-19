package RogueLite.characters.skills.defensive;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import RogueLite.statuseffect.buff.defense.Blessed;
import java.util.List;

public class Blessing implements Skill {

  TargetType targetType = TargetType.ALLY_TEAM;
  String name = "Blessing";
  int cooldownValue = 3;
  int cooldownRemaining = 3;
  Integer protection;
  Integer duration;

  public Blessing() {}

  public Blessing(
      TargetType targetType, String name, int cooldownValue, int protection, int duration) {
    this.targetType = targetType;
    this.name = name;
    this.cooldownValue = cooldownValue;
    this.cooldownRemaining = cooldownValue;
    this.protection = protection;
    this.duration = duration;
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
            .filter(
                t ->
                    t.getStatusEffects().stream()
                        .noneMatch(s -> s.getName().equals(getName())))
            .toList()) {
      if (protection != null && duration != null) {
        target.addEffect(new Blessed(name, protection, duration));
      } else {
        target.addEffect(new Blessed());
      }
      System.out.println(caster.getName() + " apply " + getName() + " effect on " + target);
    }
  }

  @Override
  public Skill newInstance() {
    return new Blessing(targetType, this.name, cooldownValue, protection, duration);
  }
}
