enum TargetType {
  self,
  allySingle,
  allySingleLowestHp,
  allyTeam,
  enemySingle,
  enemySingleHighestHp,
  enemyMultiTarget,
  enemyTeam,
}

enum EffectKind { recurrent, buff }

/// Damage-over-time family, used to target resistance relics. [generic] covers
/// any DoT that has no specific family.
enum DotType { generic, poison, bleed, burn }

enum AiType { dumb, random, killer, damager, effectDealer, effectStacker }

enum MobCategory {
  monsters('Monsters'),
  bandits('Bandits'),
  cultists('Cultists'),
  mages('Mages'),
  empire('Empire'),
  ghosts('Ghosts'),
  giants('Giants');

  const MobCategory(this.label);

  final String label;
}

enum ActionMode { attack, skill }
