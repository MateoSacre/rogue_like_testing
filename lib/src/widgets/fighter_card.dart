import 'package:flutter/material.dart';

import '../models/fighter.dart';
import '../models/skill.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../utils/format.dart';

class FighterCard extends StatelessWidget {
  const FighterCard({
    required this.fighter,
    required this.selected,
    required this.pickable,
    this.acted = false,
    this.compact = false,
    this.onTap,
    super.key,
  });

  final Fighter fighter;
  final bool selected;
  final bool pickable;
  final bool acted;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hpRatio = fighter.maxHp == 0 ? 0.0 : fighter.hp / fighter.maxHp;
    final skill = fighter.skill;
    if (compact) {
      return Card(
        margin: EdgeInsets.zero,
        color: _backgroundColor(context),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppLayout.borderRadius),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(AppLayout.compactGap),
                child: Opacity(
                  opacity: fighter.isAlive ? 1 : .42,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: constraints.maxWidth - AppLayout.compactGap * 2,
                      child: DefaultTextStyle.merge(
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fighter.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                                if (pickable)
                                  const Icon(
                                    Icons.touch_app,
                                    size: AppLayout.iconSmall,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppLayout.tinyGap),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppLayout.progressRadius,
                              ),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: hpRatio.clamp(0, 1).toDouble(),
                                backgroundColor: AppColors.progressTrack(
                                  context,
                                ),
                                valueColor: AlwaysStoppedAnimation(
                                  hpRatio > .5
                                      ? AppColors.hpHigh
                                      : (hpRatio > .25
                                            ? AppColors.hpMedium
                                            : AppColors.hpLow),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HP ${fmt(fighter.hp)}/${fmt(fighter.maxHp)}  ATK ${fmt(fighter.attackPower)}  DEF ${fmt(fighter.defence)}',
                            ),
                            if (fighter.isHero)
                              _CompactProgressLine(
                                label:
                                    'LVL ${fighter.level}',
                                value: fighter.xpCap == 0
                                    ? 1
                                    : fighter.xp / fighter.xpCap,
                                color: AppColors.xpProgress,
                              ),
                            if (skill != null)
                              _CompactProgressLine(
                                label:
                                    '${skill.name} ${skill.charge}/${skill.maxCharge}',
                                value: skill.maxCharge == 0
                                    ? 1
                                    : skill.charge / skill.maxCharge,
                                color: AppColors.skillCharge,
                              ),
                            if (fighter.statusLabel.isNotEmpty)
                              Text(
                                fighter.statusLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Card(
      color: _backgroundColor(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          child: Opacity(
            opacity: fighter.isAlive ? 1 : .42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fighter.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (pickable)
                      const Icon(Icons.touch_app, size: AppLayout.iconSmall),
                  ],
                ),
                const SizedBox(height: AppLayout.controlGap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppLayout.progressRadius),
                  child: LinearProgressIndicator(
                    minHeight: AppLayout.hpBarHeight,
                    value: hpRatio.clamp(0, 1).toDouble(),
                    backgroundColor: AppColors.progressTrack(context),
                    valueColor: AlwaysStoppedAnimation(
                      hpRatio > .5
                          ? AppColors.hpHigh
                          : (hpRatio > .25
                                ? AppColors.hpMedium
                                : AppColors.hpLow),
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.compactGap),
                Text('HP ${fmt(fighter.hp)}/${fmt(fighter.maxHp)}'),
                Text(
                  'ATK ${fmt(fighter.attackPower)}   DEF ${fmt(fighter.defence)}',
                ),
                if (fighter.isHero) ...[
                  const SizedBox(height: AppLayout.compactGap),
                  _XpBar(fighter: fighter),
                ],
                if (skill != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _SkillChargeBar(skill: skill),
                  ),
                if (fighter.statusLabel.isNotEmpty)
                  Text(
                    fighter.statusLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color? _backgroundColor(BuildContext context) {
    if (!fighter.isAlive) return AppColors.cardDefeated(context);
    if (selected) return AppColors.cardSelected(context);
    if (acted) return AppColors.cardActed(context);
    return null;
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final xpCap = fighter.xpCap;
    final ratio = xpCap == 0 ? 1.0 : fighter.xp / xpCap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('LVL ${fighter.level}')),
            Text('XP ${fighter.xp}/$xpCap'),
          ],
        ),
        const SizedBox(height: AppLayout.tinyGap),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.progressRadius),
          child: LinearProgressIndicator(
            minHeight: AppLayout.progressBarHeight,
            value: ratio.clamp(0, 1).toDouble(),
            backgroundColor: AppColors.progressTrack(context),
            valueColor: const AlwaysStoppedAnimation(AppColors.xpProgress),
          ),
        ),
      ],
    );
  }
}

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
