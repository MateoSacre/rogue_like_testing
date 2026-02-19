package RogueLite.characters.test;

import RogueLite.characters.Character;

public final class CharacterStep2Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Character - Step 2 tests (attack/defense) ===");

    test("constructor sets attackPower/defense", () -> {
      Character a = new Character("A", 10, 7, 2);
      expectEquals("attackPower", 7, a.getAttackPower());
      expectEquals("defense", 2, a.getDefence());
      expectEquals("hp", 10, a.getHp());
    });

    test("computeDamageAgainst: 8 atk vs 3 def => 5", () -> {
      Character attacker = new Character("Att", 10, 8, 0);
      Character target = new Character("Tgt", 10, 0, 3);
      expectEquals("damage", 5, attacker.computeDamageAgainst(target));
    });

    test("computeDamageAgainst: defense >= attack => 1", () -> {
      Character attacker = new Character("Att", 10, 3, 0);
      Character target = new Character("Tgt", 10, 0, 10);
      expectEquals("damage", 1, attacker.computeDamageAgainst(target));
    });

    test("computeDamageAgainst: null target throws", () -> {
      Character attacker = new Character("Att", 10, 3, 0);
      expectThrows(IllegalArgumentException.class, () -> attacker.computeDamageAgainst(null));
    });

    test("attack applies damage to target hp and returns same damage", () -> {
      Character attacker = new Character("Att", 10, 8, 0);
      Character target = new Character("Tgt", 10, 0, 3);

      double damage = attacker.attack(target);
      expectEquals("returned damage", 5, damage);
      expectEquals("target hp", 5, target.getHp());
    });

    test("attack with defense >= attack does 1 damage and target hp unchanged", () -> {
      Character attacker = new Character("Att", 10, 3, 0);
      Character target = new Character("Tgt", 10, 0, 10);

      double damage = attacker.attack(target);
      expectEquals("returned damage", 1, damage);
      expectEquals("target hp", 9, target.getHp());
    });

    test("attack: attacker dead => no-op returns 0", () -> {
      Character attacker = new Character("DeadAtt", 10, 100, 0);
      Character target = new Character("Tgt", 10, 0, 0);

      attacker.takeDamage(999); // attacker dead
      expectFalse("attacker alive", attacker.isAlive());

      double damage = attacker.attack(target);
      expectEquals("returned damage", 0, damage);
      expectEquals("target hp", 10, target.getHp());
    });

    test("attack: target dead => no-op returns 0", () -> {
      Character attacker = new Character("Att", 10, 100, 0);
      Character target = new Character("DeadTgt", 10, 0, 0);

      target.takeDamage(999);
      expectFalse("target alive", target.isAlive());

      double damage = attacker.attack(target);
      expectEquals("returned damage", 0, damage);
      expectEquals("target hp still 0", 0, target.getHp());
    });

    test("attack: null target throws (dev bug)", () -> {
      Character attacker = new Character("Att", 10, 3, 0);
      expectThrows(IllegalArgumentException.class, () -> attacker.attack(null));
    });

    test("attack never makes hp negative (even huge damage)", () -> {
      Character attacker = new Character("Att", 10, 1_000_000, 0);
      Character target = new Character("Tgt", 10, 0, 0);

      double damage = attacker.attack(target);
      expectTrue("damage >= 0", damage >= 0);
      expectEquals("target hp", 0, target.getHp());
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests Step2 ont échoué (" + failed + ")");
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
}