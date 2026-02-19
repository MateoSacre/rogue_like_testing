package RogueLite.characters.mobs;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;

public class Mob extends Character {
  private static final int BASE_VALUE = 1;
  private static final boolean IS_NOT_BOSS = false;

  private int value;
  private boolean isBoss;

  public Mob(String name) {
    super(name);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
  }

  public Mob(String name, int maxHp) {
    super(name, maxHp);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
  }

  public Mob(String name, int maxHp, int attackPower, int defence) {
    super(name, maxHp, attackPower, defence);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,int value) {
    super(name, maxHp, attackPower, defence);
    this.value = value;
    this.isBoss = IS_NOT_BOSS;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,int value, Skill skill) {
    super(name, maxHp, attackPower, defence, skill);
    this.value = value;
    this.isBoss = IS_NOT_BOSS;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,boolean isBoss) {
    super(name, maxHp, attackPower, defence);
    this.value = BASE_VALUE;
    this.isBoss = isBoss;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,int value,boolean isBoss) {
    super(name, maxHp, attackPower, defence);
    this.value = value;
    this.isBoss = isBoss;
  }

  public Mob(Character character) {
    super(character);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
  }

  public Mob(Mob mob) {
    super(mob);
    this.value = mob.getValue();
    this.isBoss = mob.isBoss();
  }

  public int getValue() {
    return value;
  }

  public boolean isBoss() {
    return isBoss;
  }
}
