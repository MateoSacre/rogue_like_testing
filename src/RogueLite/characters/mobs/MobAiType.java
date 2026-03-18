package RogueLite.characters.mobs;

import RogueLite.Debug;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public enum MobAiType {
  DUMB,
  RANDOM,
  KILLER,
  DAMAGER,
  EFFECT_DEALER,
  EFFECT_STACKER;

  public static MobAiType randomFor(Mob mob, Random random) {
    List<MobAiType> availableTypes = new ArrayList<>(List.of(DUMB, RANDOM, KILLER, DAMAGER));
    if (mob.getSkill() != null
        && mob.getSkill().appliesNegativeEffect()
        && mob.getSkill().targetsEnemies()) {
      availableTypes.add(EFFECT_DEALER);
      availableTypes.add(EFFECT_STACKER);
    }
    MobAiType selectedType = availableTypes.get(random.nextInt(availableTypes.size()));
    Debug.log("MobAiType", "Assigned " + selectedType + " to " + mob.getName());
    return selectedType;
  }
}
