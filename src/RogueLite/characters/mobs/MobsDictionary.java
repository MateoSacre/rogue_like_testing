package RogueLite.characters.mobs;

import RogueLite.characters.skills.TargetType;
import RogueLite.characters.skills.defensive.Blessing;
import RogueLite.characters.skills.healing.SimpleHeal;
import RogueLite.characters.skills.offensive.Cut;
import RogueLite.characters.skills.offensive.Explosion;
import RogueLite.characters.skills.offensive.PoisonArrow;
import RogueLite.characters.skills.offensive.PowerStrike;
import RogueLite.characters.skills.offensive.Splash;
import java.util.List;

public class MobsDictionary {
  public static List<Mob> mobs =
      List.of(
          // --- early mobs (value 1-6) ---
          new Mob("Slime", 3, 1, 0, 1, new Splash()),
          new Mob("Goblin", 5, 1, 1, 1, null),
          new Mob("Rat", 4, 1, 0, 1),
          new Mob("Bat", 4, 1, 0, 1),
          new Mob("Skeleton", 7, 2, 1, 2),
          new Mob("Wolf", 8, 2, 1, 2),
          new Mob("Spider", 7, 2, 0, 2, new PoisonArrow(TargetType.ENNEMY_SINGLE, "Venom Bite", 3, 3, 1)),
          new Mob("Bandit", 9, 3, 1, 3),
          new Mob("Cultist", 8, 3, 0, 3),
          new Mob("Scout", 10, 3, 1, 4),
          new Mob("Ghoul", 12, 3, 1, 4),
          new Mob("Boar", 13, 4, 1, 5),
          new Mob("Acolyte", 12, 3, 2, 5, new Blessing(TargetType.ALLY_TEAM, "Dark Ward", 4, 2, 2)),
          new Mob("Brute", 16, 5, 1, 6),

          // --- mid mobs (value 7-20) ---
          new Mob("Orc", 14, 4, 2, 5),
          new Mob("Ogre", 18, 5, 2, 8),
          new Mob("Raider", 18, 5, 2, 7),
          new Mob("Shaman", 16, 4, 2, 8, new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Patch Up", 4, 8D, false)),
          new Mob("Stone Imp", 20, 5, 3, 9),
          new Mob("Assassin", 17, 7, 1, 10, new Cut(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Jagged Shiv", 4, 3, 2)),
          new Mob("Troll", 22, 6, 3, 10, true),
          new Mob("Berserker", 24, 8, 2, 12, new PowerStrike(TargetType.ENNEMY_SINGLE, "Crushing Blow", 3, 2.5)),
          new Mob("Witch", 18, 8, 1, 12),
          new Mob("Frost Adept", 22, 7, 2, 13, new Explosion(TargetType.ENNEMY_MULTI_TARGET, "Ice Shards", 4, 2, 6D, false)),
          new Mob("Golem", 35, 7, 6, 15),
          new Mob("Lizard Rider", 28, 8, 3, 15),
          new Mob("Bone Archer", 20, 7, 2, 16, new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Toxic Arrow", 3, 4, 2)),
          new Mob("Warlock", 26, 10, 2, 18),
          new Mob("Guardian", 35, 6, 6, 18),
          new Mob("War Priest", 30, 6, 4, 20, new Blessing(TargetType.ALLY_TEAM, "Battle Hymn", 4, 4, 3)),

          // --- elite mobs (value 22-60) ---
          new Mob("Executioner", 45, 13, 4, 22, new PowerStrike(TargetType.ENNEMY_SINGLE, "Headsman Strike", 3, 2.8)),
          new Mob("Plague Doctor", 38, 9, 4, 24, new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Virulent Dart", 2, 6, 3)),
          new Mob("Minotaur", 40, 11, 4, 25),
          new Mob("Stormcaller", 34, 12, 3, 28, new Explosion(TargetType.ENNEMY_TEAM, "Chain Storm", 5, null, 8D, false)),
          new Mob("Hydra", 60, 14, 6, 30, true),
          new Mob("Rune Knight", 52, 12, 7, 32, new Blessing(TargetType.ALLY_TEAM, "Runic Guard", 4, 5, 3)),
          new Mob("Behemoth", 70, 14, 5, 36),
          new Mob("Shadowblade", 48, 16, 4, 40, new Cut(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Shadow Cut", 3, 5, 4)),
          new Mob("Blood Mage", 55, 15, 4, 45, new Explosion(TargetType.ENNEMY_MULTI_TARGET, "Blood Burst", 4, 3, 10D, false)),
          new Mob("Demon Lord", 85, 18, 7, 50, true),
          new Mob("Iron Colossus", 90, 14, 10, 50),
          new Mob("Phoenix Knight", 72, 18, 6, 55, new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Ember Mend", 3, 15D, false)),
          new Mob("Dragon", 100, 20, 10, 60, true),
          new Mob("Void Hunter", 68, 20, 5, 60, new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Void Venom", 2, 6, 5)),

          // --- late mobs (value 70-180) ---
          new Mob("Siege Giant", 110, 20, 8, 70),
          new Mob("Crypt Lord", 95, 19, 7, 80, new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Necrotic Mend", 3, 18D, false)),
          new Mob("Thunder Roc", 88, 24, 6, 90, new Explosion(TargetType.ENNEMY_TEAM, "Thunder Crash", 4, null, 14D, false)),
          new Mob("Ancient Titan", 200, 30, 15, 100, true),
          new Mob("Abyss Walker", 120, 23, 8, 100, new PowerStrike(TargetType.ENNEMY_SINGLE, "Abyss Cleave", 3, 3.0)),
          new Mob("Titan Guard", 150, 24, 12, 115),
          new Mob("Lich King", 240, 34, 16, 120, true),
          new Mob("Soul Reaper", 125, 28, 7, 130, new Cut(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Soul Rend", 3, 8, 6)),
          new Mob("Chrono Mage", 110, 26, 8, 145, new Explosion(TargetType.ENNEMY_MULTI_TARGET, "Time Rupture", 4, 4, 18D, false)),
          new Mob("Kraken Monarch", 300, 38, 18, 150, true),
          new Mob("World Eater Spawn", 180, 30, 10, 160),
          new Mob("Celestial Wyrm", 360, 44, 20, 180, true),
          new Mob("Dreadnought", 220, 28, 15, 180, new Blessing(TargetType.ALLY_TEAM, "Iron Bastion", 4, 8, 3)),

          // --- apex mobs for very late waves (value 220-420) ---
          new Mob("Infernal Emperor", 420, 50, 22, 220, true),
          new Mob("Star Devourer", 280, 36, 14, 220, new PoisonArrow(TargetType.ENNEMY_SINGLE_HIGHEST_HP, "Star Rot", 2, 8, 8)),
          new Mob("Cataclysm Engine", 340, 42, 18, 260, new Explosion(TargetType.ENNEMY_TEAM, "Cataclysm Pulse", 5, null, 24D, false)),
          new Mob("Void Leviathan", 520, 58, 26, 280, true),
          new Mob("Eternal Warden", 380, 34, 24, 300, new Blessing(TargetType.ALLY_TEAM, "Eternal Bulwark", 4, 12, 4)),
          new Mob("Eclipse Colossus", 650, 66, 30, 360, true),
          new Mob("Nightmare Sovereign", 320, 46, 16, 360, new PowerStrike(TargetType.ENNEMY_SINGLE, "Nightfall", 3, 3.5)),
          new Mob("Rift Seraph", 360, 44, 20, 420, new SimpleHeal(TargetType.ALLY_SINGLE_LOWEST_HP, "Rift Renewal", 3, 12D, true)),

          // --- catastrophe bosses for waves 400+ ---
          new Mob("Chronos Devourer", 780, 74, 34, 450, true),
          new Mob("World Ender", 920, 84, 38, 600, true),

          // --- event bosses stronger than the current final boss ---
          new Mob("Event Boss: Dreambreaker", 1200, 96, 42, 800, true),
          new Mob("Event Boss: Astral Tyrant", 1500, 110, 48, 1000, true),
          new Mob("Event Boss: Omega Titan", 2000, 130, 55, 1400, true));
}
