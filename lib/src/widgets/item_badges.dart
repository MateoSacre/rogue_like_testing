part of 'fighter_card.dart';

/// Compact row of rarity-colored badges for a fighter's held items, with a
/// tap/hover tooltip listing slot and item names in the current language.
class _ItemBadges extends StatelessWidget {
  const _ItemBadges({required this.fighter, this.compact = false});

  final Fighter fighter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = fighter.heldItems.toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final badgeSize = compact ? 16.0 : 22.0;
    final iconSize = compact ? 11.0 : 15.0;
    final tooltip = items
        .map(
          (item) =>
              '${context.l10n.itemSlot(item.slot)} : '
              '${context.l10n.localized(item.name)}',
        )
        .join('\n');

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      waitDuration: Duration.zero,
      preferBelow: false,
      child: Wrap(
        spacing: compact ? 2 : AppLayout.tinyGap,
        runSpacing: compact ? 2 : AppLayout.tinyGap,
        children: [
          for (final item in items)
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: _rarityColor(item.rarity).withValues(alpha: .16),
                border: Border.all(color: _rarityColor(item.rarity)),
                borderRadius: BorderRadius.circular(AppLayout.progressRadius),
              ),
              alignment: Alignment.center,
              child: Icon(
                _slotIcon(item.slot),
                size: iconSize,
                color: _rarityColor(item.rarity),
              ),
            ),
        ],
      ),
    );
  }

  Color _rarityColor(ItemRarity rarity) {
    return switch (rarity) {
      ItemRarity.common => AppColors.itemCommon,
      ItemRarity.uncommon => AppColors.itemUncommon,
      ItemRarity.legendary => AppColors.itemLegendary,
      ItemRarity.boss => AppColors.itemBoss,
    };
  }

  IconData _slotIcon(ItemSlot slot) {
    return switch (slot) {
      ItemSlot.helmet => Icons.sports_motorsports,
      ItemSlot.gloves => Icons.back_hand,
      ItemSlot.chest => Icons.shield,
      ItemSlot.weapon => Icons.gavel,
      ItemSlot.relic => Icons.token,
    };
  }
}
