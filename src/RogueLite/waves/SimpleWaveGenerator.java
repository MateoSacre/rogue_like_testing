package RogueLite.waves;

import RogueLite.teams.MobTeam;
import RogueLite.teams.Team;
import RogueLite.characters.mobs.Mob;
import RogueLite.characters.mobs.MobsDictionary;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class SimpleWaveGenerator {

  private static final long DEFAULT_SEED = 0L;

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
    int currentWaveValue = 0;
    int index = 1;
    List<Mob> wave = new ArrayList<>();
    while (currentWaveValue < totalValue) {
      Mob newMob = selectRandomMobInValue(index, currentWaveValue, totalValue);
      wave.add(newMob);
      currentWaveValue += newMob.getValue();
      index++;
    }
    return new MobTeam("Wave", List.copyOf(wave));
  }

  protected Mob selectRandomMobInValue(int index, int currentWaveValue, int totalValue) {
    int minValue = Math.max(1, totalValue / 10);

    List<Mob> strictMobs =
        MobsDictionary.mobs.stream()
            .filter(m -> m.getValue() + currentWaveValue <= totalValue)
            .filter(m -> m.getValue() >= minValue)
            .filter(m -> !m.isBoss() || (m.getValue() <= totalValue / 5))
            .toList();

    List<Mob> pool = strictMobs;

    if (pool.isEmpty()) {
      pool =
          MobsDictionary.mobs.stream()
              .filter(m -> m.getValue() + currentWaveValue <= totalValue)
              .filter(m -> !m.isBoss() || (m.getValue() <= totalValue / 2))
              .toList();
    }

    if (pool.isEmpty()) {
      throw new IllegalStateException(
          "No mobs can fit in remaining budget. currentWaveValue=" + currentWaveValue
              + ", totalValue=" + totalValue);
    }

    Mob mob = new Mob(pool.get(random.nextInt(pool.size())));
    mob.setName(index + "-" + mob.getName());
    return mob;
  }

}
