part of 'game_screen.dart';

/// Top-of-screen status line: round, alive counts, gold/gems, faction, the
/// inventory button and boss warnings. Has a full and a compact variant.
class _BattleSummary extends StatelessWidget {
  const _BattleSummary({required this.state, required this.compact});

  final _GameScreenState state;
  final bool compact;

  BattleController get battle => state.battle;

  @override
  Widget build(BuildContext context) =>
      compact ? _compactContent(context) : _fullContent(context);

  Widget _fullContent(BuildContext context) {
    return Wrap(
      spacing: AppLayout.panelGap,
      runSpacing: AppLayout.controlGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(context.tr(K.goldGems, [battle.gold, battle.gems])),
        OutlinedButton.icon(
          onPressed: state._openInventory,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            context.tr(K.inventoryCount, [
              battle.healingPotionStock +
                  battle.teamPotionStock +
                  battle.specialPotionStock,
            ]),
          ),
        ),
        if (battle.bossWaveIncoming)
          _BossWarning(
            icon: Icons.warning_amber,
            text: context.tr(K.bossIncoming),
          ),
        if (battle.waveInfo.finalWaveInTheme)
          _BossWarning(
            icon: Icons.local_fire_department,
            text: context.tr(K.bossDoubleReward),
          ),
      ],
    );
  }

  Widget _compactContent(BuildContext context) {
    return Wrap(
      spacing: AppLayout.controlGap,
      runSpacing: AppLayout.tinyGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(context.tr(K.goldShort, [battle.gold])),
        Text(context.tr(K.gemsShort, [battle.gems])),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: context.tr(K.inventory),
          onPressed: state._openInventory,
          icon: Badge.count(
            count:
                battle.healingPotionStock +
                battle.teamPotionStock +
                battle.specialPotionStock,
            child: const Icon(Icons.inventory_2),
          ),
        ),
        if (battle.bossWaveIncoming || battle.waveInfo.finalWaveInTheme)
          Icon(
            battle.waveInfo.finalWaveInTheme
                ? Icons.local_fire_department
                : Icons.warning_amber,
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }
}
