package RogueLite.characters.test;

import RogueLite.characters.hero.Hero;

public final class CharacterStep3Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Hero - Step 3 tests (XP & level scaling) ===");

    int level = 0;
    int xp = 0;
    for(int i = 0; i <= 10; i++){
      int cap = Math.toIntExact(Math.round(Math.pow(100, 1 + ((double) (level)/10))));
      System.out.println(level +"/"+ cap);
      level++;
    }


    test("xp=0 => level=0 => stats unchanged", () -> {
      Hero h = new Hero("H", 20, 5, 5);

      expectEquals("attack", 5, h.getAttackPower());
      expectEquals("defence", 5, h.getDefence());
      expectEquals("maxHp", 20.0, h.getMaxHp());
    });

    test("addXp(0) and addXp(negative) should not increase stats (recommended behavior)", () -> {
      Hero h = new Hero("H", 20, 5, 5);

      double atk0 = h.getAttackPower();
      double def0 = h.getDefence();
      double max0 = h.getMaxHp();

      h.addXp(0);
      h.addXp(-100);

      expectEquals("xp", 0, h.getXp());
      expectEquals("attack", atk0, h.getAttackPower());
      expectEquals("defence", def0, h.getDefence());
      expectEquals("maxHp", max0, h.getMaxHp());
    });

    test("addXp(negative) does not change stored xp after progress already exists", () -> {
      Hero h = new Hero("H", 20, 5, 5);

      h.addXp(40);
      h.addXp(-100);

      expectEquals("xp", 40, h.getXp());
    });

    test("xp=25 => sqrt=5 => level=round(0.5)=1 => attack+1, maxHp+2", () -> {
      Hero h = new Hero("H", 20, 5, 5);
      h.addXp(100);

      expectEquals("attack", 6, h.getAttackPower());
      expectEquals("defence", 5, h.getDefence());
      expectEquals("maxHp", 22.0, h.getMaxHp());
    });

    test("xp=100 => sqrt=10 => level=round(1.0)=1 => still level 1", () -> {
      Hero h = new Hero("H", 20, 5, 5);
      h.addXp(100);

      expectEquals("attack", 6, h.getAttackPower());
      expectEquals("defence", 5, h.getDefence());
      expectEquals("maxHp", 22.0, h.getMaxHp());
    });

    test("xp=258 => sqrt=15 => level=round(1.5)=2 => attack+2, maxHp+4", () -> {
      Hero h = new Hero("H", 20, 5, 5);
      h.addXp(258);

      expectEquals("attack", 7, h.getAttackPower());
      expectEquals("defence", 5, h.getDefence()); // 2/4 = 0
      expectEquals("maxHp", 24.0, h.getMaxHp());
    });

    test("xp=625 => sqrt=25 => level=round(2.5)=3 => attack+3, maxHp+6", () -> {
      Hero h = new Hero("H", 20, 5, 5);
      h.addXp(625);

      expectEquals("attack", 8, h.getAttackPower());
      expectEquals("defence", 5, h.getDefence()); // 3/4 = 0
      expectEquals("maxHp", 26.0, h.getMaxHp());
    });

    test("xp=2500 => sqrt=50 => level=round(5.0)=5 => defence increases by 1 (5/4)", () -> {
      Hero h = new Hero("H", 20, 5, 5);
      h.addXp(2500);

      expectEquals("attack", 10, h.getAttackPower()); // 5 + 5
      expectEquals("defence", 6, h.getDefence());     // 5 + (5/4=1)
      expectEquals("maxHp", 30.0, h.getMaxHp());      // 20 + 10
    });

    test("xp accumulation: addXp multiple times equals single addXp of sum", () -> {
      Hero h1 = new Hero("H1", 20, 5, 5);
      Hero h2 = new Hero("H2", 20, 5, 5);

      h1.addXp(1000);
      h1.addXp(1500);

      h2.addXp(2500);

      expectEquals("attack", h2.getAttackPower(), h1.getAttackPower());
      expectEquals("defence", h2.getDefence(), h1.getDefence());
      expectEquals("maxHp", h2.getMaxHp(), h1.getMaxHp());
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests Hero XP/Level ont échoué (" + failed + ")");
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

  private CharacterStep3Test() {
  }
}
