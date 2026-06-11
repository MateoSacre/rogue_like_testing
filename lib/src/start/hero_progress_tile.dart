part of 'start_screen.dart';

class _HeroProgressTile extends StatelessWidget {
  const _HeroProgressTile({
    required this.hero,
    required this.progress,
    required this.trailing,
  });

  final Fighter hero;
  final PlayerProgress progress;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final level = progress.levelFor(hero.name);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.cardPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hero.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppLayout.tinyGap),
                  Text(
                    context.tr(K.tileStatLine, [
                      level,
                      fmt(hero.maxHp),
                      fmt(hero.attackPower),
                      fmt(hero.baseDefence),
                    ]),
                  ),
                  if (progress.isUnlocked(hero.name))
                    Text(
                      context.tr(K.tilePermanentPoints, [
                        progress.statPointsFor(hero.name).maxHp,
                        progress.statPointsFor(hero.name).attack,
                        progress.statPointsFor(hero.name).defence,
                        progress.statPointsFor(hero.name).unassigned,
                      ]),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (hero.skill != null)
                    Text(
                      hero.skill!.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppLayout.controlGap),
            trailing,
          ],
        ),
      ),
    );
  }
}
