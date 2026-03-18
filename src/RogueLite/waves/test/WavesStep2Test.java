package RogueLite.waves.test;

import RogueLite.characters.mobs.MobTier;
import RogueLite.characters.mobs.MobsDictionary;
import RogueLite.teams.Team;
import RogueLite.waves.BossWaveGenerator;
import RogueLite.waves.SimpleWaveGenerator;
import RogueLite.waves.ThemedWave;
import RogueLite.waves.ThemedWaveGenerator;
import RogueLite.characters.mobs.Mob;

public final class WavesStep2Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Waves - Step 6 tests (seed & reproducibility) ===");

    test("same seed => same SimpleWave signature", () -> {
      var gen1 = new SimpleWaveGenerator(123L);
      var gen2 = new SimpleWaveGenerator(123L);

      Team w1 = gen1.generateWave(10);
      Team w2 = gen2.generateWave(10);

      expectEquals("signature", signature(w1), signature(w2));
      expectEquals("value sum", sumValues(w1), sumValues(w2));
    });

    test("same seed => same BossWave signature", () -> {
      var gen1 = new BossWaveGenerator(999L);
      var gen2 = new BossWaveGenerator(999L);

      Team w1 = gen1.generateWave(10);
      Team w2 = gen2.generateWave(10);

      expectEquals("signature", signature(w1), signature(w2));
    });

    test("different seeds => usually different signature (not guaranteed, but should often differ)", () -> {
      var gen1 = new SimpleWaveGenerator(1L);
      var gen2 = new SimpleWaveGenerator(2L);

      Team w1 = gen1.generateWave(25);
      Team w2 = gen2.generateWave(25);

      // On n'échoue pas systématiquement si égal (possible mais rare),
      // mais on log pour visibilité.
      String s1 = signature(w1);
      String s2 = signature(w2);

      if (s1.equals(s2)) {
        System.out.println("WARN: same signature with different seeds (rare): " + s1);
      } else {
        expectTrue("signatures differ", true);
      }
    });

    test("generated wave stays within the budget and stops only at six mobs or when nothing fits", () -> {
      var gen = new SimpleWaveGenerator(42L);

      for (int total = 1; total <= 30; total++) {
        Team wave = gen.generateWave(total);
        int sum = sumValues(wave);
        expectTrue("sum stays within total for total=" + total, sum <= total);
        expectTrue("wave is non-empty for total=" + total, wave.size() > 0);
        expectTrue("wave size <= 6 for total=" + total, wave.size() <= 6);
        expectTrue(
            "wave stops for a valid reason for total=" + total,
            sum == total || wave.size() == 6 || total - sum < lowestNonBossValue());
      }
    });

    test("generated waves never exceed six mobs", () -> {
      Team simpleWave = new SimpleWaveGenerator(42L).generateWave(30);
      Team bossWave = new BossWaveGenerator(42L).generateWave(30);

      expectTrue("simple wave size <= 6", simpleWave.size() <= 6);
      expectTrue("boss wave size <= 6", bossWave.size() <= 6);
    });

    test("boss generator should contain at least one boss when totalValue allows it", () -> {
      var gen = new BossWaveGenerator(42L);
      Team wave = gen.generateWave(20);
      expectTrue("contains boss", containsBoss(wave));
    });

    test("generated mobs always receive an AI profile", () -> {
      Team wave = new ThemedWaveGenerator(42L).generateWave(50);
      expectTrue(
          "all mobs have ai",
          wave.getMembers().stream()
              .allMatch(member -> member instanceof Mob mob && mob.getAiType() != null));
    });

    test("themed generator keeps the same faction for five consecutive waves", () -> {
      var gen = new ThemedWaveGenerator(42L);

      ThemedWave first = gen.generateThemedWave(20);
      for (int i = 0; i < 3; i++) {
        ThemedWave next = gen.generateThemedWave(20 + i);
        expectEquals("same category for wave " + (i + 2), first.category().name(), next.category().name());
        expectFalse("not final wave yet", next.finalWaveInTheme());
      }

      ThemedWave fifth = gen.generateThemedWave(24);
      expectEquals("same category for fifth wave", first.category().name(), fifth.category().name());
      expectTrue("fifth wave is final in theme", fifth.finalWaveInTheme());
    });

    test("themed generator last wave includes a harder mob for that faction", () -> {
      var gen = new ThemedWaveGenerator(99L);
      ThemedWave themedWave = null;
      for (int i = 0; i < 5; i++) {
        themedWave = gen.generateThemedWave(50);
      }

      expectTrue("final themed wave exists", themedWave != null && themedWave.finalWaveInTheme());
      expectTrue("contains hard mob", containsTierAtLeast(themedWave.team(), MobTier.LATE));
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests Step6 ont échoué (" + failed + ")");
    }
  }

  private static String signature(Team team) {
    StringBuilder sb = new StringBuilder();
    boolean first = true;
    for (var c : team.getMembers()) {
      if (!(c instanceof Mob mob)) {
        throw new AssertionError("Team contient un membre non-Mob: " + c.getClass().getName());
      }
      if (!first) sb.append(",");
      sb.append(mob.getName());
      first = false;
    }
    return sb.toString();
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

  private static int lowestNonBossValue() {
    return MobsDictionary.mobs.stream()
        .filter(m -> !m.isBoss())
        .mapToInt(Mob::getValue)
        .min()
        .orElseThrow();
  }

  private static boolean containsTierAtLeast(Team team, MobTier tier) {
    for (var c : team.getMembers()) {
      if (c instanceof Mob mob && mob.getTier().ordinal() >= tier.ordinal()) {
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

  private static void expectEquals(String label, int expected, int actual) {
    if (expected != actual) {
      throw new AssertionError(label + " expected " + expected + " but was " + actual);
    }
  }

  private static void expectEquals(String label, String expected, String actual) {
    if (expected == null ? actual != null : !expected.equals(actual)) {
      throw new AssertionError(label + " expected " + expected + " but was " + actual);
    }
  }

  private static void expectFalse(String label, boolean value) {
    if (value) {
      throw new AssertionError(label + " expected false but was true");
    }
  }
}
