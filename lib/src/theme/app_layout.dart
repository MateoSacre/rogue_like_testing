import 'package:flutter/widgets.dart';

class AppLayout {
  const AppLayout._();

  static const wideBreakpoint = 900.0;

  static const pagePadding = 16.0;
  static const panelGap = 16.0;
  static const sectionGap = 12.0;
  static const controlGap = 8.0;
  static const compactGap = 6.0;
  static const tinyGap = 4.0;

  static const cardPadding = 12.0;
  static const summaryPadding = 14.0;
  static const warningHorizontalPadding = 10.0;
  static const warningVerticalPadding = 8.0;

  static const hpBarHeight = 10.0;
  static const progressBarHeight = 8.0;
  static const logHeight = 220.0;
  static const fighterCardMaxWidth = 320.0;
  static const heroCardHeight = 196.0;
  static const enemyCardHeight = 158.0;
  static const compactHeroCardHeight = 92.0;
  static const compactEnemyCardHeight = 62.0;
  static const iconSmall = 18.0;
  static const iconMedium = 20.0;

  static const borderRadius = 8.0;
  static const progressRadius = 4.0;

  /// A dialog content width that never exceeds the screen (avoids overflow on
  /// narrow devices). Returns [preferred] when it fits, otherwise the
  /// available width minus page padding on both sides.
  static double dialogWidth(BuildContext context, double preferred) {
    final available = MediaQuery.sizeOf(context).width - pagePadding * 2;
    return preferred < available ? preferred : available;
  }
}
