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
    // Label above, bar below spanning the full card width — a Row would
    // otherwise split label/bar 50/50 regardless of how short the label is.
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppLayout.progressRadius),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: value.clamp(0, 1).toDouble(),
              backgroundColor: AppColors.progressTrack(context),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
