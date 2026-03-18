package RogueLite.characters.mobs;

import RogueLite.Debug;
import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.TargetType;
import RogueLite.characters.skills.defensive.Blessing;
import RogueLite.characters.skills.healing.SimpleHeal;
import RogueLite.characters.skills.offensive.Cut;
import RogueLite.characters.skills.offensive.Explosion;
import RogueLite.characters.skills.offensive.PoisonArrow;
import RogueLite.characters.skills.offensive.PowerStrike;
import RogueLite.characters.skills.offensive.Splash;
import java.util.Collections;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class MobsDictionary {
  public static final List<Mob> mobs =
      Stream.of(
              buildMonsters(),
              buildBandits(),
              buildCultists(),
              buildAncientBeasts(),
              buildMages(),
              buildEmpire(),
              buildGhosts(),
              buildAncientMech(),
              buildGiants())
          .flatMap(List::stream)
          .toList();

  public static final Map<MobCategory, List<Mob>> mobsByCategory =
      Collections.unmodifiableMap(
          mobs.stream()
              .collect(
                  Collectors.groupingBy(
                      Mob::getCategory,
                      () -> new EnumMap<>(MobCategory.class),
                      Collectors.toUnmodifiableList())));

  static {
    for (MobCategory category : MobCategory.values()) {
      validateFactionRoster(category);
    }
  }

  public static List<Mob> getMobsByCategory(MobCategory category) {
    return mobsByCategory.getOrDefault(category, List.of());
  }

  public static List<Mob> getMobsByCategoryAndTier(MobCategory category, MobTier tier) {
    return getMobsByCategory(category).stream().filter(m -> m.getTier() == tier).toList();
  }

  private static void validateFactionRoster(MobCategory category) {
    List<Mob> roster = getMobsByCategory(category);
    Debug.log("MobsDictionary", "Validating category=" + category + " size=" + roster.size());
    requireTierCount(category, roster, MobTier.ELITE, 3);
    requireTierCount(category, roster, MobTier.LATE, 3);
    requireTierCount(category, roster, MobTier.APEX, 2);
    requireTierCount(category, roster, MobTier.CATASTROPHE_BOSS, 1);
    requireTierCount(category, roster, MobTier.EVENT_BOSS, 1);
  }

  private static void requireTierCount(
      MobCategory category, List<Mob> roster, MobTier tier, int minimumCount) {
    long count = roster.stream().filter(m -> m.getTier() == tier).count();
    if (count < minimumCount) {
      throw new IllegalStateException(
          "Category " + category + " requires at least " + minimumCount + " " + tier + " mobs");
    }
  }

  private static List<Mob> buildMonsters() {
    return List.of(
        mob("Slime", 3, 1, 0, 1, new Splash(), MobCategory.MONSTERS, MobTier.EARLY),
        mob("Dire Wolf", 10, 3, 1, 4, MobCategory.MONSTERS, MobTier.MID),
        mob("Feral Alpha", 24, 8, 2, 12, MobCategory.MONSTERS, MobTier.ELITE),
        mob(
            "Venommaw",
            22,
            7,
            2,
            15,
            new PoisonArrow(TargetType.ENNEMY_SINGLE, "Venom Bite", 3, 4, 2),
            MobCategory.MONSTERS,
            MobTier.ELITE),
        mob("Bonehide", 30, 8, 4, 18, MobCategory.MONSTERS, MobTier.ELITE),
        mob("Marsh Terror", 55, 14, 5, 32, MobCategory.MONSTERS, MobTier.LATE),
        mob("Ravager", 60, 15, 6, 40, MobCategory.MONSTERS, MobTier.LATE),
        mob("Abyss Stalker", 68, 18, 5, 48, MobCategory.MONSTERS, MobTier.LATE),
        mob("World Eater Spawn", 180, 30, 10, 120, MobCategory.MONSTERS, MobTier.APEX),
        mob(
            "Star Devourer",
            280,
            36,
            14,
            180,
            new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Star Rot", 2, 8, 8),
            MobCategory.MONSTERS,
            MobTier.APEX),
        boss("World Ender", 920, 84, 38, 600, MobCategory.MONSTERS, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Omega Chimera", 1500, 115, 52, 1000, MobCategory.MONSTERS, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildBandits() {
    return List.of(
        mob("Cutpurse", 5, 1, 1, 1, MobCategory.BANDITS, MobTier.EARLY),
        mob("Highway Scout", 10, 3, 1, 4, MobCategory.BANDITS, MobTier.MID),
        mob(
            "Assassin",
            17,
            7,
            1,
            12,
            new Cut(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Jagged Shiv", 4, 3, 2),
            MobCategory.BANDITS,
            MobTier.ELITE),
        mob("Saboteur", 20, 7, 2, 15, MobCategory.BANDITS, MobTier.ELITE),
        mob("Enforcer", 26, 9, 4, 18, MobCategory.BANDITS, MobTier.ELITE),
        mob("Dread Captain", 50, 14, 6, 32, MobCategory.BANDITS, MobTier.LATE),
        mob(
            "Blackblade Duelist",
            52,
            16,
            5,
            40,
            new PowerStrike(TargetType.ENNEMY_SINGLE, "Execution Lunge", 3, 2.8),
            MobCategory.BANDITS,
            MobTier.LATE),
        mob("War Wagon", 75, 12, 9, 48, MobCategory.BANDITS, MobTier.LATE),
        mob("Crimson Marshal", 210, 32, 12, 120, MobCategory.BANDITS, MobTier.APEX),
        mob("Kingpin of Ash", 260, 34, 16, 170, MobCategory.BANDITS, MobTier.APEX),
        boss("Tyrant of Knives", 760, 76, 32, 520, MobCategory.BANDITS, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Crownless Emperor", 1400, 108, 46, 920, MobCategory.BANDITS, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildCultists() {
    return List.of(
        mob("Initiate", 5, 1, 0, 1, MobCategory.CULTISTS, MobTier.EARLY),
        mob(
            "Acolyte",
            12,
            3,
            2,
            4,
            new Blessing(TargetType.ALLY_TEAM, "Dark Ward", 4, 2, 2),
            MobCategory.CULTISTS,
            MobTier.MID),
        mob(
            "Blood Priest",
            24,
            7,
            3,
            12,
            new Blessing(TargetType.ALLY_TEAM, "Blood Ward", 4, 3, 3),
            MobCategory.CULTISTS,
            MobTier.ELITE),
        mob("Hex Binder", 22, 8, 2, 15, MobCategory.CULTISTS, MobTier.ELITE),
        mob(
            "Plague Cantor",
            26,
            8,
            3,
            18,
            new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Virulent Hymn", 3, 5, 2),
            MobCategory.CULTISTS,
            MobTier.ELITE),
        mob(
            "Void Caller",
            42,
            13,
            4,
            32,
            new Explosion(TargetType.ENNEMY_TEAM, "Void Pulse", 5, null, 8D, false),
            MobCategory.CULTISTS,
            MobTier.LATE),
        mob(
            "Sacrificial Blade",
            50,
            15,
            5,
            40,
            new Cut(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Bloodletting", 3, 5, 4),
            MobCategory.CULTISTS,
            MobTier.LATE),
        mob("Ash Prophet", 55, 16, 6, 48, MobCategory.CULTISTS, MobTier.LATE),
        mob("Eclipse Hierophant", 200, 31, 13, 130, MobCategory.CULTISTS, MobTier.APEX),
        mob("Demon Vessel", 280, 38, 15, 180, MobCategory.CULTISTS, MobTier.APEX),
        boss("Apocalypse Choir", 820, 78, 34, 560, MobCategory.CULTISTS, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Star Apostle", 1450, 110, 48, 980, MobCategory.CULTISTS, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildAncientBeasts() {
    return List.of(
        mob("Hatchling", 5, 1, 0, 1, MobCategory.ANCIENT_BEASTS, MobTier.EARLY),
        mob("Scale Hunter", 12, 4, 1, 4, MobCategory.ANCIENT_BEASTS, MobTier.MID),
        mob("Feral Gryphon", 24, 8, 2, 12, MobCategory.ANCIENT_BEASTS, MobTier.ELITE),
        mob(
            "Basilisk",
            28,
            8,
            3,
            15,
            new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Stone Venom", 3, 5, 2),
            MobCategory.ANCIENT_BEASTS,
            MobTier.ELITE),
        mob("Stonehorn", 34, 9, 5, 18, MobCategory.ANCIENT_BEASTS, MobTier.ELITE),
        mob("Great Roc", 60, 15, 5, 32, MobCategory.ANCIENT_BEASTS, MobTier.LATE),
        mob("Sabertooth Prime", 66, 17, 5, 40, MobCategory.ANCIENT_BEASTS, MobTier.LATE),
        mob("Mammoth King", 84, 16, 8, 48, MobCategory.ANCIENT_BEASTS, MobTier.LATE),
        mob("Moonfang Leviathan", 210, 32, 14, 125, MobCategory.ANCIENT_BEASTS, MobTier.APEX),
        mob("Sunscale Behemoth", 300, 36, 18, 175, MobCategory.ANCIENT_BEASTS, MobTier.APEX),
        boss("Kraken Monarch", 880, 82, 36, 580, MobCategory.ANCIENT_BEASTS, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Dream Serpent", 1500, 114, 50, 1020, MobCategory.ANCIENT_BEASTS, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildMages() {
    return List.of(
        mob("Spark Familiar", 4, 1, 0, 1, MobCategory.MAGES, MobTier.EARLY),
        mob("Rune Adept", 12, 4, 1, 4, MobCategory.MAGES, MobTier.MID),
        mob(
            "Frost Adept",
            22,
            7,
            2,
            12,
            new Explosion(TargetType.ENNEMY_MULTI_TARGET, "Ice Shards", 4, 2, 6D, false),
            MobCategory.MAGES,
            MobTier.ELITE),
        mob(
            "Pyromancer",
            24,
            8,
            2,
            15,
            new Explosion(TargetType.ENNEMY_TEAM, "Fire Burst", 5, null, 7D, false),
            MobCategory.MAGES,
            MobTier.ELITE),
        mob("Hex Scholar", 26, 8, 3, 18, MobCategory.MAGES, MobTier.ELITE),
        mob(
            "Stormcaller",
            40,
            14,
            4,
            32,
            new Explosion(TargetType.ENNEMY_TEAM, "Chain Storm", 5, null, 8D, false),
            MobCategory.MAGES,
            MobTier.LATE),
        mob(
            "Chrono Mage",
            44,
            15,
            5,
            40,
            new Explosion(TargetType.ENNEMY_MULTI_TARGET, "Time Rupture", 4, 4, 18D, false),
            MobCategory.MAGES,
            MobTier.LATE),
        mob(
            "Blood Mage",
            52,
            16,
            5,
            48,
            new Explosion(TargetType.ENNEMY_MULTI_TARGET, "Blood Burst", 4, 3, 10D, false),
            MobCategory.MAGES,
            MobTier.LATE),
        mob("Archon Invoker", 180, 30, 12, 130, MobCategory.MAGES, MobTier.APEX),
        mob(
            "Rift Seraph",
            360,
            44,
            20,
            180,
            new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Rift Renewal", 3, 12D, true),
            MobCategory.MAGES,
            MobTier.APEX),
        boss("Cataclysm Sage", 860, 84, 36, 590, MobCategory.MAGES, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Astral Tyrant", 1500, 110, 48, 1000, MobCategory.MAGES, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildEmpire() {
    return List.of(
        mob("Recruit", 5, 1, 1, 1, MobCategory.EMPIRE, MobTier.EARLY),
        mob("Legionnaire", 14, 4, 2, 4, MobCategory.EMPIRE, MobTier.MID),
        mob("Imperial Guard", 26, 8, 4, 12, MobCategory.EMPIRE, MobTier.ELITE),
        mob(
            "War Priest",
            30,
            6,
            4,
            15,
            new Blessing(TargetType.ALLY_TEAM, "Battle Hymn", 4, 4, 3),
            MobCategory.EMPIRE,
            MobTier.ELITE),
        mob("Arc Rifleman", 24, 10, 2, 18, MobCategory.EMPIRE, MobTier.ELITE),
        mob("Shield Captain", 52, 14, 8, 32, MobCategory.EMPIRE, MobTier.LATE),
        mob(
            "Siege Engineer",
            48,
            14,
            5,
            40,
            new Explosion(TargetType.ENNEMY_TEAM, "Bombardment", 5, null, 8D, false),
            MobCategory.EMPIRE,
            MobTier.LATE),
        mob(
            "Phoenix Knight",
            72,
            18,
            6,
            48,
            new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Ember Mend", 3, 15D, false),
            MobCategory.EMPIRE,
            MobTier.LATE),
        mob(
            "Dreadnought",
            220,
            28,
            15,
            130,
            new Blessing(TargetType.ALLY_TEAM, "Iron Bastion", 4, 8, 3),
            MobCategory.EMPIRE,
            MobTier.APEX),
        mob("Titan Guard", 260, 32, 18, 175, MobCategory.EMPIRE, MobTier.APEX),
        boss("Emperor's Wrath", 900, 86, 38, 610, MobCategory.EMPIRE, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Eternal Caesar", 1550, 116, 52, 1050, MobCategory.EMPIRE, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildGhosts() {
    return List.of(
        mob("Wisp", 4, 1, 0, 1, MobCategory.GHOSTS, MobTier.EARLY),
        mob("Haunter", 12, 4, 1, 4, MobCategory.GHOSTS, MobTier.MID),
        mob("Banshee", 24, 8, 2, 12, MobCategory.GHOSTS, MobTier.ELITE),
        mob("Grave Whisper", 22, 8, 2, 15, MobCategory.GHOSTS, MobTier.ELITE),
        mob("Soul Drainer", 28, 8, 3, 18, MobCategory.GHOSTS, MobTier.ELITE),
        mob("Phantom Knight", 50, 15, 6, 32, MobCategory.GHOSTS, MobTier.LATE),
        mob(
            "Crypt Lord",
            95,
            19,
            7,
            40,
            new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Necrotic Mend", 3, 18D, false),
            MobCategory.GHOSTS,
            MobTier.LATE),
        mob(
            "Soul Reaper",
            125,
            28,
            7,
            48,
            new Cut(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Soul Rend", 3, 8, 6),
            MobCategory.GHOSTS,
            MobTier.LATE),
        mob(
            "Nightmare Sovereign",
            320,
            46,
            16,
            135,
            new PowerStrike(TargetType.ENNEMY_SINGLE, "Nightfall", 3, 3.5),
            MobCategory.GHOSTS,
            MobTier.APEX),
        mob("Death Choir", 280, 40, 15, 180, MobCategory.GHOSTS, MobTier.APEX),
        boss("Lich King", 960, 88, 40, 620, MobCategory.GHOSTS, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Dreambreaker", 1500, 112, 48, 1000, MobCategory.GHOSTS, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildAncientMech() {
    return List.of(
        mob("Scrapper Drone", 5, 1, 1, 1, MobCategory.ANCIENT_MECH, MobTier.EARLY),
        mob("Bolt Sentry", 14, 4, 2, 4, MobCategory.ANCIENT_MECH, MobTier.MID),
        mob("Gear Knight", 28, 8, 4, 12, MobCategory.ANCIENT_MECH, MobTier.ELITE),
        mob("Shock Drone", 24, 9, 2, 15, MobCategory.ANCIENT_MECH, MobTier.ELITE),
        mob("Rust Golem", 34, 8, 6, 18, MobCategory.ANCIENT_MECH, MobTier.ELITE),
        mob("Iron Colossus", 90, 14, 10, 32, MobCategory.ANCIENT_MECH, MobTier.LATE),
        mob(
            "Cataclysm Engine",
            340,
            42,
            18,
            40,
            new Explosion(TargetType.ENNEMY_TEAM, "Cataclysm Pulse", 5, null, 24D, false),
            MobCategory.ANCIENT_MECH,
            MobTier.LATE),
        mob("War Automaton", 110, 18, 10, 48, MobCategory.ANCIENT_MECH, MobTier.LATE),
        mob(
            "Eternal Warden",
            380,
            34,
            24,
            150,
            new Blessing(TargetType.ALLY_TEAM, "Eternal Bulwark", 4, 12, 4),
            MobCategory.ANCIENT_MECH,
            MobTier.APEX),
        mob("Eclipse Colossus", 650, 66, 30, 200, MobCategory.ANCIENT_MECH, MobTier.APEX),
        boss("Chronos Devourer", 1100, 96, 44, 700, MobCategory.ANCIENT_MECH, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Omega Titan", 2000, 130, 55, 1400, MobCategory.ANCIENT_MECH, MobTier.EVENT_BOSS));
  }

  private static List<Mob> buildGiants() {
    return List.of(
        mob("Pebbleling", 5, 1, 1, 1, MobCategory.GIANTS, MobTier.EARLY),
        mob("Young Giant", 16, 4, 2, 4, MobCategory.GIANTS, MobTier.MID),
        boss("Troll Chieftain", 22, 6, 3, 10, MobCategory.GIANTS, MobTier.ELITE),
        mob("Ogre Bruiser", 28, 9, 4, 15, MobCategory.GIANTS, MobTier.ELITE),
        mob("Stone Giant", 38, 10, 6, 18, MobCategory.GIANTS, MobTier.ELITE),
        mob("Siege Giant", 110, 20, 8, 32, MobCategory.GIANTS, MobTier.LATE),
        mob("Behemoth", 140, 22, 9, 40, MobCategory.GIANTS, MobTier.LATE),
        mob("Storm Giant", 150, 24, 10, 48, MobCategory.GIANTS, MobTier.LATE),
        mob("Colossus Jarl", 320, 40, 18, 140, MobCategory.GIANTS, MobTier.APEX),
        mob("Mountain Breaker", 400, 44, 22, 190, MobCategory.GIANTS, MobTier.APEX),
        boss("Ancient Titan", 1200, 100, 46, 760, MobCategory.GIANTS, MobTier.CATASTROPHE_BOSS),
        boss("Event Boss: Skybreaker Colossus", 1800, 122, 54, 1200, MobCategory.GIANTS, MobTier.EVENT_BOSS));
  }

  private static Mob mob(
      String name, int hp, int attack, int defence, int value, MobCategory category, MobTier tier) {
    return new Mob(name, hp, attack, defence, value, category, tier);
  }

  private static Mob mob(
      String name,
      int hp,
      int attack,
      int defence,
      int value,
      Skill skill,
      MobCategory category,
      MobTier tier) {
    return new Mob(name, hp, attack, defence, value, skill, category, tier);
  }

  private static Mob boss(
      String name, int hp, int attack, int defence, int value, MobCategory category, MobTier tier) {
    return new Mob(name, hp, attack, defence, value, true, category, tier);
  }
}
