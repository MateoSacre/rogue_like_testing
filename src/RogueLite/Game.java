package RogueLite;

import RogueLite.battle.Battle;
import RogueLite.characters.hero.Hero;
import RogueLite.characters.skills.TargetType;
import RogueLite.characters.skills.defensive.Blessing;
import RogueLite.characters.skills.healing.SimpleHeal;
import RogueLite.characters.skills.offensive.Cut;
import RogueLite.characters.skills.offensive.Explosion;
import RogueLite.characters.skills.offensive.PoisonArrow;
import RogueLite.characters.skills.offensive.PowerStrike;
import RogueLite.teams.HeroTeam;
import RogueLite.waves.ThemedWave;
import RogueLite.waves.ThemedWaveGenerator;
import java.time.OffsetDateTime;
import java.util.List;

public class Game {

  private static final int THEME_LENGTH = 5;

  public static void main(String[] args) {
    final boolean IS_TEST_MODE = false;
    final long seed = OffsetDateTime.now().toEpochSecond();

    HeroTeam baseTeam = getBaseTeam();
    ThemedWaveGenerator waveGenerator =
        IS_TEST_MODE ? new ThemedWaveGenerator() : new ThemedWaveGenerator(seed);
    int waveCounter = 1;
    while (!baseTeam.isDefeated()) {
      int themeWaveIndex = ((waveCounter - 1) % THEME_LENGTH) + 1;
      int waveValue = waveCounter;
      ThemedWave wave = waveGenerator.generateThemedWave(waveValue);

      System.out.println(
          "-- Wave "
              + waveCounter
              + " ["
              + wave.category()
              + " "
              + themeWaveIndex
              + "/"
              + THEME_LENGTH
              + "] --");

      Battle.fight(baseTeam, wave.team());
      if (!baseTeam.isDefeated()) {
        int waveXp = Math.floorDiv((waveCounter * 10), baseTeam.getAliveMembers().size());
        if (wave.finalWaveInTheme()) {
          waveXp *= 2;
        }
        final int earnedXp = waveXp;
        baseTeam
            .getAliveMembers()
            .forEach(
                h -> {
                  h.addXp(earnedXp);
                  h.heal(h.getMaxHp() / 10);
                });
      }
      waveCounter++;
    }
  }

  private static HeroTeam getBaseTeam() {
    return new HeroTeam(
        "Base Team",
        List.of(
            new Hero(
                "Paladin",
                25,
                3,
                7,
                new Blessing(TargetType.ALLY_SINGLE_LOWEST_HP, "Protect", 3, 10, 3)),
            new Hero(
                "Hero", 20, 5, 5, new PowerStrike(TargetType.ENNEMY_SINGLE, "Power slash", 3, 3)),
            new Hero(
                "Warrior",
                15,
                7,
                3,
                new Cut(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Deep cut", 4, 5, 5)),
            new Hero(
                "Artificier",
                10,
                10,
                5,
                new Explosion(TargetType.ENNEMY_TEAM, "Nuke", 10, null, 3D, true)),
            new Hero(
                "Archer",
                15,
                5,
                5,
                new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Poison Arrow", 3, 5, 2)),
            new Hero(
                "Priest",
                15,
                2,
                3,
                new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Magic Healing", 3, 30D, true)),
            new Hero(
                "Mage",
                15,
                8,
                2,
                new Explosion(TargetType.ENNEMY_MULTI_TARGET, "Triple Beam", 5, 3, 16D, false))));
  }
}
