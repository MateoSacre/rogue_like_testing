package RogueLite.characters.hero;

import RogueLite.characters.Character;
import RogueLite.characters.mobs.Mob;
import RogueLite.characters.skills.Skill;

public class Hero extends Character {

  static final double XP_SLOPE_MODIFIER = .00001;

  int level = 0;
  long xp = 0;

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
    return super.getAttackPower() + getLevel();
  }

  private int getLevel() {
    return level;
  }

  @Override
  public double getDefence() {
    return super.getDefence() + getLevel() / 4;
  }

  @Override
  public double getMaxHp() {
    return super.getMaxHp() + getLevel() * 2;
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
}
