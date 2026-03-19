package RogueLite.characters.test;

import RogueLite.characters.hero.Hero;
import RogueLite.characters.hero.Hero.LevelUpStat;

public final class CharacterStep3Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Hero - Step 3 tests (XP & level choices) ===");

    Hero.setLevelUpStatChooser(hero -> LevelUpStat.ATTACK);
    try {
      test("xp=0 => no level => stats unchanged", () -> {
        Hero h = new Hero("H", 20, 5, 5);

        expectEquals("attack", 5, h.getAttackPower());
        expectEquals("defence", 5, h.getDefence());
        expectEquals("maxHp", 20.0, h.getMaxHp());
      });

      test("addXp(0) and addXp(negative) keep progress unchanged", () -> {
        Hero h = new Hero("H", 20, 5, 5);

        h.addXp(0);
        h.addXp(-100);

        expectEquals("level", 0, h.getLevel());
        expectEquals("xp", 0, h.getXp());
        expectEquals("attack", 5, h.getAttackPower());
        expectEquals("defence", 5, h.getDefence());
        expectEquals("maxHp", 20.0, h.getMaxHp());
      });

      test("a level-up can permanently increase attack by at least 5 percent", () -> {
        Hero h = new Hero("H", 20, 5, 5);

        h.addXp(100);

        expectEquals("level", 1, h.getLevel());
        expectEquals("attack", 6, h.getAttackPower());
        expectEquals("defence", 5, h.getDefence());
        expectEquals("maxHp", 20.0, h.getMaxHp());
      });

      test("multiple attack picks stack permanently across levels", () -> {
        Hero h = new Hero("H", 20, 20, 5);

        h.addXp(250);

        expectEquals("level", 2, h.getLevel());
        expectEquals("attack", 23, h.getAttackPower());
        expectEquals("defence", 5, h.getDefence());
        expectEquals("maxHp", 20.0, h.getMaxHp());
      });

      test("xp accumulation across calls matches a single equivalent grant", () -> {
        Hero h1 = new Hero("H1", 20, 20, 5);
        Hero h2 = new Hero("H2", 20, 20, 5);

        h1.addXp(100);
        h1.addXp(150);

        h2.addXp(250);

        expectEquals("level", h2.getLevel(), h1.getLevel());
        expectEquals("attack", h2.getAttackPower(), h1.getAttackPower());
        expectEquals("defence", h2.getDefence(), h1.getDefence());
        expectEquals("maxHp", h2.getMaxHp(), h1.getMaxHp());
      });

      test("minimum increase of 1 applies to defence on level-up", () -> {
        Hero.setLevelUpStatChooser(hero -> LevelUpStat.DEFENCE);
        Hero h = new Hero("Tank", 20, 5, 1);

        h.addXp(100);

        expectEquals("level", 1, h.getLevel());
        expectEquals("attack", 5, h.getAttackPower());
        expectEquals("defence", 2, h.getDefence());
        expectEquals("maxHp", 20.0, h.getMaxHp());
      });

      test("max hp choice increases max hp permanently", () -> {
        Hero.setLevelUpStatChooser(hero -> LevelUpStat.MAX_HP);
        Hero h = new Hero("Vitality", 20, 5, 5);

        h.addXp(100);

        expectEquals("level", 1, h.getLevel());
        expectEquals("attack", 5, h.getAttackPower());
        expectEquals("defence", 5, h.getDefence());
        expectEquals("maxHp", 21.0, h.getMaxHp());
      });
    } finally {
      Hero.resetLevelUpStatChooser();
    }

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests Hero XP/Level ont echoue (" + failed + ")");
    }
  }

  private static void test(String name, Runnable body) {
    try {
      body.run();
      passed++;
      System.out.println("[OK]   " + name);
    } catch (Throwable t) {
      failed++;
      System.out.println("[FAIL] " + name);
      System.out.println("       " + t.getClass().getSimpleName() + ": " + t.getMessage());
    }
  }

  private static void expectEquals(String label, int expected, int actual) {
    if (expected != actual) {
      throw new AssertionError(label + " expected " + expected + " but was " + actual);
    }
  }

  private static void expectEquals(String label, double expected, double actual, double eps) {
    if (Math.abs(expected - actual) > eps) {
      throw new AssertionError(label + " expected " + expected + " but was " + actual);
    }
  }

  private static void expectEquals(String label, double expected, double actual) {
    expectEquals(label, expected, actual, 0.000001);
  }

  private CharacterStep3Test() {}
}
