part of 'game_screen.dart';

class _BossWarning extends StatelessWidget {
  const _BossWarning({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = AppColors.warningForeground(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.warningHorizontalPadding,
        vertical: AppLayout.warningVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBackground(context),
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
        border: Border.all(color: AppColors.warningBorder(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: AppLayout.iconMedium),
          const SizedBox(width: AppLayout.controlGap),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
