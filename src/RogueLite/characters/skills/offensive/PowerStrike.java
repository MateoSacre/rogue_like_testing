package RogueLite.characters.skills.offensive;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import java.util.List;

public class PowerStrike implements Skill {

  TargetType targetType = TargetType.ENNEMY_SINGLE;
  String name = "Power Strike";
  int cooldownValue = 3;
  int cooldownRemaining = 3;
  double damageModifier = 2;

  public PowerStrike() {}

  public PowerStrike(TargetType targetType, String name, int cooldownValue,double damageModifier) {
    this.targetType = targetType;
    this.name = name;
    this.cooldownValue = cooldownValue;
    this.cooldownRemaining = cooldownValue;
    this.damageModifier = damageModifier;
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
    if (targets.size() == 1
        && (targets.getFirst().getHp() <= caster.getAttackPower()
            || targets.getFirst().getDefence() > caster.getAttackPower() * damageModifier)) {
      return false;
    }
    return true;
  }

  @Override
  public void use(Character caster, List<Character> targets) {
    for (Character target : targets) {
      double damages = caster.attack(target, damageModifier);
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
    return new PowerStrike(targetType, name, cooldownValue,damageModifier);
  }
}
