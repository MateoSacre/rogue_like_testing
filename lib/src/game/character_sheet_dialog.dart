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
              fighter.name,
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
                  ..._itemRows(context),
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
    final base = context.tr(K.atkDef, [
      fmt(fighter.attackPower),
      fmt(fighter.baseDefence),
    ]);
    final buff = fighter.defence - fighter.baseDefence;
    return buff > 0 ? '$base (+${fmt(buff)})' : base;
  }

  // ── Derived combat stats ──────────────────────────────────────────────────

  List<Widget> _combatLines(BuildContext context) {
    final lines = <String>[
      context.tr(K.sheetCrit, [
        100 ~/ GameBalance.criticalHitChanceDivisor,
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
    return lines.map(Text.new).toList();
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
      final damage = sources.map((e) => e.damage).reduce(max);
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

  List<Widget> _itemRows(BuildContext context) {
    final rows = <Widget>[];
    for (final slot in [
      ItemSlot.helmet,
      ItemSlot.gloves,
      ItemSlot.chest,
      ItemSlot.weapon,
    ]) {
      final id = fighter.equipment[slot];
      final def = id == null ? null : itemById(id);
      rows.add(_itemRow(context, slot: slot, def: def, count: 1));
    }
    // Relics grouped by id, insertion order preserved.
    final counts = <String, int>{};
    for (final id in fighter.relics) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      final def = itemById(entry.key);
      if (def == null) continue;
      rows.add(
        _itemRow(context, slot: ItemSlot.relic, def: def, count: entry.value),
      );
    }
    return rows;
  }

  Widget _itemRow(
    BuildContext context, {
    required ItemSlot slot,
    required ItemDef? def,
    required int count,
  }) {
    final color = def == null
        ? Theme.of(context).colorScheme.outline
        : _itemRarityColor(def.rarity);
    final label = def == null
        ? '${context.l10n.itemSlot(slot)} : ${context.tr(K.itemSlotEmpty)}'
        : '${context.l10n.itemSlot(slot)} : '
              '${context.l10n.localized(def.name)}'
              '${count > 1 ? ' ×$count' : ''}';
    final row = Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.tinyGap),
      child: Row(
        children: [
          Icon(_itemSlotIcon(slot), size: AppLayout.iconSmall, color: color),
          const SizedBox(width: AppLayout.compactGap),
          Expanded(
            child: Text(label, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
    if (def == null) return row;
    return Tooltip(
      message: _itemTooltip(context, def, count),
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      waitDuration: Duration.zero,
      preferBelow: false,
      child: row,
    );
  }

  /// Individual description, plus the combined effect for stacked relics.
  String _itemTooltip(BuildContext context, ItemDef def, int count) {
    final lines = <String>[context.l10n.localized(def.description)];
    if (count > 1) {
      lines.add('');
      lines.add(context.tr(K.sheetCumulative, [count]));
      lines.addAll(_cumulativeLines(context, def, count));
    }
    return lines.join('\n');
  }

  List<String> _cumulativeLines(BuildContext context, ItemDef def, int count) {
    final lines = <String>[];
    final stats = <String>[
      if (def.hpBonus > 0)
        '${context.tr(K.statHp)} +${fmt(def.hpBonus * count)}',
      if (def.atkBonus > 0)
        '${context.tr(K.statAtk)} +${fmt(def.atkBonus * count)}',
      if (def.defBonus > 0)
        '${context.tr(K.statDef)} +${fmt(def.defBonus * count)}',
    ];
    if (stats.isNotEmpty) lines.add(stats.join(' · '));
    if (def.extraAttackChance > 0) {
      final total = min(
        def.extraAttackChance * count,
        GameBalance.extraAttackChanceCap,
      );
      lines.add(context.tr(K.sheetDoubleStrike, [_pct(total)]));
    }
    if (def.lifesteal > 0) {
      lines.add(context.tr(K.sheetLifesteal, [_pct(def.lifesteal * count)]));
    }
    final onHit = def.onHit;
    if (onHit != null) {
      final chance = combinedProcChance(List.filled(count, onHit.chance));
      lines.add(
        context.tr(K.sheetOnHit, [
          _dotLabel(context, onHit.name),
          _pct(chance),
          fmt(onHit.damage),
          onHit.duration,
        ]),
      );
    }
    return lines;
  }

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
