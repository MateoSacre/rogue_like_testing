part of 'fighter_card.dart';

class _CompactProgressLine extends StatelessWidget {
  const _CompactProgressLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppLayout.tinyGap),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppLayout.progressRadius),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: value.clamp(0, 1).toDouble(),
                backgroundColor: AppColors.progressTrack(context),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
