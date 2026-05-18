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
