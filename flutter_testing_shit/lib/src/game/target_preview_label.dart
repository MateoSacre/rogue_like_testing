part of 'game_screen.dart';

class _TargetPreviewLabel extends StatelessWidget {
  const _TargetPreviewLabel({required this.name, required this.preview});

  final String name;
  final String preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name),
        if (preview.isNotEmpty)
          Text(
            preview,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}
