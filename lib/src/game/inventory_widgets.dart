part of 'game_screen.dart';

/// Drag-and-drop inventory dialog: drag a potion chip onto a hero to use it.
/// Mutation + persistence live in [_GameScreenState]; this only refreshes
/// itself after a successful use.
class _InventoryDialog extends StatefulWidget {
  const _InventoryDialog({required this.state});

  final _GameScreenState state;

  @override
  State<_InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends State<_InventoryDialog> {
  _GameScreenState get state => widget.state;
  BattleController get battle => state.battle;

  void _useItem(_InventoryItemKind kind, Fighter hero) {
    if (state._useInventoryItem(kind, hero)) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr(K.inventory)),
      content: SizedBox(
        width: AppLayout.dialogWidth(context, 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppLayout.controlGap,
              runSpacing: AppLayout.controlGap,
              children: state
                  ._inventoryItems()
                  .map(
                    (item) =>
                        _InventoryDraggable(item: item, enabled: item.count > 0),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            Text(
              context.tr(K.dropOnHero),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppLayout.controlGap),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppLayout.controlGap,
                  runSpacing: AppLayout.controlGap,
                  children: battle.heroes.members.map((hero) {
                    return _InventoryHeroTarget(
                      hero: hero,
                      canUse: state._canUseAnyInventoryItem(hero),
                      onAccept: _useItem,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr(K.close)),
        ),
      ],
    );
  }
}

enum _InventoryItemKind { healing, team, special }

class _InventoryItem {
  const _InventoryItem({
    required this.kind,
    required this.icon,
    required this.label,
    required this.count,
  });

  final _InventoryItemKind kind;
  final IconData icon;
  final String label;
  final int count;
}

class _InventoryDraggable extends StatelessWidget {
  const _InventoryDraggable({required this.item, required this.enabled});

  final _InventoryItem item;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chip = _InventoryChip(item: item, enabled: enabled);
    if (!enabled) return chip;
    return Draggable<_InventoryItemKind>(
      data: item.kind,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
        child: _InventoryChip(item: item, enabled: true),
      ),
      childWhenDragging: Opacity(opacity: .45, child: chip),
      child: chip,
    );
  }
}

class _InventoryChip extends StatelessWidget {
  const _InventoryChip({required this.item, required this.enabled});

  final _InventoryItem item;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.warningHorizontalPadding,
          vertical: AppLayout.warningVerticalPadding,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLayout.borderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: AppLayout.iconMedium),
            const SizedBox(width: AppLayout.controlGap),
            Text(context.tr(K.invItemCount, [item.label, item.count])),
          ],
        ),
      ),
    );
  }
}

class _InventoryHeroTarget extends StatelessWidget {
  const _InventoryHeroTarget({
    required this.hero,
    required this.canUse,
    required this.onAccept,
  });

  final Fighter hero;
  final bool canUse;
  final void Function(_InventoryItemKind kind, Fighter hero) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_InventoryItemKind>(
      onWillAcceptWithDetails: (_) => canUse,
      onAcceptWithDetails: (details) {
        onAccept(details.data, hero);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 180,
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.cardSelected(context) : null,
            borderRadius: BorderRadius.circular(AppLayout.borderRadius),
            border: Border.all(
              color: highlighted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Opacity(
            opacity: hero.isAlive ? 1 : .42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppLayout.tinyGap),
                Text(context.tr(K.hp, [fmt(hero.hp), fmt(hero.maxHp)])),
                if (hero.skill != null)
                  Text(
                    context.tr(K.specialCount, [
                      hero.skill!.charge,
                      hero.skill!.maxCharge,
                    ]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
