package RogueLite.waves.test;

import RogueLite.teams.Team;
import RogueLite.waves.BossWaveGenerator;
import RogueLite.waves.SimpleWaveGenerator;
import RogueLite.characters.mobs.Mob;

public final class WavesStep1Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Waves - Step 5 tests (budget + boss rules) ===");

    test("new SimpleWaveGenerator().generateWave(totalValue) rejects non-positive? (document current behavior)", () -> {
      // Ton code ne check pas totalValue <= 0. Donc:
      // totalValue=0 => wave vide => Team(..., List.of()) => probablement exception côté Team.
      // Ici on documente le comportement attendu: ça doit throw.
      expectThrows(RuntimeException.class, () -> new SimpleWaveGenerator().generateWave(0));
      expectThrows(RuntimeException.class, () -> new SimpleWaveGenerator().generateWave(-1));
    });

    test("SimpleWaveGenerator: total value of generated wave stays within requested totalValue", () -> {
      Team wave = new SimpleWaveGenerator().generateWave(10);
      expectTrue("sum values <= total", sumValues(wave) <= 10);
    });

    test("SimpleWaveGenerator: contains no boss mobs", () -> {
      Team wave = new SimpleWaveGenerator().generateWave(20);
      expectFalse("containsBoss", containsBoss(wave));
    });

    test("BossWaveGenerator: should contain at least one boss mob (will expose static hiding issue)", () -> {
      Team wave = new BossWaveGenerator().generateWave(10);
      expectTrue("containsBoss", containsBoss(wave));
    });

    test("BossWaveGenerator: total value stays within requested totalValue", () -> {
      Team wave = new BossWaveGenerator().generateWave(15);
      expectTrue("sum values <= total", sumValues(wave) <= 15);
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests WavesStep5 ont échoué (" + failed + ")");
    }
  }

  private static int sumValues(Team team) {
    int sum = 0;
    for (var c : team.getMembers()) {
      if (!(c instanceof Mob mob)) {
        throw new AssertionError("Team contient un membre non-Mob: " + c.getClass().getName());
      }
      sum += mob.getValue();
    }
    return sum;
  }

  private static boolean containsBoss(Team team) {
    for (var c : team.getMembers()) {
      if (c instanceof Mob mob && mob.isBoss()) {
        return true;
      }
    }
    return false;
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

  private static void expectThrows(Class<? extends Throwable> expectedType, Runnable body) {
    try {
      body.run();
    } catch (Throwable t) {
      if (expectedType.isInstance(t)) {
        return;
      }
      // On accepte aussi les sous-classes de RuntimeException si tu veux garder souple
      if (expectedType == RuntimeException.class && t instanceof RuntimeException) {
        return;
      }
      throw new AssertionError(
          "Expected " + expectedType.getSimpleName() + " but got " + t.getClass().getSimpleName(), t
      );
    }
    throw new AssertionError("Expected " + expectedType.getSimpleName() + " but nothing was thrown");
  }
}
