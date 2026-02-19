package RogueLite.statuseffect;

import RogueLite.characters.Character;

public interface StatusEffect {
  String getName();
  EffectActivation getActivation();
  EffectType getType();

  int getRemainingTurn();

  boolean isStackable();

  void setDuration(int duration);
  int getDuration();

  Object applyEffect(Character character);

  void removeEffect(Character character);

  void tick();

  StatusEffect newInstance();
}
