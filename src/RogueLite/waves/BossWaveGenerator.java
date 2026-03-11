package RogueLite.waves;

import RogueLite.teams.MobTeam;
import RogueLite.teams.Team;
import RogueLite.characters.mobs.Mob;
import RogueLite.characters.mobs.MobsDictionary;
import java.util.ArrayList;
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
    List<Mob> potentialMobs;
    if (totalValue % 100 == 0) {
      potentialMobs =
          MobsDictionary.mobs.stream().filter(m -> m.getValue() == 100 && m.isBoss()).toList();
    } else {
      potentialMobs =
          MobsDictionary.mobs.stream()
              .filter(m -> m.getValue() + currentWaveValue <= totalValue && m.isBoss())
              .toList();
    }
    if (potentialMobs.isEmpty()) {
      return new SimpleWaveGenerator(random)
          .selectRandomMobInValue(index, currentWaveValue, totalValue);
    }
    Mob mob = new Mob(potentialMobs.get(random.nextInt(potentialMobs.size())));
    mob.setName(index + "-" + mob.getName());
    return mob;
  }
}
