import 'battle_actions.dart';
import 'enums.dart';
import 'fighter.dart';
import 'skill_preview.dart';

typedef SkillPreviewBuilder =
    SkillPreview Function(BattleActions battle, Fighter caster, Fighter target);

class Skill {
  Skill({
    required this.name,
    required this.chargeMax,
    required this.targetType,
    required this.apply,
    int? charge,
    this.shouldUse,
    this.preview,
    this.appliesNegativeEffect = false,
    this.description = '',
    this.chargeBars = 1,
  }) : charge = charge ?? 0;

  final String name;
  final int chargeMax;
  int charge;
  int chargeBars;
  final TargetType targetType;
  final String description;
  final bool appliesNegativeEffect;
  final bool Function(Fighter caster, List<Fighter> targets)? shouldUse;

  /// Describes the expected effect on a target, for the targeting UI.
  /// When null, the UI falls back to a plain damage preview for enemy skills.
  final SkillPreviewBuilder? preview;

  final void Function(
    BattleActions battle,
    Fighter caster,
    List<Fighter> targets,
  )
  apply;

  int get maxCharge => chargeMax * chargeBars;

  bool get isReady => charge >= chargeMax;

  bool get targetsEnemies {
    return switch (targetType) {
      TargetType.enemySingle ||
      TargetType.enemySingleHighestHp ||
      TargetType.enemyMultiTarget ||
      TargetType.enemyTeam => true,
      _ => false,
    };
  }

  void startCooldown() {
    charge = (charge - chargeMax).clamp(0, maxCharge).toInt();
  }

  void tickCooldown() {
    if (charge < maxCharge) {
      charge++;
    }
  }

  void fullyRecharge() {
    charge = maxCharge;
  }
}
