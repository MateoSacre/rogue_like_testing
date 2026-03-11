package RogueLite.characters.hero;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;

public class Hero extends Character {

  int level = 0;
  int xp = 0;

  public void addXp(int xp) {
    if (xp < 0) {
      System.out.println("Negative xp, not doing anything");
      return;
    }
    int nextLevelXpCap = getXpCap();
    int totalXp = this.xp + xp;
    if (totalXp >= nextLevelXpCap) {
      int xpToReport = totalXp - nextLevelXpCap;
      this.level++;
      this.xp = 0;
      addXp(xpToReport);
    } else {
      this.xp += xp;
    }
  }

  public int getXp() {
    return xp;
  }

  public int getXpCap() {
    return Math.toIntExact(Math.round(Math.pow(100, 1 + ((double) (level) / 10))));
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
    if (!target.isAlive()) {
      addXp((int) Math.round(target.getMaxHp() / 4));
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
        + getXpCap()
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
