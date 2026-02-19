package RogueLite.characters.test;

import RogueLite.characters.Character;

public final class CharacterStep1Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Character - Step 1 tests ===");

    test("constructor initializes hp to maxHp", () -> {
      Character c = new Character("Alice", 10);
      expectEquals("hp", 10, c.getHp());
      expectEquals("maxHp", 10, c.getMaxHp());
      expectTrue("isAlive", c.isAlive());
    });

    test("constructor rejects invalid args", () -> {
      expectThrows(IllegalArgumentException.class, () -> new Character(null, 10));
      expectThrows(IllegalArgumentException.class, () -> new Character("   ", 10));
      expectThrows(IllegalArgumentException.class, () -> new Character("Bob", 0));
      expectThrows(IllegalArgumentException.class, () -> new Character("Bob", -5));
    });

    test("takeDamage reduces hp", () -> {
      Character c = new Character("Bob", 10);
      c.takeDamage(3);
      expectEquals("hp", 7, c.getHp());
    });

    test("takeDamage clamps to 0", () -> {
      Character c = new Character("Claire", 10);
      c.takeDamage(999);
      expectEquals("hp", 0, c.getHp());
      expectFalse("isAlive", c.isAlive());
    });

    test("takeDamage(0) and takeDamage(negative) are no-op", () -> {
      Character c = new Character("NoOp", 10);
      c.takeDamage(0);
      expectEquals("hp after 0 dmg", 10, c.getHp());
      c.takeDamage(-10);
      expectEquals("hp after negative dmg", 10, c.getHp());
    });

    test("heal increases hp but not above maxHp", () -> {
      Character c = new Character("Dan", 10);
      c.takeDamage(8); // hp = 2
      c.heal(5);       // hp = 7
      expectEquals("hp", 7, c.getHp());

      c.heal(999);     // hp = 10
      expectEquals("hp", 10, c.getHp());
    });

    test("heal(0) and heal(negative) are no-op", () -> {
      Character c = new Character("NoOpHeal", 10);
      c.takeDamage(3); // hp = 7
      c.heal(0);
      expectEquals("hp after heal 0", 7, c.getHp());
      c.heal(-10);
      expectEquals("hp after heal negative", 7, c.getHp());
    });

    test("invariants always hold: 0 <= hp <= maxHp", () -> {
      Character c = new Character("Inv", 10);
      c.takeDamage(1000);
      expectTrue("hp >= 0", c.getHp() >= 0);
      expectTrue("hp <= maxHp", c.getHp() <= c.getMaxHp());

      c.heal(1000);
      expectTrue("hp >= 0", c.getHp() >= 0);
      expectTrue("hp <= maxHp", c.getHp() <= c.getMaxHp());
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests ont échoué (" + failed + ")");
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

  private static void expectTrue(String label, boolean value) {
    if (!value) {
      throw new AssertionError(label + " expected true but was false");
    }
  }

  private static void expectFalse(String label, boolean value) {
    if (value) {
      throw new AssertionError(label + " expected false but was true");
    }
  }

  private static void expectEquals(String label, int expected, int actual) {
    if (expected != actual) {
      throw new AssertionError(label + " expected " + expected + " but was " + actual);
    }
  }

  private static void expectEquals(String label, double expected, double actual) {
    if (expected != actual) {
      throw new AssertionError(label + " expected " + expected + " but was " + actual);
    }
  }

  private static void expectThrows(Class<? extends Throwable> expectedType, Runnable body) {
    try {
      body.run();
    } catch (Throwable t) {
      if (expectedType.isInstance(t)) {
        return;
      }
      throw new AssertionError(
          "Expected exception " + expectedType.getSimpleName() + " but got " + t.getClass().getSimpleName(), t
      );
    }
    throw new AssertionError("Expected exception " + expectedType.getSimpleName() + " but nothing was thrown");
  }

  private CharacterStep1Test() {
  }
}