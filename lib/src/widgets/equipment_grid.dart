import 'package:flutter/material.dart';

import '../data/items.dart';
import '../l10n/app_localizations.dart';
import '../models/fighter.dart';
import '../models/item.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';

/// Square-cell equipment view: the four gear slots (filled or empty) followed
/// by one cell per distinct relic (with an ×count badge). Tapping a filled cell
/// shows the item's name and description. Replaces the old line list.
class EquipmentGrid extends StatelessWidget {
  const EquipmentGrid({required this.fighter, this.cellSize = 52, super.key});

  final Fighter fighter;
  final double cellSize;

  static const _gearSlots = [
    ItemSlot.helmet,
    ItemSlot.gloves,
    ItemSlot.chest,
    ItemSlot.weapon,
  ];

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (final slot in _gearSlots) {
      final id = fighter.equipment[slot];
      cells.add(_cell(context, slot, id == null ? null : itemById(id), 1));
    }
    final relicCounts = <String, int>{};
    for (final id in fighter.relics) {
      relicCounts[id] = (relicCounts[id] ?? 0) + 1;
    }
    for (final entry in relicCounts.entries) {
      final def = itemById(entry.key);
      if (def == null) continue;
      cells.add(_cell(context, ItemSlot.relic, def, entry.value));
    }
    return Wrap(
      spacing: AppLayout.compactGap,
      runSpacing: AppLayout.compactGap,
      children: cells,
    );
  }

  Widget _cell(BuildContext context, ItemSlot slot, ItemDef? def, int count) {
    final empty = def == null;
    final color = empty
        ? Theme.of(context).colorScheme.outlineVariant
        : AppColors.itemRarity(def.rarity);
    final cell = Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
        border: Border.all(color: color, width: empty ? 1 : 2),
        color: empty ? null : color.withValues(alpha: .12),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(_slotIcon(slot), color: color, size: AppLayout.iconMedium),
          ),
          if (count > 1)
            Positioned(
              right: 3,
              bottom: 1,
              child: Text(
                '×$count',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
    if (empty) return Opacity(opacity: .5, child: cell);
    return Tooltip(
      message:
          '${context.l10n.localized(def.name)}\n${context.l10n.localized(def.description)}'
          '${count > 1 ? ' (×$count)' : ''}',
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      waitDuration: Duration.zero,
      preferBelow: false,
      child: cell,
    );
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
