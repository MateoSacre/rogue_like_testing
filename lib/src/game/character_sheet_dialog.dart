part of 'game_screen.dart';

/// Character sheet: stats, active effects, derived combat stats (crit,
/// double strike, lifesteal, on-hit procs) and held items. Hovering/tapping
/// an item shows its individual effect, plus the combined effect when the
/// hero holds several copies of the same relic.
class _CharacterSheetDialog extends StatelessWidget {
  const _CharacterSheetDialog({required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.creatureName(fighter.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (fighter.isHero)
            Text(
              context.tr(K.level, [fighter.level]),
              style: Theme.of(context).textTheme.titleSmall,
            ),
        ],
      ),
      content: SizedBox(
        width: AppLayout.dialogWidth(context, 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fighter.rarity != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppLayout.tinyGap),
                  child: Row(
                    children: [
                      RarityStars(rarity: fighter.rarity!, size: 16),
                      const SizedBox(width: AppLayout.compactGap),
                      Text(
                        context.l10n.creatureRarity(fighter.rarity!),
                        style: TextStyle(
                          color: AppColors.creatureRarity(fighter.rarity!),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              _sectionTitle(context, K.sheetStats),
              Text(context.tr(K.hp, [fmt(fighter.hp), fmt(fighter.maxHp)])),
              Text(_atkDefLine(context)),
              if (fighter.isHero)
                Text(context.tr(K.xpValue, [fighter.xp, fighter.xpCap])),
              if (fighter.skill != null) ...[
                _sectionTitle(context, K.sheetSkill),
                Text(
                  context.tr(K.skillChargeLine, [
                    fighter.skill!.name,
                    fighter.skill!.description,
                    fighter.skill!.charge,
                    fighter.skill!.maxCharge,
                  ]),
                ),
              ],
              _sectionTitle(context, K.sheetCombat),
              ..._combatLines(context),
              _sectionTitle(context, K.sheetEffects),
              if (fighter.effects.isEmpty)
                Text(context.tr(K.sheetNoEffects))
              else
                ...fighter.effects.map(
                  (effect) => Text(_effectLine(context, effect)),
                ),
              if (fighter.isHero) ...[
                _sectionTitle(context, K.sheetEquipment),
                if (fighter.itemCount == 0)
                  Text(context.tr(K.sheetNoItems))
                else
                  EquipmentGrid(fighter: fighter),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr(K.close)),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, K key) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppLayout.sectionGap,
        bottom: AppLayout.tinyGap,
      ),
      child: Text(
        context.tr(key),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  String _atkDefLine(BuildContext context) {
    // Effective values include active buffs (attack/defence) and items.
    return context.tr(K.atkDef, [fmt(fighter.attack), fmt(fighter.defence)]);
  }

  // ── Derived combat stats ──────────────────────────────────────────────────

  List<Widget> _combatLines(BuildContext context) {
    final lines = <String>[
      context.tr(K.sheetCrit, [
        _pct(fighter.critChance),
        fmt(GameBalance.criticalHitModifier),
      ]),
    ];
    if (fighter.extraAttackChance > 0) {
      lines.add(
        context.tr(K.sheetDoubleStrike, [_pct(fighter.extraAttackChance)]),
      );
    }
    if (fighter.lifesteal > 0) {
      lines.add(context.tr(K.sheetLifesteal, [_pct(fighter.lifesteal)]));
    }
    lines.addAll(_onHitSummaryLines(context, fighter.onHitEffects));
    lines.addAll(_resistLines(context));
    return lines.map(Text.new).toList();
  }

  /// Resistance relics carried by the fighter (DoT reduction/negation/immunity
  /// per type, plus lifesteal reduction).
  List<String> _resistLines(BuildContext context) {
    final lines = <String>[];
    for (final type in [DotType.poison, DotType.bleed, DotType.burn]) {
      final flat = fighter.dotFlatReduction(type);
      final negate = fighter.dotNegateChance(type);
      final label = _dotTypeLabel(context, type);
      if (negate >= 1) {
        lines.add(context.tr(K.sheetResistImmune, [label]));
      } else {
        if (flat > 0) {
          lines.add(context.tr(K.sheetResistFlat, [label, fmt(flat)]));
        }
        if (negate > 0) {
          lines.add(context.tr(K.sheetResistNegate, [label, _pct(negate)]));
        }
      }
    }
    if (fighter.lifestealResist > 0) {
      lines.add(
        context.tr(K.sheetLifestealResist, [_pct(fighter.lifestealResist)]),
      );
    }
    return lines;
  }

  String _dotTypeLabel(BuildContext context, DotType type) {
    return switch (type) {
      DotType.poison => context.tr(K.dotPoison),
      DotType.bleed => context.tr(K.dotBleed),
      DotType.burn => context.tr(K.dotBurn),
      DotType.generic => '',
    };
  }

  /// One line per distinct on-hit effect name, with the effective chance
  /// that at least one source procs, and the strongest damage/duration.
  List<String> _onHitSummaryLines(
    BuildContext context,
    Iterable<ItemOnHit> effects,
  ) {
    final byName = <String, List<ItemOnHit>>{};
    for (final effect in effects) {
      byName.putIfAbsent(effect.name, () => []).add(effect);
    }
    return byName.entries.map((entry) {
      final sources = entry.value;
      final chance = combinedProcChance(sources.map((e) => e.chance));
      // DoT ticks now scale with the holder's ATK (snapshot at proc time).
      final damage = sources
          .map((e) => e.tickDamage(fighter.attack))
          .reduce(max);
      final duration = sources.map((e) => e.duration).reduce(max);
      return context.tr(K.sheetOnHit, [
        _dotLabel(context, entry.key),
        _pct(chance),
        fmt(damage),
        duration,
      ]);
    }).toList();
  }

  // ── Active effects ────────────────────────────────────────────────────────

  String _effectLine(BuildContext context, StatusEffect effect) {
    final parts = <String>[];
    if (effect.kind == EffectKind.recurrent && effect.damage > 0) {
      parts.add(context.tr(K.fxDamagePerTurn, [fmt(effect.damage)]));
    }
    if (effect.kind == EffectKind.buff && effect.defenceBonus != 0) {
      final signed =
          '${effect.defenceBonus > 0 ? '+' : ''}${fmt(effect.defenceBonus)}';
      parts.add(context.tr(K.fxDefence, [signed]));
    }
    if (parts.isEmpty) parts.add(effect.kind.name);
    final remaining = effect.duration == 1
        ? context.tr(K.fxTurnRemaining)
        : context.tr(K.fxTurnsRemaining, [effect.duration]);
    return context.tr(K.fxLine, [effect.name, parts.join(', '), remaining]);
  }

  // ── Items ─────────────────────────────────────────────────────────────────

  String _dotLabel(BuildContext context, String effectName) {
    return switch (effectName) {
      'Bleed' => context.tr(K.dotBleed),
      'Poison' => context.tr(K.dotPoison),
      'Burn' => context.tr(K.dotBurn),
      _ => effectName,
    };
  }

  int _pct(double value) => (value * 100).round();
}
