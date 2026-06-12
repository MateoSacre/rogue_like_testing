part of 'game_screen.dart';

/// Target chip content: the target's name plus a localized rendering of the
/// structured [SkillPreview] the controller computed for it.
class _TargetPreviewLabel extends StatelessWidget {
  const _TargetPreviewLabel({required this.name, required this.preview});

  final String name;
  final SkillPreview preview;

  @override
  Widget build(BuildContext context) {
    final text = _format(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name),
        if (text.isNotEmpty)
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
      ],
    );
  }

  String _format(BuildContext context) {
    return switch (preview.kind) {
      SkillPreviewKind.none => '',
      SkillPreviewKind.damage when preview.dot != null => context.tr(
        K.previewDamageDot,
        [
          fmt(preview.amount),
          context.tr(
            preview.dot == SkillPreviewDot.bleed ? K.dotBleed : K.dotPoison,
          ),
          fmt(preview.dotDamage),
        ],
      ),
      SkillPreviewKind.damage => context.tr(K.previewDamage, [
        fmt(preview.amount),
      ]),
      SkillPreviewKind.heal => context.tr(K.previewHeal, [
        fmt(preview.amount),
      ]),
      SkillPreviewKind.defence => context.tr(K.previewDefence, [
        fmt(preview.amount),
      ]),
    };
  }
}
