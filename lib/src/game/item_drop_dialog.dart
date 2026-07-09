part of 'game_screen.dart';

/// Result of the drop dialog: a hero to receive the item, or null to sell it.
class _ItemDropChoice {
  const _ItemDropChoice(this.hero);

  final Fighter? hero;
}

/// Manual-mode item attribution: shows the dropped item (name, rarity,
/// description) and lets the player give it to a living hero — with the
/// replacement consequence spelled out — or sell it.
class _ItemDropDialog extends StatelessWidget {
  const _ItemDropDialog({required this.def, required this.heroes});

  final ItemDef def;
  final List<Fighter> heroes;

  @override
  Widget build(BuildContext context) {
    final rarityColor = _itemRarityColor(def.rarity);
    return AlertDialog(
      title: Text(context.tr(K.itemFound)),
      content: SizedBox(
        width: AppLayout.dialogWidth(context, 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_itemSlotIcon(def.slot), color: rarityColor),
                const SizedBox(width: AppLayout.controlGap),
                Expanded(
                  child: Text(
                    context.l10n.localized(def.name),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: rarityColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.compactGap,
                    vertical: AppLayout.tinyGap,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: rarityColor),
                    borderRadius: BorderRadius.circular(
                      AppLayout.progressRadius,
                    ),
                  ),
                  child: Text(
                    '${context.l10n.itemRarity(def.rarity)} · '
                    '${context.l10n.itemSlot(def.slot)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: rarityColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.compactGap),
            Text(context.l10n.localized(def.description)),
            const SizedBox(height: AppLayout.sectionGap),
            Text(
              context.tr(K.itemGiveTo),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppLayout.controlGap),
            ...heroes.map((hero) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppLayout.compactGap),
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_ItemDropChoice(hero)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.creatureName(hero.name)),
                            Text(
                              _consequenceFor(context, hero),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(const _ItemDropChoice(null)),
          icon: const Icon(Icons.paid),
          label: Text(context.tr(K.itemSellFor, [itemSellValue(def.rarity)])),
        ),
      ],
    );
  }

  String _consequenceFor(BuildContext context, Fighter hero) {
    if (def.isRelic) {
      return context.tr(K.itemRelicCount, [hero.relics.length]);
    }
    final currentId = hero.equipment[def.slot];
    final current = currentId == null ? null : itemById(currentId);
    if (current == null) return context.tr(K.itemSlotEmpty);
    return context.tr(K.itemReplaces, [context.l10n.localized(current.name)]);
  }
}

Color _itemRarityColor(ItemRarity rarity) {
  return switch (rarity) {
    ItemRarity.common => AppColors.itemCommon,
    ItemRarity.uncommon => AppColors.itemUncommon,
    ItemRarity.legendary => AppColors.itemLegendary,
    ItemRarity.boss => AppColors.itemBoss,
  };
}

IconData _itemSlotIcon(ItemSlot slot) {
  return switch (slot) {
    ItemSlot.helmet => Icons.sports_motorsports,
    ItemSlot.gloves => Icons.back_hand,
    ItemSlot.chest => Icons.shield,
    ItemSlot.weapon => Icons.gavel,
    ItemSlot.relic => Icons.token,
  };
}
