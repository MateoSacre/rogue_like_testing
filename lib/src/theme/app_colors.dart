import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const seed = Color(0xff4f6f52);
  static const scaffoldBackground = Color(0xfff5f0e8);
  static const darkScaffoldBackground = Color(0xff171915);

  static Color cardSelected(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff4b4530)
        : const Color(0xffc3b892);
  }

  static Color cardActed(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff2e332d)
        : const Color(0xffe4e4e4);
  }

  static Color cardDefeated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff4b2b2b)
        : const Color(0xff8d5c5a);
  }

  static Color progressTrack(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;
  }

  static const hpHigh = Colors.green;
  static const hpMedium = Colors.orange;
  static const hpLow = Colors.red;
  static const skillCharge = Color(0xffc73d3d);
  static const xpProgress = Color(0xff2375d1);

  static Color warningBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff4a321c)
        : const Color(0xffffe1c4);
  }

  static Color warningBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xffb9843f)
        : const Color(0xffc6682f);
  }

  static Color warningForeground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xffffcf8a)
        : const Color(0xff9d3f12);
  }
}
