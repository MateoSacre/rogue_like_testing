part of 'game_screen.dart';

class _LevelUpDialog extends StatelessWidget {
  const _LevelUpDialog({required this.pending, required this.battle});

  final PendingLevelUp pending;
  final BattleController battle;

  @override
  Widget build(BuildContext context) {
    final hero = pending.hero;
    return AlertDialog(
      title: Text('${hero.name} gagne un niveau'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: LevelUpStat.values.map((stat) {
          final increase = battle.levelUpIncreaseFor(hero, stat);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.controlGap),
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(stat),
              child: Text(stat.describe(hero, increase)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
