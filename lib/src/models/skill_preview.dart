/// What a skill (or basic attack) is expected to do to a given target.
///
/// This is pure data — no strings — so the battle logic stays free of
/// presentation concerns and the UI can format and localize it. Each skill
/// carries its own preview builder; adding or renaming a skill can no longer
/// silently break the target previews.
enum SkillPreviewKind { none, damage, heal, defence }

/// Damage-over-time flavor attached to a damage preview.
enum SkillPreviewDot { bleed, poison }

class SkillPreview {
  const SkillPreview.none()
    : kind = SkillPreviewKind.none,
      amount = 0,
      dot = null,
      dotDamage = 0;

  const SkillPreview.damage(this.amount, {this.dot, this.dotDamage = 0})
    : kind = SkillPreviewKind.damage;

  const SkillPreview.heal(this.amount)
    : kind = SkillPreviewKind.heal,
      dot = null,
      dotDamage = 0;

  const SkillPreview.defence(this.amount)
    : kind = SkillPreviewKind.defence,
      dot = null,
      dotDamage = 0;

  final SkillPreviewKind kind;

  /// Damage dealt, HP restored, or defence granted — depending on [kind].
  final double amount;

  final SkillPreviewDot? dot;

  /// Damage per turn of [dot], when present.
  final double dotDamage;
}
