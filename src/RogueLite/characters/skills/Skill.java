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

  default boolean appliesNegativeEffect() {
    return false;
  }

  default boolean targetsEnemies() {
    return switch (getTargetType()) {
      case ENNEMY_SINGLE,
          ENNEMY_SINGLE_LOWEST_HP,
          ENNEMY_SINGLE_HIGHEST_HP,
          ENNEMY_MULTI_TARGET,
          ENNEMY_TEAM -> true;
      default -> false;
    };
  }
}
