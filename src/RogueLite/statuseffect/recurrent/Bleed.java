package RogueLite.statuseffect.recurrent;

import RogueLite.characters.Character;
import RogueLite.statuseffect.EffectActivation;
import RogueLite.statuseffect.EffectType;
import RogueLite.statuseffect.StatusEffect;

public class Bleed implements StatusEffect {

  EffectActivation activation = EffectActivation.EVERY_TURN;
  EffectType type = EffectType.RECURRENT;
  String name = "Bleed";
  int duration = 3;
  double damage = 5;

  public Bleed() {}

  public Bleed(String name, int duration, double damage) {
    this.name = name;
    this.duration = duration;
    this.damage = damage;
  }

  @Override
  public String getName() {
    return name;
  }

  public void setDuration(int duration) {
    this.duration = duration;
  }

  @Override
  public int getDuration() {
    return duration;
  }

  @Override
  public EffectActivation getActivation() {
    return activation;
  }

  @Override
  public EffectType getType() {
    return type;
  }

  @Override
  public int getRemainingTurn() {
    return duration;
  }

  @Override
  public boolean isStackable() {
    return true;
  }

  @Override
  public Object applyEffect(Character character) {
    double damageInflicted = character.takeDamage(damage);
    System.out.println("Applied " + getName() + " for " + damageInflicted + " to " + character);
    return null;
  }

  @Override
  public void removeEffect(Character character) {
    System.out.println("Removed " + getName() + " for " + character);
  }

  @Override
  public void tick() {
    duration--;
  }

  @Override
  public StatusEffect newInstance() {
    return new Bleed(name, duration, damage);
  }
}
