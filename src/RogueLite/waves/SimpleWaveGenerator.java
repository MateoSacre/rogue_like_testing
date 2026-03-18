package RogueLite.waves;

import RogueLite.Debug;
import RogueLite.teams.MobTeam;
import RogueLite.teams.Team;
import RogueLite.characters.mobs.Mob;
import RogueLite.characters.mobs.MobAiType;
import RogueLite.characters.mobs.MobsDictionary;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Random;

public class SimpleWaveGenerator {

  private static final long DEFAULT_SEED = 0L;
  protected static final int MAX_WAVE_SIZE = 6;

  protected final Random random;

  public SimpleWaveGenerator() {
    this.random = new Random(DEFAULT_SEED);
  }

  public SimpleWaveGenerator(Random random) {
    this.random = random;
  }

  public SimpleWaveGenerator(Long seed) {
    this.random = new Random(seed);
  }

  public Team generateWave(int totalValue) {
    Debug.log("SimpleWaveGenerator", "Generating wave with totalValue=" + totalValue);
    int index = 1;
    int remainingValue = totalValue;
    int remainingSlots = MAX_WAVE_SIZE;
    List<Mob> wave = new ArrayList<>();
    while (remainingValue > 0 && remainingSlots > 0) {
      Mob newMob = selectMobForRemainingValue(index, remainingValue);
      if (newMob == null) {
        Debug.log("SimpleWaveGenerator", "Stopping generation: no valid mob for remainingValue=" + remainingValue);
        break;
      }
      wave.add(newMob);
      Debug.log(
          "SimpleWaveGenerator",
          "Added mob " + newMob.getName() + " value=" + newMob.getValue() + " ai=" + newMob.getAiType());
      remainingValue -= newMob.getValue();
      remainingSlots--;
      index++;
    }
    return new MobTeam("Wave", List.copyOf(wave));
  }

  protected Mob selectMobForRemainingValue(int index, int remainingValue) {
    Mob selectedMob = findClosestMobWithinShare(remainingValue, false);
    if (selectedMob == null) {
      return null;
    }
    Mob mob = new Mob(selectedMob);
    mob.setName(index + "-" + mob.getName());
    mob.setAiType(MobAiType.randomFor(mob, random));
    Debug.log(
        "SimpleWaveGenerator",
        "Selected template=" + selectedMob.getName() + " remainingValue=" + remainingValue + " ai=" + mob.getAiType());
    return mob;
  }

  protected Mob findClosestMobWithinShare(
      int remainingValue, boolean bossesAllowed) {
    double minimumTargetValue = remainingValue / 4.0;

    List<Mob> mobsWithinTargetWindow =
        MobsDictionary.mobs.stream()
            .filter(m -> m.getValue() <= remainingValue)
            .filter(m -> bossesAllowed || !m.isBoss() || (m.isBoss() && m.getValue() <= remainingValue/4))
            .filter(m -> m.getValue() <= remainingValue)
            .filter(m -> m.getValue() >= minimumTargetValue)
            .toList();

    if (!mobsWithinTargetWindow.isEmpty()) {
      return mobsWithinTargetWindow.get(random.nextInt(mobsWithinTargetWindow.size()));
    }

    return MobsDictionary.mobs.stream()
        .filter(m -> m.getValue() <= remainingValue)
        .filter(m -> bossesAllowed || !m.isBoss() || (m.isBoss() && m.getValue() <= remainingValue/4))
        .min(Comparator.comparingInt(Mob::getValue))
        .orElse(null);
  }

}
