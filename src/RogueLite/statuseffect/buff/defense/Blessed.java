package RogueLite.statuseffect.buff.defense;

import RogueLite.characters.Character;
import RogueLite.statuseffect.EffectActivation;
import RogueLite.statuseffect.EffectType;
import RogueLite.statuseffect.StatusEffect;

public class Blessed implements StatusEffect {

  EffectActivation activation = EffectActivation.TAKING_DAMAGE;
  EffectType type = EffectType.BUFF;
  String name = "Blessed";
  int duration = 2;
  double protection = 1;

  boolean isApplied = false;

  public Blessed() {}

  public Blessed(String name, int duration, double protection) {
    this.name = name;
    this.duration = duration;
    this.protection = protection;
  }

  @Override
  public String getName() {
    return name;
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
    return false;
  }

  @Override
  public void setDuration(int duration) {
    this.duration = duration;
  }

  @Override
  public int getDuration() {
    return duration;
  }

  @Override
  public Object applyEffect(Character character) {
    return protection;
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
    return new Blessed(name, duration, protection);
  }
}
