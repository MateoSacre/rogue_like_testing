package RogueLite.teams.test;

import RogueLite.characters.Character;
import RogueLite.characters.hero.Hero;
import RogueLite.characters.mobs.Mob;
import RogueLite.teams.HeroTeam;
import RogueLite.teams.MobTeam;
import RogueLite.teams.Team;

import java.util.ArrayList;
import java.util.List;

public final class TeamStep1Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Team - Step tests (HeroTeam & MobTeam) ===");

    // ---- HeroTeam constructor validation ----
    test("HeroTeam: constructor rejects invalid name", () -> {
      List<Hero> members = List.of(new Hero("A", 10, 1, 0));
      expectThrows(IllegalArgumentException.class, () -> new HeroTeam(null, members));
      expectThrows(IllegalArgumentException.class, () -> new HeroTeam("   ", members));
    });

    test("HeroTeam: constructor rejects null/empty members", () -> {
      expectThrows(IllegalArgumentException.class, () -> new HeroTeam("Heroes", null));
      expectThrows(IllegalArgumentException.class, () -> new HeroTeam("Heroes", List.of()));
    });

    test("HeroTeam: constructor rejects null member", () -> {
      List<Hero> members = new ArrayList<>();
      members.add(new Hero("A", 10, 1, 0));
      members.add(null);
      expectThrows(IllegalArgumentException.class, () -> new HeroTeam("Heroes", members));
    });

    // ---- MobTeam constructor validation ----
    test("MobTeam: constructor rejects invalid name", () -> {
      List<Mob> members = List.of(new Mob("A", 10, 1, 0));
      expectThrows(IllegalArgumentException.class, () -> new MobTeam(null, members));
      expectThrows(IllegalArgumentException.class, () -> new MobTeam("   ", members));
    });

    test("MobTeam: constructor rejects null/empty members", () -> {
      expectThrows(IllegalArgumentException.class, () -> new MobTeam("Monsters", null));
      expectThrows(IllegalArgumentException.class, () -> new MobTeam("Monsters", List.of()));
    });

    test("MobTeam: constructor rejects null member", () -> {
      List<Mob> members = new ArrayList<>();
      members.add(new Mob("A", 10, 1, 0));
      members.add(null);
      expectThrows(IllegalArgumentException.class, () -> new MobTeam("Monsters", members));
    });

    // ---- getMembers must be unmodifiable ----
    test("HeroTeam: getMembers returns unmodifiable view", () -> {
      Team team = new HeroTeam("Heroes", List.of(
          new Hero("A", 10, 1, 0),
          new Hero("B", 10, 1, 0)
      ));
      expectThrows(UnsupportedOperationException.class, () -> team.getMembers().add(new Hero("C", 10, 1, 0)));
    });

    test("MobTeam: getMembers returns unmodifiable view", () -> {
      Team team = new MobTeam("Monsters", List.of(
          new Mob("A", 10, 1, 0),
          new Mob("B", 10, 1, 0)
      ));
      expectThrows(UnsupportedOperationException.class, () -> team.getMembers().add(new Mob("C", 10, 1, 0)));
    });

    // ---- isDefeated / getAliveMembers ----
    test("HeroTeam: isDefeated false when at least one alive", () -> {
      Hero a = new Hero("A", 10, 1, 0);
      Hero b = new Hero("B", 10, 1, 0);
      b.takeDamage(999);

      Team team = new HeroTeam("Heroes", List.of(a, b));
      expectFalse("isDefeated", team.isDefeated());
      expectEquals("alive count", 1, team.getAliveMembers().size());
      expectEquals("livingCount", 1, team.livingCount());
    });

    test("MobTeam: isDefeated true when all dead", () -> {
      Mob a = new Mob("A", 10, 1, 0);
      Mob b = new Mob("B", 10, 1, 0);
      a.takeDamage(999);
      b.takeDamage(999);

      Team team = new MobTeam("Monsters", List.of(a, b));
      expectTrue("isDefeated", team.isDefeated());
      expectEquals("alive count", 0, team.getAliveMembers().size());
      expectEquals("pickFirstAlive", null, team.pickFirstAlive());
      expectEquals("livingCount", 0, team.livingCount());
    });

    // ---- pickFirstAlive order + exclude ----
    test("HeroTeam: pickFirstAlive returns first alive in order", () -> {
      Hero a = new Hero("A", 10, 1, 0);
      Hero b = new Hero("B", 10, 1, 0);
      Hero c = new Hero("C", 10, 1, 0);
      a.takeDamage(999); // dead

      Team team = new HeroTeam("Heroes", List.of(a, b, c));
      Character picked = team.pickFirstAlive();
      expectTrue("picked is B", picked == b);
    });

    test("HeroTeam: pickFirstAlive(exclude) skips excluded", () -> {
      Hero a = new Hero("A", 10, 1, 0);
      Hero b = new Hero("B", 10, 1, 0);
      Hero c = new Hero("C", 10, 1, 0);

      Team team = new HeroTeam("Heroes", List.of(a, b, c));
      Character picked = team.pickFirstAlive(b);
      expectTrue("picked is A", picked == a);
    });

    test("MobTeam: pickFirstAlive(exclude) returns null if only excluded alive", () -> {
      Mob a = new Mob("A", 10, 1, 0);
      Mob b = new Mob("B", 10, 1, 0);
      b.takeDamage(999); // dead

      Team team = new MobTeam("Monsters", List.of(a, b));
      Character picked = team.pickFirstAlive(a);
      expectEquals("picked", null, picked);
    });

    // ---- size ----
    test("Team size returns members size", () -> {
      Team heroes = new HeroTeam("Heroes", List.of(new Hero("A", 10, 1, 0), new Hero("B", 10, 1, 0)));
      Team mobs = new MobTeam("Monsters", List.of(new Mob("A", 10, 1, 0)));

      expectEquals("heroes size", 2, heroes.size());
      expectEquals("mobs size", 1, mobs.size());
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests TeamStep1Test ont échoué (" + failed + ")");
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

  private static void expectEquals(String label, Object expected, Object actual) {
    if (expected == null ? actual != null : !expected.equals(actual)) {
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

  private TeamStep1Test() {
  }
}