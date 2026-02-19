package RogueLite.characters.mobs;

import RogueLite.characters.skills.offensive.Splash;
import java.util.List;

public class MobsDictionary {
  public static List<Mob> mobs =
      List.of(
          // --- petits mobs (value 1-3) ---
          new Mob("Slime", 3, 1, 0, 1, new Splash()),
          new Mob("Goblin", 5, 1, 1, 1,null),
          new Mob("Rat", 4, 1, 0, 1),
          new Mob("Bat", 4, 1, 0, 1),
          new Mob("Skeleton", 7, 2, 1, 2),
          new Mob("Wolf", 8, 2, 1, 2),
          new Mob("Bandit", 9, 3, 1, 3),
          new Mob("Cultist", 8, 3, 0, 3),

          // --- moyens (value 4-10) ---
          new Mob("Orc", 14, 4, 2, 5),
          new Mob("Ogre", 18, 5, 2, 8),

          // --- élites (value 12-25) ---
          new Mob("Witch", 18, 8, 1, 12),
          new Mob("Golem", 35, 7, 6, 15),
          new Mob("Warlock", 26, 10, 2, 18),
          new Mob("Minotaur", 40, 11, 4, 25),

          // --- mini-boss / boss (isBoss=true) ---
          new Mob("Troll", 22, 6, 3, 10, true),
          new Mob("Hydra", 60, 14, 6, 30, true),
          new Mob("Demon Lord", 85, 18, 7, 50, true),

          // --- boss “classique” (tu l'avais déjà) ---
          new Mob("Dragon", 100, 20, 10, 60, true),

          // --- boss final valeur 100 ---
          new Mob("Ancient Titan", 200, 30, 15, 100, true));
}
