package RogueLite;

import java.util.Random;

public final class GameRandom {

  private static final long DEFAULT_SEED = 0L;

  private static long currentSeed = DEFAULT_SEED;
  private static Random random = new Random(DEFAULT_SEED);

  private GameRandom() {}

  public static Random shared() {
    return random;
  }

  public static long getCurrentSeed() {
    return currentSeed;
  }

  public static void setSeed(long seed) {
    currentSeed = seed;
    random = new Random(seed);
  }

  public static void reset() {
    setSeed(DEFAULT_SEED);
  }
}
