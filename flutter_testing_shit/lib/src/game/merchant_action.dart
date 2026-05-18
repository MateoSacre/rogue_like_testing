part of 'game_screen.dart';

class _MerchantAction extends StatelessWidget {
  const _MerchantAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int cost;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.compactGap),
        child: Row(
          children: [
            Icon(icon, size: AppLayout.iconMedium),
            const SizedBox(width: AppLayout.controlGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: AppLayout.controlGap),
            Text('${cost}g'),
          ],
        ),
      ),
    );
  }
}
