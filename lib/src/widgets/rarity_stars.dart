import 'package:flutter/material.dart';

import '../models/creature_rarity.dart';
import '../theme/app_colors.dart';

/// A compact row of filled stars (one per rarity tier, 1★ … 6★) tinted with
/// the rarity colour. Used on fighter cards and the character sheet.
class RarityStars extends StatelessWidget {
  const RarityStars({required this.rarity, this.size = 12, super.key});

  final CreatureRarity rarity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.creatureRarity(rarity);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rarity.stars,
        (_) => Icon(Icons.star, size: size, color: color),
      ),
    );
  }
}
