package RogueLite.characters.skills.offensive;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import java.util.List;

public class Splash implements Skill {

  TargetType targetType = TargetType.ENNEMY_TEAM;
  String name = "Splash";
  int cooldownValue = 2;
  int cooldownRemaining = 2;

  public Splash() {}

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
    for (Character target : targets) {
      target.takeDamage(1);
      System.out.println(
          caster.getName()
              + " attacks "
              + target.getName()
              + " with "
              + name
              + " for 1 dmg "
              + target);
    }
  }

  @Override
  public Skill newInstance() {
    return new Splash();
  }
}
