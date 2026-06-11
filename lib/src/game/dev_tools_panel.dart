part of 'game_screen.dart';

/// Dev-mode toolbar (gold/gems cheats, effect application, merchant). Only
/// rendered when dev mode is on. Buttons delegate to the screen's dev flows.
class _DevToolsPanel extends StatelessWidget {
  const _DevToolsPanel({required this.state, required this.compact});

  final _GameScreenState state;
  final bool compact;

  BattleController get battle => state.battle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.controlGap),
        child: Wrap(
          spacing: AppLayout.controlGap,
          runSpacing: AppLayout.controlGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              compact ? context.tr(K.devShort) : context.tr(K.devTools),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            OutlinedButton.icon(
              onPressed: () => state.update(battle.devAddGold),
              icon: const Icon(Icons.paid),
              label: Text(
                compact ? context.tr(K.addGoldShort) : context.tr(K.addGold),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => state.update(battle.devAddGems),
              icon: const Icon(Icons.diamond),
              label: Text(
                compact ? context.tr(K.addGemsShort) : context.tr(K.addGems),
              ),
            ),
            OutlinedButton.icon(
              onPressed: state._openDevEffectDialog,
              icon: const Icon(Icons.bolt),
              label: Text(
                compact ? context.tr(K.effectShort) : context.tr(K.applyEffect),
              ),
            ),
            OutlinedButton.icon(
              onPressed: battle.gameOver || battle.isAnimating
                  ? null
                  : state._devOpenMerchant,
              icon: const Icon(Icons.storefront),
              label: Text(
                compact ? context.tr(K.shopShort) : context.tr(K.openMerchant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
