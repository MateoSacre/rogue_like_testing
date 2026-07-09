import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/creature_rarity.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';

/// Square, Brave-Frontier-style unit tile: a portrait fills the square (or an
/// initial-letter placeholder when no art is set) with the rarity shown as a
/// coloured strip along the bottom edge. Used for the hero inventory grid.
class CreatureTile extends StatelessWidget {
  const CreatureTile({
    required this.name,
    required this.rarity,
    this.level,
    this.imageAsset,
    this.size = AppLayout.creatureTileSize,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String name;
  final CreatureRarity rarity;
  final int? level;
  final String? imageAsset;
  final double size;

  /// Shows a highlighted border and a checkmark badge — used by the team
  /// editor to mark creatures already picked for the roster.
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.creatureRarity(rarity);
    final barHeight = (size * .24).clamp(14.0, 22.0);
    return InkWell(
      borderRadius: BorderRadius.circular(AppLayout.borderRadius),
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLayout.borderRadius),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : color,
            width: selected ? 3 : 2,
          ),
          color: color.withValues(alpha: selected ? .28 : .12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: barHeight),
              child: _portrait(color),
            ),
            if (level != null)
              Positioned(top: 2, left: 2, child: _levelBadge(context)),
            if (selected)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Icon(
                    Icons.check,
                    size: (size * .18).clamp(12.0, 16.0),
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: barHeight,
                color: color,
                alignment: Alignment.center,
                child: _rarityBadge(barHeight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _portrait(Color color) {
    final asset = imageAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(color),
      );
    }
    return _placeholder(color);
  }

  Widget _placeholder(Color color) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return ColoredBox(
      color: color.withValues(alpha: .08),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: size * .38,
          ),
        ),
      ),
    );
  }

  // A single star icon plus the rarity's star count (e.g. "★6")
  Widget _rarityBadge(double barHeight) {
    final iconSize = barHeight * .62;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for(int i = 0; i< rarity.stars; i++)
        Icon(Icons.star, size: iconSize, color: Colors.white),
      ],
    );
  }

  Widget _levelBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        context.tr(K.levelBadge, [level]),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
