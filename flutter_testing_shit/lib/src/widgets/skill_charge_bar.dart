part of 'fighter_card.dart';

class _SkillChargeBar extends StatelessWidget {
  const _SkillChargeBar({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final barRows = <Widget>[];
    for (var start = 0; start < skill.chargeBars; start += 2) {
      final barsInRow = skill.chargeBars - start >= 2 ? 2 : 1;
      barRows.add(
        Row(
          children: List.generate(barsInRow, (index) {
            final barIndex = start + index;
            final filled = (skill.charge - barIndex * skill.chargeMax).clamp(
              0,
              skill.chargeMax,
            );
            final ratio = skill.chargeMax == 0 ? 1.0 : filled / skill.chargeMax;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : AppLayout.tinyGap,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppLayout.progressRadius),
                  child: LinearProgressIndicator(
                    minHeight: AppLayout.progressBarHeight,
                    value: ratio.toDouble(),
                    backgroundColor: AppColors.progressTrack(context),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.skillCharge,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                skill.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppLayout.controlGap),
            Text('${skill.charge}/${skill.maxCharge}'),
          ],
        ),
        const SizedBox(height: AppLayout.tinyGap),
        ...(barRows
            .expand((row) => [row, const SizedBox(height: AppLayout.tinyGap)])
            .toList()
          ..removeLast()),
      ],
    );
  }
}
