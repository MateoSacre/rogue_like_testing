package RogueLite.characters;

import RogueLite.characters.skills.Skill;
import RogueLite.characters.skills.offensive.PowerStrike;
import RogueLite.statuseffect.EffectActivation;
import RogueLite.statuseffect.EffectType;
import RogueLite.statuseffect.StatusEffect;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class Character {

  private static final int DEFAULT_MAX_HP = 20;
  private static final int DEFAULT_ATTACK_POWER = 3;
  private static final int DEFAULT_DEFENCE = 1;
  private static final Skill DEFAULT_SKILL = new PowerStrike();

  protected String name;
  protected double hp;
  protected final double maxHp;
  protected final double attackPower;
  protected final double defence;

  protected final Skill skill;
  protected final List<StatusEffect> statusEffects;

  public Character(String name) {
    this(name, DEFAULT_MAX_HP);
  }

  public Character(String name, Skill skill) {
    this(name, DEFAULT_MAX_HP, DEFAULT_ATTACK_POWER, DEFAULT_DEFENCE, skill);
  }

  public Character(String name, int maxHp) {
    this(name, maxHp, DEFAULT_ATTACK_POWER, DEFAULT_DEFENCE, DEFAULT_SKILL);
  }

  public Character(String name, int maxHp, int attackPower, int defence) {
    this(name, maxHp, attackPower, defence, DEFAULT_SKILL);
  }

  public Character(String name, int maxHp, int attackPower, int defence, Skill skill) {
    if (name == null || name.isBlank()) {
      throw new IllegalArgumentException("Name is null or blank");
    }
    if (maxHp <= 0) {
      throw new IllegalArgumentException("Max HP must be positive and non null");
    }
    if (attackPower < 0) {
      throw new IllegalArgumentException("Attack power must be positive");
    }
    if (defence < 0) {
      throw new IllegalArgumentException("Defence must be positive");
    }
    this.name = name;
    this.maxHp = maxHp;
    this.hp = maxHp;
    this.attackPower = attackPower;
    this.defence = defence;
    this.skill = (skill == null) ? null : skill.newInstance();
    this.statusEffects = new ArrayList<StatusEffect>();
  }

  public Character(Character character) {
    this.name = character.getName();
    this.maxHp = character.getMaxHp();
    this.hp = character.getMaxHp();
    this.attackPower = character.getAttackPower();
    this.defence = character.getDefence();
    this.skill = (character.getSkill() == null) ? null : character.getSkill().newInstance();
    this.statusEffects =
        character.statusEffects.stream()
            .map(StatusEffect::newInstance)
            .collect(Collectors.toList());
  }

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public double getHp() {
    return hp;
  }

  public double getMaxHp() {
    return maxHp;
  }

  public double getAttackPower() {
    return attackPower + getAttackBuff();
  }

  public double getDefence() {
    return defence + getDefenceBuff();
  }

  public boolean isAlive() {
    return hp > 0;
  }

  public Skill getSkill() {
    return skill;
  }

  public double takeDamage(double damage) {
    if (damage <= 0) {
      return 0;
    }
    if (damage > hp) {
      hp = 0;
    } else {
      hp -= damage;
    }
    return damage;
  }

  public double heal(double amount) {
    if (amount <= 0) {
      return 0;
    }
    if (hp + amount >= getMaxHp()) {
      hp = getMaxHp();
    } else {
      hp += amount;
    }
    return amount;
  }

  public double computeDamageAgainst(Character target, double modifier) {
    if (target == null) {
      throw new IllegalArgumentException("Target is null");
    }
    double damage = ((this.getAttackPower()) * modifier) - target.getDefence();
    if (damage <= 0) {
      return 1;
    }
    return damage;
  }

  private double getAttackBuff() {
    return statusEffects.stream()
        .filter(
            se ->
                se.getType().equals(EffectType.BUFF)
                    && se.getActivation().equals(EffectActivation.ATTACK))
        .mapToDouble(se -> (Double) se.applyEffect(this))
        .sum();
  }

  private double getDefenceBuff() {
    return statusEffects.stream()
        .filter(
            se ->
                se.getType().equals(EffectType.BUFF)
                    && se.getActivation().equals(EffectActivation.TAKING_DAMAGE))
        .mapToDouble(se -> (Double) se.applyEffect(this))
        .sum();
  }

  public double computeDamageAgainst(Character target) {
    return computeDamageAgainst(target, 1);
  }

  public double attack(Character target, double modifier) {
    if (target == null) {
      throw new IllegalArgumentException("Target is null");
    }
    if (!target.isAlive() || !this.isAlive()) {
      return 0;
    }
    return target.takeDamage(computeDamageAgainst(target, modifier));
  }

  public double attack(Character target) {
    return attack(target, 1);
  }

  public boolean canUseSkill() {
    return skill != null && skill.getCooldownRemaining() == 0;
  }

  public void initiateSkillCooldown() {
    skill.initiateCooldown();
  }

  public void applySkillCooldown() {
    if (skill != null) skill.applySkillCooldown();
  }

  public void useSkill(List<Character> targets) {
    skill.use(this, targets);
  }

  public List<StatusEffect> getStatusEffects() {
    return statusEffects;
  }

  public void addEffect(StatusEffect effect) {
    statusEffects.add(effect);
  }

  public void removeEffectsIfNeeded() {
    List<Integer> effectToRemove = new ArrayList<>();
    for (int i = 0; i < statusEffects.size(); i++) {
      StatusEffect effect = statusEffects.get(i);
      if (effect.getRemainingTurn() == 0) {
        effectToRemove.add(i);
      }
    }
    for (int i : effectToRemove) {
      StatusEffect effect = statusEffects.get(i);
      effect.removeEffect(this);
      statusEffects.remove(effect);
    }
  }

  @Override
  public String toString() {
    return "[Name="
        + name
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
