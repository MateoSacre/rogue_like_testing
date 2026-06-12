import '../../models/enums.dart';
import '../../models/fighter.dart';
import '../../models/skill.dart';
import '../../models/skill_preview.dart';
import '../targeting.dart';
import 'battle_state.dart';

/// Manages hero/target selection state and exposes the queries that the
/// battle UI needs (canAct, targetsForSelectedAction, previewForTarget).
mixin SelectionMixin on BattleControllerBase {
  // ── Hero & action selection ───────────────────────────────────────────────

  void selectHero(Fighter hero) {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return;
    selectedHero = hero;
    selectedTarget = null;
    actionMode = hero.skill?.isReady == true ? ActionMode.skill : ActionMode.attack;
  }

  void setAction(ActionMode action) {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return;
    actionMode = action;
  }

  // ── Target selection ──────────────────────────────────────────────────────

  bool canToggleEnemyTarget(Fighter target) {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return false;
    if (!target.isAlive || !mobs.members.contains(target)) return false;
    if (actionMode == ActionMode.skill &&
        selectedHero?.skill?.targetType != TargetType.enemySingle) {
      return false;
    }
    return targetsForSelectedAction().contains(target);
  }

  void toggleEnemyTarget(Fighter target) {
    if (!canToggleEnemyTarget(target)) return;
    selectedTarget = selectedTarget == target ? null : target;
  }

  // ── Computed target list ──────────────────────────────────────────────────

  List<Fighter> targetsForSelectedAction() {
    final hero = selectedHero;
    if (hero == null) return [];
    if (actionMode == ActionMode.attack) return mobs.alive;
    final skill = hero.skill;
    if (skill == null || !skill.isReady) return [];
    if (_targetTypeNeedsNoManualTarget()) return resolveManualTargets(hero, skill);
    return manualTargetsForSkill(hero, skill, heroes, mobs);
  }

  @override
  List<Fighter> resolveManualTargets(Fighter caster, Skill skill) {
    return switch (skill.targetType) {
      TargetType.self => [caster],
      TargetType.allySingle => [selectedTarget ?? heroes.alive.first],
      TargetType.allySingleLowestHp => [lowestHp(heroes.alive)],
      TargetType.allyTeam => heroes.alive,
      TargetType.enemySingle => [
        selectedTarget ?? autoTargetFor(caster) ?? mobs.alive.first,
      ],
      TargetType.enemySingleHighestHp => [highestHp(mobs.alive)],
      TargetType.enemyMultiTarget => mobs.alive.take(3).toList(),
      TargetType.enemyTeam => mobs.alive,
    };
  }

  // ── Can act ───────────────────────────────────────────────────────────────

  @override
  bool get canAct {
    if (isAnimating || autoAttackEnabled || merchantAvailable) return false;
    final hero = selectedHero;
    if (hero == null || !hero.isAlive || actedHeroes.contains(hero)) return false;
    if (actionMode == ActionMode.skill && hero.skill?.isReady != true) return false;
    final targets = targetsForSelectedAction();
    if (targets.isEmpty) return false;
    if (selectedTarget != null) return targets.contains(selectedTarget);
    if (_targetTypeNeedsNoManualTarget()) return true;
    return actionMode == ActionMode.attack ||
        hero.skill?.targetType == TargetType.enemySingle;
  }

  // ── Damage / heal preview ─────────────────────────────────────────────────

  SkillPreview previewForTarget(Fighter target) {
    final hero = selectedHero;
    if (hero == null) return const SkillPreview.none();
    if (actionMode == ActionMode.attack) {
      return SkillPreview.damage(computeDamagePreview(hero, target));
    }
    final skill = hero.skill;
    if (skill == null || !skill.isReady) return const SkillPreview.none();
    // Each skill describes its own expected effect; no name-based lookup.
    final builder = skill.preview;
    if (builder != null) return builder(this, hero, target);
    return skill.targetsEnemies
        ? SkillPreview.damage(computeDamagePreview(hero, target))
        : const SkillPreview.none();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  bool _targetTypeNeedsNoManualTarget() {
    final skill = selectedHero?.skill;
    if (actionMode == ActionMode.attack || skill == null) return false;
    return switch (skill.targetType) {
      TargetType.self ||
      TargetType.allySingleLowestHp ||
      TargetType.allyTeam ||
      TargetType.enemySingleHighestHp ||
      TargetType.enemyMultiTarget ||
      TargetType.enemyTeam => true,
      TargetType.allySingle || TargetType.enemySingle => false,
    };
  }
}
