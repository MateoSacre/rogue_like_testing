package RogueLite.characters.mobs;

import RogueLite.characters.Character;
import RogueLite.characters.skills.Skill;

public class Mob extends Character {
  private static final int BASE_VALUE = 1;
  private static final boolean IS_NOT_BOSS = false;
  private static final MobCategory DEFAULT_CATEGORY = MobCategory.MONSTERS;
  private static final MobTier DEFAULT_TIER = MobTier.EARLY;

  private int value;
  private boolean isBoss;
  private MobCategory category;
  private MobTier tier;

  public Mob(String name) {
    super(name);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(String name, int maxHp) {
    super(name, maxHp);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(String name, int maxHp, int attackPower, int defence) {
    super(name, maxHp, attackPower, defence);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,int value) {
    super(name, maxHp, attackPower, defence);
    this.value = value;
    this.isBoss = IS_NOT_BOSS;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,int value, Skill skill) {
    super(name, maxHp, attackPower, defence, skill);
    this.value = value;
    this.isBoss = IS_NOT_BOSS;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,boolean isBoss) {
    super(name, maxHp, attackPower, defence);
    this.value = BASE_VALUE;
    this.isBoss = isBoss;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(String name, int maxHp, int attackPower, int defence,int value,boolean isBoss) {
    super(name, maxHp, attackPower, defence);
    this.value = value;
    this.isBoss = isBoss;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(
      String name,
      int maxHp,
      int attackPower,
      int defence,
      int value,
      MobCategory category,
      MobTier tier) {
    super(name, maxHp, attackPower, defence);
    this.value = value;
    this.isBoss = IS_NOT_BOSS;
    this.category = category;
    this.tier = tier;
  }

  public Mob(
      String name,
      int maxHp,
      int attackPower,
      int defence,
      int value,
      Skill skill,
      MobCategory category,
      MobTier tier) {
    super(name, maxHp, attackPower, defence, skill);
    this.value = value;
    this.isBoss = IS_NOT_BOSS;
    this.category = category;
    this.tier = tier;
  }

  public Mob(
      String name,
      int maxHp,
      int attackPower,
      int defence,
      int value,
      boolean isBoss,
      MobCategory category,
      MobTier tier) {
    super(name, maxHp, attackPower, defence);
    this.value = value;
    this.isBoss = isBoss;
    this.category = category;
    this.tier = tier;
  }

  public Mob(Character character) {
    super(character);
    this.value = BASE_VALUE;
    this.isBoss = IS_NOT_BOSS;
    this.category = DEFAULT_CATEGORY;
    this.tier = DEFAULT_TIER;
  }

  public Mob(Mob mob) {
    super(mob);
    this.value = mob.getValue();
    this.isBoss = mob.isBoss();
    this.category = mob.getCategory();
    this.tier = mob.getTier();
  }

  public int getValue() {
    return value;
  }

  public boolean isBoss() {
    return isBoss;
  }

  public MobCategory getCategory() {
    return category;
  }

  public MobTier getTier() {
    return tier;
  }
}
