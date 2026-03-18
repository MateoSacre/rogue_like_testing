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

public class BossWaveGenerator {

  private static final long DEFAULT_SEED = 0L;

  protected final Random random;

  public BossWaveGenerator() {
    this.random = new Random(DEFAULT_SEED);
  }

  public BossWaveGenerator(Random random) {
    this.random = random;
  }

  public BossWaveGenerator(Long seed) {
    this.random = new Random(seed);
  }

  public Team generateWave(int totalValue) {
    Debug.log("BossWaveGenerator", "Generating boss wave with totalValue=" + totalValue);
    int index = 1;
    int remainingValue = totalValue;
    int remainingSlots = SimpleWaveGenerator.MAX_WAVE_SIZE;
    List<Mob> wave = new ArrayList<>();
    boolean bossAdded = false;

    while (remainingValue > 0 && remainingSlots > 0) {
      Mob newMob = selectMobForRemainingValue(index, remainingValue, remainingSlots, bossAdded);
      if (newMob == null) {
        Debug.log("BossWaveGenerator", "Stopping generation: no valid mob for remainingValue=" + remainingValue);
        break;
      }
      wave.add(newMob);
      Debug.log(
          "BossWaveGenerator",
          "Added mob " + newMob.getName() + " value=" + newMob.getValue() + " ai=" + newMob.getAiType());
      remainingValue -= newMob.getValue();
      remainingSlots--;
      bossAdded = bossAdded || newMob.isBoss();
      index++;
    }
    return new MobTeam("Wave", List.copyOf(wave));
  }

  protected Mob selectMobForRemainingValue(
      int index, int remainingValue, int remainingSlots, boolean bossAdded) {
    Mob selectedMob = null;

    if (!bossAdded) {
      selectedMob = findBossForRemainingValue(remainingValue, remainingSlots);
    }
    if (selectedMob == null) {
      selectedMob =
          new SimpleWaveGenerator(random)
              .findClosestMobWithinShare(remainingValue,false);
    }
    if (selectedMob == null) {
      return null;
    }

    Mob mob = new Mob(selectedMob);
    mob.setName(index + "-" + mob.getName());
    mob.setAiType(MobAiType.randomFor(mob, random));
    Debug.log(
        "BossWaveGenerator",
        "Selected template=" + selectedMob.getName() + " remainingValue=" + remainingValue + " ai=" + mob.getAiType());
    return mob;
  }

  private Mob findBossForRemainingValue(int remainingValue, int remainingSlots) {
    double targetValue = (double) remainingValue / remainingSlots;
    double minimumTargetValue = targetValue / 4.0;

    List<Mob> bossesWithinTargetWindow =
        MobsDictionary.mobs.stream()
            .filter(Mob::isBoss)
            .filter(m -> m.getValue() <= remainingValue)
            .filter(m -> m.getValue() <= targetValue)
            .filter(m -> m.getValue() >= minimumTargetValue)
            .toList();

    if (!bossesWithinTargetWindow.isEmpty()) {
      return bossesWithinTargetWindow.get(random.nextInt(bossesWithinTargetWindow.size()));
    }

    return MobsDictionary.mobs.stream()
        .filter(Mob::isBoss)
        .filter(m -> m.getValue() <= remainingValue)
        .min(Comparator.comparingInt(Mob::getValue))
        .orElse(null);
  }
}
