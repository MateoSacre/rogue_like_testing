package RogueLite.waves;

import RogueLite.Debug;
import RogueLite.characters.mobs.Mob;
import RogueLite.characters.mobs.MobAiType;
import RogueLite.characters.mobs.MobCategory;
import RogueLite.characters.mobs.MobTier;
import RogueLite.characters.mobs.MobsDictionary;
import RogueLite.teams.MobTeam;
import RogueLite.teams.Team;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Random;

public class ThemedWaveGenerator extends SimpleWaveGenerator {

  private static final int THEME_LENGTH = 5;

  private MobCategory currentCategory;
  private int wavesRemainingInTheme;

  public ThemedWaveGenerator() {
    super();
  }

  public ThemedWaveGenerator(Random random) {
    super(random);
  }

  public ThemedWaveGenerator(Long seed) {
    super(seed);
  }

  @Override
  public Team generateWave(int totalValue) {
    return generateThemedWave(totalValue).team();
  }

  public ThemedWave generateThemedWave(int totalValue) {
    if (wavesRemainingInTheme == 0) {
      currentCategory = pickRandomCategory();
      wavesRemainingInTheme = THEME_LENGTH;
      Debug.log("ThemedWaveGenerator", "Starting new theme with category=" + currentCategory);
    }

    boolean isFinalWaveInTheme = wavesRemainingInTheme == 1;
    Debug.log(
        "ThemedWaveGenerator",
        "Generating themed wave value=" + totalValue + " category=" + currentCategory
            + " finalWave=" + isFinalWaveInTheme + " remainingInTheme=" + wavesRemainingInTheme);
    int index = 1;
    int remainingValue = totalValue;
    int remainingSlots = MAX_WAVE_SIZE;
    List<Mob> wave = new ArrayList<>();

    if (isFinalWaveInTheme) {
      Mob hardMob = selectHardMob(index, totalValue, currentCategory);
      if (hardMob != null) {
        wave.add(hardMob);
        Debug.log(
            "ThemedWaveGenerator",
            "Inserted hard mob " + hardMob.getName() + " value=" + hardMob.getValue() + " ai=" + hardMob.getAiType());
        remainingValue -= hardMob.getValue();
        remainingSlots--;
        index++;
      }
    }

    while (remainingValue > 0 && remainingSlots > 0) {
      Mob mob = selectFactionMob(index, remainingValue, currentCategory, false);
      if (mob == null) {
        Debug.log("ThemedWaveGenerator", "Stopping generation: no valid mob for remainingValue=" + remainingValue);
        break;
      }
      wave.add(mob);
      Debug.log(
          "ThemedWaveGenerator",
          "Added mob " + mob.getName() + " value=" + mob.getValue() + " ai=" + mob.getAiType());
      remainingValue -= mob.getValue();
      remainingSlots--;
      index++;
    }

    wavesRemainingInTheme--;
    Debug.log("ThemedWaveGenerator", "Theme waves remaining after generation=" + wavesRemainingInTheme);
    return new ThemedWave(new MobTeam("Wave", List.copyOf(wave)), currentCategory, isFinalWaveInTheme);
  }

  public MobCategory getCurrentCategory() {
    return currentCategory;
  }

  public int getWavesRemainingInTheme() {
    return wavesRemainingInTheme;
  }

  private MobCategory pickRandomCategory() {
    MobCategory[] categories = MobCategory.values();
    return categories[random.nextInt(categories.length)];
  }

  private Mob selectHardMob(int index, int totalValue, MobCategory category) {
    List<MobTier> preferredTiers = getHardMobPriority(totalValue);
    for (MobTier tier : preferredTiers) {
      List<Mob> candidates =
          MobsDictionary.getMobsByCategoryAndTier(category, tier).stream()
              .filter(m -> m.getValue() <= totalValue)
              .toList();
      if (!candidates.isEmpty()) {
        Mob selected = candidates.get(random.nextInt(candidates.size()));
        Mob mob = new Mob(selected);
        mob.setName(index + "-" + mob.getName());
        mob.setAiType(MobAiType.randomFor(mob, random));
        Debug.log(
            "ThemedWaveGenerator",
            "Picked hard mob template=" + selected.getName() + " tier=" + tier + " ai=" + mob.getAiType());
        return mob;
      }
    }
    return selectFactionMob(index, totalValue, category, true);
  }

  private List<MobTier> getHardMobPriority(int totalValue) {
    if (totalValue >= 800) {
      return List.of(
          MobTier.EVENT_BOSS,
          MobTier.CATASTROPHE_BOSS,
          MobTier.APEX,
          MobTier.LATE,
          MobTier.ELITE,
          MobTier.MID,
          MobTier.EARLY);
    }
    if (totalValue >= 300) {
      return List.of(
          MobTier.CATASTROPHE_BOSS,
          MobTier.APEX,
          MobTier.LATE,
          MobTier.ELITE,
          MobTier.MID,
          MobTier.EARLY);
    }
    if (totalValue >= 100) {
      return List.of(MobTier.APEX, MobTier.LATE, MobTier.ELITE, MobTier.MID, MobTier.EARLY);
    }
    if (totalValue >= 30) {
      return List.of(MobTier.LATE, MobTier.ELITE, MobTier.MID, MobTier.EARLY);
    }
    return List.of(MobTier.ELITE, MobTier.MID, MobTier.EARLY);
  }

  private Mob selectFactionMob(
      int index, int remainingValue, MobCategory category, boolean bossesAllowed) {
    Mob selected =
        findMobInCategoryWithinWindow(remainingValue, category, bossesAllowed);
    if (selected == null) {
      return null;
    }
    Mob mob = new Mob(selected);
    mob.setName(index + "-" + mob.getName());
    mob.setAiType(MobAiType.randomFor(mob, random));
    Debug.log(
        "ThemedWaveGenerator",
        "Selected themed mob template=" + selected.getName() + " remainingValue=" + remainingValue + " ai=" + mob.getAiType());
    return mob;
  }

  private Mob findMobInCategoryWithinWindow(
      int remainingValue, MobCategory category, boolean bossesAllowed) {
    double minimumTargetValue = remainingValue / 4.0;
    List<Mob> categoryPool = MobsDictionary.getMobsByCategory(category);

    List<Mob> mobsWithinWindow =
        categoryPool.stream()
            .filter(m -> m.getValue() <= remainingValue)
            .filter(m -> bossesAllowed || !m.isBoss())
            .filter(m -> m.getValue() >= minimumTargetValue)
            .toList();

    if (!mobsWithinWindow.isEmpty()) {
      return mobsWithinWindow.get(random.nextInt(mobsWithinWindow.size()));
    }

    return categoryPool.stream()
        .filter(m -> m.getValue() <= remainingValue)
        .filter(m -> bossesAllowed || !m.isBoss())
        .min(Comparator.comparingInt(Mob::getValue))
        .orElse(null);
  }
}
