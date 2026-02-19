package RogueLite.characters.skills;

import RogueLite.characters.Character;
import java.util.List;

public interface Skill {

  String getName();
  int getCooldownValue();
  int getCooldownRemaining();

  TargetType getTargetType();

  void initiateCooldown();
  void applySkillCooldown();

  boolean shouldUse(Character caster, List<Character> targets);
  void use(Character caster, List<Character> targets);

  Skill newInstance();
}