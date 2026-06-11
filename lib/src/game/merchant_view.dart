part of 'game_screen.dart';

/// The merchant's purchase list. Presentational only — every action delegates
/// to the screen's buy flows. [onChanged] lets a host (e.g. the merchant page)
/// refresh after a purchase; [onContinue] overrides the default "leave" action.
class _MerchantView extends StatelessWidget {
  const _MerchantView({required this.state, this.onChanged, this.onContinue});

  final _GameScreenState state;
  final VoidCallback? onChanged;
  final VoidCallback? onContinue;

  BattleController get battle => state.battle;

  void _merchantUpdate(VoidCallback action) {
    state.update(action);
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final goldWord = context.tr(K.gold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(K.merchant),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppLayout.compactGap),
        Text(context.tr(K.goldAmount, [battle.gold])),
        const SizedBox(height: AppLayout.sectionGap),
        _MerchantAction(
          icon: Icons.local_drink,
          title: context.tr(K.potionSmallXp),
          subtitle: context.tr(K.xpAmount, [GameBalance.smallXpPotionAmount]),
          cost: GameBalance.smallXpPotionCost,
          enabled: battle.canBuySmallXpPotion,
          onPressed: () => state._buyTargetedXpPotion(
            xp: GameBalance.smallXpPotionAmount,
            cost: GameBalance.smallXpPotionCost,
            label: context.tr(K.potionSmallXp),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.local_bar,
          title: context.tr(K.potionLargeXp),
          subtitle: context.tr(K.xpAmount, [GameBalance.largeXpPotionAmount]),
          cost: GameBalance.largeXpPotionCost,
          enabled: battle.canBuyLargeXpPotion,
          onPressed: () => state._buyTargetedXpPotion(
            xp: GameBalance.largeXpPotionAmount,
            cost: GameBalance.largeXpPotionCost,
            label: context.tr(K.potionLargeXp),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.science,
          title: context.tr(K.potionSuperXp),
          subtitle: context.tr(K.xpAmount, [GameBalance.superXpPotionAmount]),
          cost: GameBalance.superXpPotionCost,
          enabled: battle.canBuySuperXpPotion,
          onPressed: () => state._buyTargetedXpPotion(
            xp: GameBalance.superXpPotionAmount,
            cost: GameBalance.superXpPotionCost,
            label: context.tr(K.potionSuperXp),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.healing,
          title: context.tr(K.potionHealing),
          subtitle: context.tr(K.useOnInjured),
          cost: GameBalance.singlePotionCost,
          enabled: battle.canBuySinglePotion && battle.hasInjuredHero,
          onPressed: () => state._buyTargetedHealingPotion(onChanged: onChanged),
        ),
        const SizedBox(height: AppLayout.controlGap),
        OutlinedButton.icon(
          onPressed: battle.canBuySinglePotion
              ? () => _merchantUpdate(battle.buySinglePotionStock)
              : null,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            context.tr(K.stockHealing, [
              context.tr(K.costGold, [GameBalance.singlePotionCost, goldWord]),
            ]),
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.groups,
          title: context.tr(K.potionTeam),
          subtitle: context.tr(K.useOnAllInjured),
          cost: GameBalance.teamPotionCost,
          enabled: battle.canBuyTeamPotion && battle.hasInjuredHero,
          onPressed: () => _merchantUpdate(battle.buyTeamPotion),
        ),
        const SizedBox(height: AppLayout.controlGap),
        OutlinedButton.icon(
          onPressed: battle.canBuyTeamPotion
              ? () => _merchantUpdate(battle.buyTeamPotionStock)
              : null,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            context.tr(K.stockTeam, [
              context.tr(K.costGold, [GameBalance.teamPotionCost, goldWord]),
            ]),
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.auto_awesome,
          title: context.tr(K.potionSpecial),
          subtitle: context.tr(K.useRecharge),
          cost: GameBalance.specialPotionCost,
          enabled: battle.canBuySpecialPotion && state._hasRechargeableHero(),
          onPressed: () => state._buyTargetedSpecialPotion(onChanged: onChanged),
        ),
        const SizedBox(height: AppLayout.controlGap),
        OutlinedButton.icon(
          onPressed: battle.canBuySpecialPotion
              ? () => _merchantUpdate(battle.buySpecialPotionStock)
              : null,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            context.tr(K.stockSpecial, [
              context.tr(K.costGold, [GameBalance.specialPotionCost, goldWord]),
            ]),
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.add_chart,
          title: context.tr(K.specialBarUpgrade),
          subtitle: context.tr(K.specialBarUpgradeDesc),
          cost: GameBalance.specialBarUpgradeCost,
          enabled: battle.canBuySpecialBarUpgrade && state._hasHeroWithSkill(),
          onPressed: () =>
              state._buyTargetedSpecialBarUpgrade(onChanged: onChanged),
        ),
        const Divider(height: AppLayout.panelGap),
        OutlinedButton.icon(
          onPressed: onContinue ?? state._continueAfterMerchant,
          icon: const Icon(Icons.arrow_forward),
          label: Text(context.tr(K.continueLabel)),
        ),
      ],
    );
  }
}
