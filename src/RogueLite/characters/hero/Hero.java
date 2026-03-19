package RogueLite.characters.hero;

import RogueLite.characters.Character;
import RogueLite.characters.mobs.Mob;
import RogueLite.characters.skills.Skill;
import java.util.Scanner;

public class Hero extends Character {

  static final double XP_SLOPE_MODIFIER = .00001;
  private static final Scanner scanner = new Scanner(System.in);
  private static LevelUpStatChooser levelUpStatChooser = Hero::readLevelUpChoice;

  int level = 0;
  long xp = 0;
  private double bonusMaxHp = 0;
  private double bonusAttackPower = 0;
  private double bonusDefence = 0;

  public void addXp(long xp) {
    if (xp < 0) {
      System.out.println("Negative xp, not doing anything");
      return;
    }
    long nextLevelXpCap = getXpCap(level);
    long totalXp = this.xp + xp;
    if (totalXp >= nextLevelXpCap) {
      long xpToReport = totalXp - nextLevelXpCap;
      this.level++;
      System.out.println(this.name + " reached level " + (this.level + 1));
      applyLevelUpBonus();
      this.xp = 0;
      if (this.heal(getMaxHp()) > 0) {
        System.out.println(this.name + " fully healed");
      }
      addXp(xpToReport);
    } else {
      this.xp += xp;
    }
  }

  public long getXpCap(int level) {
    long xpCap = 100; // cap pour passer du niveau 0 au niveau 1

    for (int i = 0; i < level; i++) {
      double multiplier = 1.02 + 0.48 * Math.exp(-XP_SLOPE_MODIFIER * i);
      xpCap = Math.round(xpCap * multiplier);
    }

    return xpCap;
  }

  public long getXp() {
    return xp;
  }

  public Hero(String name) {
    super(name);
  }

  public Hero(String name, Skill skill) {
    super(name, skill);
  }

  public Hero(String name, int maxHp) {
    super(name, maxHp);
  }

  public Hero(String name, int maxHp, int attackPower, int defence) {
    super(name, maxHp, attackPower, defence);
  }

  public Hero(String name, int maxHp, int attackPower, int defence, Skill skill) {
    super(name, maxHp, attackPower, defence, skill);
  }

  public Hero(Character character) {
    super(character);
  }

  @Override
  public double getAttackPower() {
    return super.getAttackPower() + bonusAttackPower;
  }

  public int getLevel() {
    return level;
  }

  @Override
  public double getDefence() {
    return super.getDefence() + bonusDefence;
  }

  @Override
  public double getMaxHp() {
    return super.getMaxHp() + bonusMaxHp;
  }

  @Override
  public double attack(Character target, double modifier) {
    double damages = super.attack(target, modifier);
    if (!target.isAlive() && target instanceof Mob) {
      addXp(Math.ceilDiv(((Mob) target).getValue(), 3));
    }
    return damages;
  }

  @Override
  public String toString() {
    return "[Name="
        + name
        + ", LVL="
        + (getLevel() + 1)
        + ", XP="
        + getXp()
        + "/"
        + getXpCap(level)
        + ", DEF="
        + getDefence()
        + ", ATK"
        + getAttackPower()
        + ", HP="
        + hp
        + "/"
        + getMaxHp()
        + "]";
  }

  private void applyLevelUpBonus() {
    LevelUpStat chosenStat = levelUpStatChooser.choose(this);
    double currentValue = switch (chosenStat) {
      case MAX_HP -> getMaxHp();
      case ATTACK -> getAttackPower();
      case DEFENCE -> getDefence();
    };
    double increase = Math.max(1D, Math.ceil(currentValue * 0.05D));
    switch (chosenStat) {
      case MAX_HP -> bonusMaxHp += increase;
      case ATTACK -> bonusAttackPower += increase;
      case DEFENCE -> bonusDefence += increase;
    }
    System.out.println(
        name
            + " gains +"
            + formatStatValue(increase)
            + " "
            + chosenStat.getLabel()
            + " permanently");
  }

  private static String formatStatValue(double value) {
    if (Math.rint(value) == value) {
      return Integer.toString((int) value);
    }
    return Double.toString(value);
  }

  private static LevelUpStat readLevelUpChoice(Hero hero) {
    while (true) {
      System.out.println("Choose a stat to improve for " + hero.getName() + ":");
      LevelUpStat[] values = LevelUpStat.values();
      for (int i = 0; i < values.length; i++) {
        LevelUpStat stat = values[i];
        double currentValue = switch (stat) {
          case MAX_HP -> hero.getMaxHp();
          case ATTACK -> hero.getAttackPower();
          case DEFENCE -> hero.getDefence();
        };
        double increase = Math.max(1D, Math.ceil(currentValue * 0.05D));
        System.out.println(
            "  "
                + (i + 1)
                + ". "
                + stat.getLabel()
                + " (current="
                + formatStatValue(currentValue)
                + ", +"
                + formatStatValue(increase)
                + ")");
      }
      System.out.print("Choose a stat [1-" + values.length + "]: ");
      String rawValue = scanner.nextLine();
      try {
        int choice = Integer.parseInt(rawValue.trim());
        if (choice >= 1 && choice <= values.length) {
          return values[choice - 1];
        }
      } catch (NumberFormatException ignored) {
        // Retry below.
      }
      System.out.println("Invalid choice. Try again.");
    }
  }

  public static void setLevelUpStatChooser(LevelUpStatChooser chooser) {
    levelUpStatChooser = chooser == null ? Hero::readLevelUpChoice : chooser;
  }

  public static void resetLevelUpStatChooser() {
    levelUpStatChooser = Hero::readLevelUpChoice;
  }

  public enum LevelUpStat {
    MAX_HP("Max HP"),
    ATTACK("Attack"),
    DEFENCE("Defence");

    private final String label;

    LevelUpStat(String label) {
      this.label = label;
    }

    public String getLabel() {
      return label;
    }
  }

  @FunctionalInterface
  public interface LevelUpStatChooser {
    LevelUpStat choose(Hero hero);
  }
}
