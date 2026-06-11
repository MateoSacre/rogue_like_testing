part of 'fighter_card.dart';

class _StatusEffectBadges extends StatelessWidget {
  const _StatusEffectBadges({required this.effects, this.compact = false});

  final List<StatusEffect> effects;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    final visuals = effects.map(_StatusEffectVisual.fromEffect).toList();
    final iconSize = compact ? 14.0 : AppLayout.iconMedium;
    final badgeSize = compact ? 20.0 : 28.0;
    final tooltip = _tooltipMessage(context, effects);

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      waitDuration: Duration.zero,
      preferBelow: false,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Wrap(
          spacing: compact ? 3 : AppLayout.tinyGap,
          runSpacing: compact ? 3 : AppLayout.tinyGap,
          children: [
            for (final visual in visuals)
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: .16),
                  border: Border.all(
                    color: visual.color.withValues(alpha: .74),
                  ),
                  borderRadius: BorderRadius.circular(AppLayout.progressRadius),
                ),
                alignment: Alignment.center,
                child: Icon(visual.icon, size: iconSize, color: visual.color),
              ),
          ],
        ),
      ),
    );
  }

  String _tooltipMessage(BuildContext context, List<StatusEffect> effects) {
    return effects.map((effect) => _effectLine(context, effect)).join('\n');
  }

  String _effectLine(BuildContext context, StatusEffect effect) {
    final parts = <String>[];
    if (effect.kind == EffectKind.recurrent && effect.damage > 0) {
      parts.add(context.tr(K.fxDamagePerTurn, [fmt(effect.damage)]));
      parts.add(context.tr(K.fxIgnoresArmor));
    }
    if (effect.kind == EffectKind.buff && effect.defenceBonus != 0) {
      final signed =
          '${effect.defenceBonus > 0 ? '+' : ''}${fmt(effect.defenceBonus)}';
      parts.add(context.tr(K.fxDefence, [signed]));
    }
    if (parts.isEmpty) parts.add(effect.kind.name);

    final remaining = effect.duration == 1
        ? context.tr(K.fxTurnRemaining)
        : context.tr(K.fxTurnsRemaining, [effect.duration]);
    return context.tr(K.fxLine, [effect.name, parts.join(', '), remaining]);
  }
}

class _StatusEffectVisual {
  const _StatusEffectVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  factory _StatusEffectVisual.fromEffect(StatusEffect effect) {
    final lowerName = effect.name.toLowerCase();
    if (lowerName.contains('poison')) {
      return const _StatusEffectVisual(
        icon: Icons.science,
        color: Color(0xff2e7d32),
      );
    }
    if (lowerName.contains('cut') || lowerName.contains('bleed')) {
      return const _StatusEffectVisual(
        icon: Icons.bloodtype,
        color: Color(0xffb3261e),
      );
    }
    if (effect.kind == EffectKind.buff) {
      return const _StatusEffectVisual(
        icon: Icons.shield,
        color: Color(0xff1976d2),
      );
    }
    return const _StatusEffectVisual(
      icon: Icons.local_fire_department,
      color: Color(0xffef6c00),
    );
  }
}
