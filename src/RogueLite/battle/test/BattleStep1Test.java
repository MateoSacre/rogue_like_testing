package RogueLite.battle.test;

import RogueLite.battle.Battle;
import RogueLite.characters.hero.Hero;
import RogueLite.characters.mobs.Mob;
import RogueLite.teams.HeroTeam;
import RogueLite.teams.MobTeam;
import RogueLite.teams.Team;

import java.util.List;

public final class BattleStep1Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Battle - Step 4 tests (Team interface) ===");

    test("fight rejects null teams", () -> {
      Team t = new HeroTeam("T", List.of(new Hero("A", 10, 1, 0)));
      expectThrows(IllegalArgumentException.class, () -> Battle.fight(null, t));
      expectThrows(IllegalArgumentException.class, () -> Battle.fight(t, null));
    });

    test("1v1 deterministic: stronger hero wins", () -> {
      Hero hero = new Hero("Hero", 10, 6, 0);
      Mob slime = new Mob("Slime", 10, 2, 0);

      Team heroes = new HeroTeam("Heroes", List.of(hero));
      Team monsters = new MobTeam("Monsters", List.of(slime));

      Team winner = Battle.fight(heroes, monsters);

      expectTrue("winner is Heroes", winner == heroes);
      expectTrue("hero alive", hero.isAlive());
      expectFalse("slime dead", slime.isAlive());
      expectEquals("slime hp", 0.0, slime.getHp());
    });

    test("2v2: stops when one team is defeated", () -> {
      Hero a1 = new Hero("A1", 10, 10, 0);
      Hero a2 = new Hero("A2", 10, 1, 0);

      Mob b1 = new Mob("B1", 5, 1, 0);
      Mob b2 = new Mob("B2", 50, 1, 0);

      Team teamA = new HeroTeam("A", List.of(a1, a2));
      Team teamB = new MobTeam("B", List.of(b1, b2));

      Team winner = Battle.fight(teamA, teamB);

      expectTrue("winner is A", winner == teamA);
      expectTrue("teamB is defeated", teamB.isDefeated());
      expectFalse("b1 dead", b1.isAlive());
      expectFalse("b2 dead", b2.isAlive());
    });

    test("characters already dead at start are skipped", () -> {
      Hero a1 = new Hero("A1", 10, 5, 0);
      Hero a2 = new Hero("A2", 10, 5, 0);
      a1.takeDamage(999); // dead

      Mob b1 = new Mob("B1", 10, 1, 0);

      Team teamA = new HeroTeam("A", List.of(a1, a2));
      Team teamB = new MobTeam("B", List.of(b1));

      Team winner = Battle.fight(teamA, teamB);

      expectTrue("winner is A", winner == teamA);
      expectTrue("a2 alive", a2.isAlive());
      expectFalse("b1 dead", b1.isAlive());
    });

    test("fight handles team already defeated at start", () -> {
      Hero a1 = new Hero("A1", 10, 5, 0);
      a1.takeDamage(999);

      Mob b1 = new Mob("B1", 10, 1, 0);

      Team teamA = new HeroTeam("A", List.of(a1));
      Team teamB = new MobTeam("B", List.of(b1));

      Team winner = Battle.fight(teamA, teamB);

      expectTrue("winner is B", winner == teamB);
      expectTrue("b1 still alive", b1.isAlive());
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests BattleStep1Test ont échoué (" + failed + ")");
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

  private static void expectEquals(String label, double expected, double actual) {
    double eps = 0.000001;
    if (Math.abs(expected - actual) > eps) {
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

  private BattleStep1Test() {
  }
}