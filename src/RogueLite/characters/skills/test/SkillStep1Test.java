package RogueLite.characters.skills.test;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import RogueLite.characters.skills.healing.SimpleHeal;
import RogueLite.characters.skills.offensive.Explosion;
import RogueLite.characters.skills.offensive.PowerStrike;

import java.util.List;

public final class SkillStep1Test {

  private static int passed = 0;
  private static int failed = 0;

  public static void run() {
    passed = 0;
    failed = 0;

    System.out.println("=== Skills - All tests (offensive + healing) ===");

    test("skills start on cooldown (not immediately available)", () -> {
      Character p = new Character("P", new PowerStrike());
      expectTrue("initial cd > 0", p.getSkill().getCooldownRemaining() > 0);
      expectFalse("canUseSkill is false", p.canUseSkill());
    });

    test("cooldown reaches 0 after enough ticks (skill becomes usable)", () -> {
      Character p = new Character("P", new PowerStrike());
      int start = p.getSkill().getCooldownRemaining();
      expectTrue("start > 0", start > 0);

      for (int i = 0; i < start; i++) {
        p.applySkillCooldown();
      }

      expectEquals("cd after ticks", 0, p.getSkill().getCooldownRemaining());
      expectTrue("canUseSkill", p.canUseSkill());
    });

    test("Skill instances are NOT shared between characters (via newInstance)", () -> {
      Skill prototype = new PowerStrike();

      Character c1 = new Character("C1", prototype);
      Character c2 = new Character("C2", prototype);

      expectTrue("skill instance differs", c1.getSkill() != c2.getSkill());

      int c2Start = c2.getSkill().getCooldownRemaining();
      int c1Start = c1.getSkill().getCooldownRemaining();
      expectTrue("both start cooldown >= 0", c1Start >= 0 && c2Start >= 0);

      // On tick le cooldown du skill de c1 seulement
      c1.applySkillCooldown();
      c1.applySkillCooldown();

      // c2 ne doit pas avoir bougé
      expectEquals("c2 cd unchanged", c2Start, c2.getSkill().getCooldownRemaining());
    });

    test("PowerStrike: targetType is ENNEMY_SINGLE", () -> {
      Skill s = new PowerStrike();
      expectEquals("targetType", TargetType.ENNEMY_SINGLE, s.getTargetType());
    });

    test("PowerStrike: use() deals damage to one target", () -> {
      Character caster = new Character("Caster", new PowerStrike());
      Character target = new Character("Target", 20, 3, 1, null);

      double hpBefore = target.getHp();
      caster.useSkill(List.of(target));
      double hpAfter = target.getHp();

      expectTrue("target took damage", hpAfter < hpBefore);
      expectTrue("hp not negative", hpAfter >= 0);
    });

    test("PowerStrike: initiateCooldown resets to cooldownValue", () -> {
      PowerStrike s = new PowerStrike();
      Character caster = new Character("Caster", s);

      // On tick un peu, puis on ré-initie
      caster.applySkillCooldown();
      caster.applySkillCooldown();

      caster.initiateSkillCooldown();
      expectEquals("cd == cooldownValue", caster.getSkill().getCooldownValue(), caster.getSkill().getCooldownRemaining());
    });

    test("Explosion: targetType is ENNEMY_TEAM", () -> {
      Skill s = new Explosion();
      expectEquals("targetType", TargetType.ENNEMY_TEAM, s.getTargetType());
    });

    test("Explosion: use() deals damage to multiple targets", () -> {
      Character caster = new Character("Mage", new Explosion());
      Character t1 = new Character("T1", 20, 3, 1, null);
      Character t2 = new Character("T2", 20, 3, 1, null);
      Character t3 = new Character("T3", 20, 3, 1, null);

      double b1 = t1.getHp();
      double b2 = t2.getHp();
      double b3 = t3.getHp();

      caster.useSkill(List.of(t1, t2, t3));

      expectTrue("t1 damaged", t1.getHp() < b1);
      expectTrue("t2 damaged", t2.getHp() < b2);
      expectTrue("t3 damaged", t3.getHp() < b3);
    });

    test("Explosion: ENNEMY_MULTI_TARGET respects nbTargets", () -> {
      Character caster =
          new Character(
              "Mage",
              new Explosion(
                  TargetType.ENNEMY_MULTI_TARGET, "Mini Explosion", 3, 2, 4.0, false));
      Character t1 = new Character("T1", 20, 3, 1, null);
      Character t2 = new Character("T2", 20, 3, 1, null);
      Character t3 = new Character("T3", 20, 3, 1, null);

      double b1 = t1.getHp();
      double b2 = t2.getHp();
      double b3 = t3.getHp();

      caster.useSkill(List.of(t1, t2, t3));

      expectTrue("t1 damaged", t1.getHp() < b1);
      expectTrue("t2 damaged", t2.getHp() < b2);
      expectEquals("t3 unchanged", b3, t3.getHp());
    });

    test("SimpleHeal: targetType is ALLY_SINGLE_LOWEST_HP (as implemented)", () -> {
      Skill s = new SimpleHeal();
      expectEquals("targetType", TargetType.ALLY_SINGLE_LOWEST_HP, s.getTargetType());
    });

    test("SimpleHeal: use() increases hp (when damaged) and does not exceed maxHp", () -> {
      Character healer = new Character("Priest", new SimpleHeal());

      healer.takeDamage(10);
      double before = healer.getHp();
      expectTrue("damaged", before < healer.getMaxHp());

      healer.useSkill(List.of(healer));
      double after = healer.getHp();

      expectTrue("healed", after > before);
      expectTrue("capped to maxHp", after <= healer.getMaxHp());
    });

    test("SimpleHeal: shouldUse is false when target at full hp (SELF)", () -> {
      Character healer = new Character("Priest", new SimpleHeal());
      boolean should = healer.getSkill().shouldUse(healer, List.of(healer));
      expectFalse("shouldUse", should);
    });

    System.out.println();
    System.out.println("=== Summary ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);

    if (failed > 0) {
      throw new AssertionError("Des tests SkillsAllTest ont échoué (" + failed + ")");
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
}
