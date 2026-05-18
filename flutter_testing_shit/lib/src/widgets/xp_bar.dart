part of 'fighter_card.dart';

class _XpBar extends StatelessWidget {
  const _XpBar({required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final xpCap = fighter.xpCap;
    final ratio = xpCap == 0 ? 1.0 : fighter.xp / xpCap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('LVL ${fighter.level}')),
            Text('XP ${fighter.xp}/$xpCap'),
          ],
        ),
        const SizedBox(height: AppLayout.tinyGap),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.progressRadius),
          child: LinearProgressIndicator(
            minHeight: AppLayout.progressBarHeight,
            value: ratio.clamp(0, 1).toDouble(),
            backgroundColor: AppColors.progressTrack(context),
            valueColor: const AlwaysStoppedAnimation(AppColors.xpProgress),
          ),
        ),
      ],
    );
  }
}
