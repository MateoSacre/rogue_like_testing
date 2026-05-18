part of 'start_screen.dart';

class _StatAllocationDialog extends StatefulWidget {
  const _StatAllocationDialog({required this.hero, required this.initialStats});

  final Fighter hero;
  final HeroStatPoints initialStats;

  @override
  State<_StatAllocationDialog> createState() => _StatAllocationDialogState();
}

class _StatAllocationDialogState extends State<_StatAllocationDialog> {
  late HeroStatPoints stats;

  int get total => widget.initialStats.total;
  int get remaining => stats.unassigned;

  @override
  void initState() {
    super.initState();
    stats = widget.initialStats;
  }

  @override
  Widget build(BuildContext context) {
    final preview = heroWithPermanentStats(
      widget.hero,
      total + 1,
      (stat) => stats.valueFor(stat),
    );
    return AlertDialog(
      title: Text('Stats de ${widget.hero.name}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Niveau ${total + 1} - Points non attribues: $remaining'),
            const SizedBox(height: AppLayout.sectionGap),
            _StatAllocationRow(
              stat: LevelUpStat.maxHp,
              value: stats.maxHp,
              preview: fmt(preview.maxHp),
              canRemove: stats.maxHp > 0,
              canAdd: remaining > 0,
              onRemove: () => setState(() {
                stats = stats.unassign(LevelUpStat.maxHp);
              }),
              onAdd: () => setState(() {
                stats = stats.assign(LevelUpStat.maxHp);
              }),
            ),
            _StatAllocationRow(
              stat: LevelUpStat.attack,
              value: stats.attack,
              preview: fmt(preview.attackPower),
              canRemove: stats.attack > 0,
              canAdd: remaining > 0,
              onRemove: () => setState(() {
                stats = stats.unassign(LevelUpStat.attack);
              }),
              onAdd: () => setState(() {
                stats = stats.assign(LevelUpStat.attack);
              }),
            ),
            _StatAllocationRow(
              stat: LevelUpStat.defence,
              value: stats.defence,
              preview: fmt(preview.baseDefence),
              canRemove: stats.defence > 0,
              canAdd: remaining > 0,
              onRemove: () => setState(() {
                stats = stats.unassign(LevelUpStat.defence);
              }),
              onAdd: () => setState(() {
                stats = stats.assign(LevelUpStat.defence);
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(stats),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

class _StatAllocationRow extends StatelessWidget {
  const _StatAllocationRow({
    required this.stat,
    required this.value,
    required this.preview,
    required this.canRemove,
    required this.canAdd,
    required this.onRemove,
    required this.onAdd,
  });

  final LevelUpStat stat;
  final int value;
  final String preview;
  final bool canRemove;
  final bool canAdd;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.controlGap),
      child: Row(
        children: [
          Expanded(child: Text('${_shortStat(stat)}: $preview')),
          Text(value.toString()),
          const SizedBox(width: AppLayout.controlGap),
          IconButton(
            tooltip: 'Retirer',
            onPressed: canRemove ? onRemove : null,
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Ajouter',
            onPressed: canAdd ? onAdd : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
