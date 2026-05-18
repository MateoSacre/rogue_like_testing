import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/level_up_stat.dart';
import '../models/team.dart';
import '../persistence/save_service.dart';
import '../settings/game_settings.dart';
import '../settings/settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../utils/format.dart';
import '../widgets/fighter_card.dart';
import 'battle_controller.dart';
import 'game_balance.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.settings,
    required this.onSettingsChanged,
    this.initialBattleJson,
    super.key,
  });

  final GameSettings settings;
  final Map<String, dynamic>? initialBattleJson;
  final ValueChanged<GameSettings> onSettingsChanged;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BattleController battle;
  final ScrollController _heroesScrollController = ScrollController();
  final ScrollController _centerScrollController = ScrollController();
  final ScrollController _enemiesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    battle = widget.initialBattleJson == null
        ? BattleController()
        : BattleController.fromJson(widget.initialBattleJson!);
  }

  @override
  void dispose() {
    _heroesScrollController.dispose();
    _centerScrollController.dispose();
    _enemiesScrollController.dispose();
    super.dispose();
  }

  void update(void Function() action) {
    setState(action);
    saveGame();
  }

  Future<void> _mobAttackDelay() {
    return Future<void>.delayed(widget.settings.autoAttackSpeed.duration);
  }

  void _refresh() {
    if (mounted) setState(() {});
    saveGame();
  }

  Future<void> saveGame() {
    return SaveService.save(settings: widget.settings, battle: battle);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppLayout.wideBreakpoint;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wave ${battle.waveCounter} - ${battle.waveInfo.category.label}',
        ),
        actions: [
          IconButton(
            tooltip: 'Restart',
            onPressed: () => update(battle.resetGame),
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            tooltip: 'Reglages',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.pagePadding),
          child: isWide ? _wideLayout() : _narrowLayout(),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return SettingsScreen(
            settings: widget.settings,
            onChanged: (settings) {
              widget.onSettingsChanged(settings);
              SaveService.save(settings: settings, battle: battle);
            },
          );
        },
      ),
    );
  }

  Widget _wideLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _topPanel(),
        const SizedBox(height: AppLayout.panelGap),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _gridTeamPanel('Heroes', battle.heroes, true)),
              const SizedBox(width: AppLayout.panelGap),
              Expanded(child: _gridTeamPanel('Enemies', battle.mobs, false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 36,
          child: _compactGridTeamPanel('Enemies', battle.mobs, false),
        ),
        const SizedBox(height: AppLayout.controlGap),
        Expanded(flex: 28, child: _centerPanel(compact: true)),
        const SizedBox(height: AppLayout.controlGap),
        Expanded(
          flex: 36,
          child: _compactGridTeamPanel('Heroes', battle.heroes, true),
        ),
      ],
    );
  }

  Widget _centerPanel({bool compact = false}) {
    if (!compact) return _battleControlsPanel(showSummary: true);
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: _battleControlsPanel(showSummary: true, compact: true),
          ),
        );
      },
    );
  }

  Widget _topPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.summaryPadding),
        child: _battleControlsPanel(showSummary: true),
      ),
    );
  }

  Widget _battleControlsPanel({
    required bool showSummary,
    bool compact = false,
  }) {
    final hero = battle.selectedHero;
    final skill = hero?.skill;
    final targets = battle.targetsForSelectedAction();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSummary) ...[
          compact ? _compactSummaryContent() : _summaryContent(),
          SizedBox(
            height: compact ? AppLayout.compactGap : AppLayout.sectionGap,
          ),
        ],
        if (battle.gameOver)
          FilledButton.icon(
            onPressed: () => update(battle.resetGame),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Restart run'),
          )
        else if (battle.merchantAvailable)
          compact
              ? FilledButton.icon(
                  onPressed: _openMerchantPage,
                  icon: const Icon(Icons.storefront),
                  label: const Text('Open shop'),
                )
              : _merchantPanel()
        else ...[
          Text('Hero action', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppLayout.controlGap),
          SegmentedButton<ActionMode>(
            segments: [
              const ButtonSegment(
                value: ActionMode.attack,
                icon: Icon(Icons.gps_fixed),
                label: Text('Attack'),
              ),
              ButtonSegment(
                value: ActionMode.skill,
                enabled: skill?.isReady == true,
                icon: const Icon(Icons.auto_awesome),
                label: Text(skill == null ? 'Skill' : skill.name),
              ),
            ],
            selected: {battle.actionMode},
            onSelectionChanged: battle.isAnimating || battle.autoAttackEnabled
                ? null
                : (selection) =>
                      update(() => battle.setAction(selection.first)),
          ),
          SizedBox(
            height: compact
                ? AppLayout.compactGap
                : AppLayout.warningHorizontalPadding,
          ),
          if (skill != null && !compact)
            Text(
              '${skill.name}: ${skill.description}'
              ' - Charge ${skill.charge}/${skill.maxCharge}',
            ),
          if (!compact) ...[
            const SizedBox(height: AppLayout.sectionGap),
            Wrap(
              spacing: AppLayout.controlGap,
              runSpacing: AppLayout.controlGap,
              children: targets.map((target) {
                final selected = battle.selectedTarget == target;
                return ChoiceChip(
                  selected: selected,
                  label: _TargetPreviewLabel(
                    name: target.name,
                    preview: battle.previewForTarget(target),
                  ),
                  onSelected: battle.isAnimating || battle.autoAttackEnabled
                      ? null
                      : (_) => update(() => battle.selectedTarget = target),
                );
              }).toList(),
            ),
            const SizedBox(height: AppLayout.sectionGap),
          ],
          Wrap(
            spacing: AppLayout.controlGap,
            runSpacing: AppLayout.controlGap,
            children: [
              FilledButton.icon(
                onPressed: battle.canAct
                    ? () async {
                        await battle.performSelectedAction(
                          pause: _mobAttackDelay,
                          notify: _refresh,
                          levelUpMode: widget.settings.levelUpMode,
                        );
                        await _resolvePendingLevelUps();
                        _refresh();
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  compact
                      ? (hero == null ? 'Hero' : 'Act')
                      : (hero == null ? 'Choose a hero' : 'Act with ${hero.name}'),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    battle.gameOver ||
                        (battle.isAnimating && !battle.autoAttackEnabled)
                    ? null
                    : () async {
                        if (battle.autoAttackEnabled) {
                          update(battle.stopAutoAttack);
                          return;
                        }
                        update(() => battle.autoAttackEnabled = true);
                        await battle.performAutoAttack(
                          pause: _mobAttackDelay,
                          notify: _refresh,
                          useSkills: widget.settings.autoUseSkills,
                          levelUpMode: widget.settings.levelUpMode,
                        );
                        await _resolvePendingLevelUps();
                        _refresh();
                      },
                icon: Icon(
                  battle.autoAttackEnabled
                      ? Icons.pause_circle
                      : Icons.flash_auto,
                ),
                label: Text(
                  compact
                      ? (battle.autoAttackEnabled ? 'Auto ON' : 'Auto')
                      : (battle.autoAttackEnabled
                            ? 'Auto attack ON'
                            : 'Auto attack OFF'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _resolvePendingLevelUps() async {
    while (mounted && battle.pendingLevelUps.isNotEmpty) {
      final pending = battle.pendingLevelUps.first;
      final stat = await showDialog<LevelUpStat>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return _LevelUpDialog(pending: pending, battle: battle);
        },
      );
      if (stat == null) return;
      setState(() => battle.resolvePendingLevelUp(pending, stat));
    }
  }

  Widget _summaryContent() {
    return Wrap(
      spacing: AppLayout.panelGap,
      runSpacing: AppLayout.controlGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Round ${battle.roundCounter}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${battle.heroes.alive.length}/${battle.heroes.members.length} heroes alive'
          '   ${battle.mobs.alive.length}/${battle.mobs.members.length} enemies alive',
        ),
        Text('Gold: ${battle.gold}   Gems: ${battle.gems}'),
        Text('Enemy faction: ${battle.waveInfo.category.label}'),
        OutlinedButton.icon(
          onPressed: _openInventory,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            'Inventory ${battle.healingPotionStock + battle.teamPotionStock + battle.specialPotionStock}',
          ),
        ),
        if (battle.bossWaveIncoming)
          const _BossWarning(
            icon: Icons.warning_amber,
            text: 'Boss wave incoming next',
          ),
        if (battle.waveInfo.finalWaveInTheme)
          const _BossWarning(
            icon: Icons.local_fire_department,
            text: 'Boss wave: double reward',
          ),
      ],
    );
  }

  Widget _compactSummaryContent() {
    return Wrap(
      spacing: AppLayout.controlGap,
      runSpacing: AppLayout.tinyGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'R${battle.roundCounter}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'H ${battle.heroes.alive.length}/${battle.heroes.members.length}',
        ),
        Text('E ${battle.mobs.alive.length}/${battle.mobs.members.length}'),
        Text('G ${battle.gold}'),
        Text('Gem ${battle.gems}'),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Inventory',
          onPressed: _openInventory,
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

  Widget _merchantPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.cardPadding),
        child: _merchantContent(),
      ),
    );
  }

  Widget _merchantContent({
    VoidCallback? onChanged,
    VoidCallback? onContinue,
  }) {
    void merchantUpdate(VoidCallback action) {
      update(action);
      onChanged?.call();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Merchant', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppLayout.compactGap),
        Text('Gold: ${battle.gold}'),
        const SizedBox(height: AppLayout.sectionGap),
        _MerchantAction(
          icon: Icons.local_drink,
          title: 'Small XP potion',
          subtitle: '+${GameBalance.smallXpPotionAmount} XP',
          cost: GameBalance.smallXpPotionCost,
          enabled: battle.canBuySmallXpPotion,
          onPressed: () => _buyTargetedXpPotion(
            xp: GameBalance.smallXpPotionAmount,
            cost: GameBalance.smallXpPotionCost,
            label: 'Small XP potion',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.local_bar,
          title: 'Large XP potion',
          subtitle: '+${GameBalance.largeXpPotionAmount} XP',
          cost: GameBalance.largeXpPotionCost,
          enabled: battle.canBuyLargeXpPotion,
          onPressed: () => _buyTargetedXpPotion(
            xp: GameBalance.largeXpPotionAmount,
            cost: GameBalance.largeXpPotionCost,
            label: 'Large XP potion',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.science,
          title: 'Super XP potion',
          subtitle: '+${GameBalance.superXpPotionAmount} XP',
          cost: GameBalance.superXpPotionCost,
          enabled: battle.canBuySuperXpPotion,
          onPressed: () => _buyTargetedXpPotion(
            xp: GameBalance.superXpPotionAmount,
            cost: GameBalance.superXpPotionCost,
            label: 'Super XP potion',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.healing,
          title: 'Healing potion',
          subtitle: 'Use now on an injured hero',
          cost: GameBalance.singlePotionCost,
          enabled: battle.canBuySinglePotion && battle.hasInjuredHero,
          onPressed: () => _buyTargetedHealingPotion(onChanged: onChanged),
        ),
        const SizedBox(height: AppLayout.controlGap),
        OutlinedButton.icon(
          onPressed: battle.canBuySinglePotion
              ? () => merchantUpdate(battle.buySinglePotionStock)
              : null,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            'Stock healing potion - ${GameBalance.singlePotionCost} gold',
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.groups,
          title: 'Team potion',
          subtitle: 'Use now on all injured heroes',
          cost: GameBalance.teamPotionCost,
          enabled: battle.canBuyTeamPotion && battle.hasInjuredHero,
          onPressed: () => merchantUpdate(battle.buyTeamPotion),
        ),
        const SizedBox(height: AppLayout.controlGap),
        OutlinedButton.icon(
          onPressed: battle.canBuyTeamPotion
              ? () => merchantUpdate(battle.buyTeamPotionStock)
              : null,
          icon: const Icon(Icons.inventory_2),
          label: Text('Stock team potion - ${GameBalance.teamPotionCost} gold'),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.auto_awesome,
          title: 'Special attack potion',
          subtitle: 'Use now to fully recharge a special',
          cost: GameBalance.specialPotionCost,
          enabled: battle.canBuySpecialPotion && _hasRechargeableHero(),
          onPressed: () => _buyTargetedSpecialPotion(onChanged: onChanged),
        ),
        const SizedBox(height: AppLayout.controlGap),
        OutlinedButton.icon(
          onPressed: battle.canBuySpecialPotion
              ? () => merchantUpdate(battle.buySpecialPotionStock)
              : null,
          icon: const Icon(Icons.inventory_2),
          label: Text(
            'Stock special potion - ${GameBalance.specialPotionCost} gold',
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        _MerchantAction(
          icon: Icons.add_chart,
          title: 'Special bar upgrade',
          subtitle: 'Adds one extra special charge bar',
          cost: GameBalance.specialBarUpgradeCost,
          enabled: battle.canBuySpecialBarUpgrade && _hasHeroWithSkill(),
          onPressed: () =>
              _buyTargetedSpecialBarUpgrade(onChanged: onChanged),
        ),
        const Divider(height: AppLayout.panelGap),
        OutlinedButton.icon(
          onPressed: onContinue ?? () => update(battle.continueAfterMerchant),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue'),
        ),
      ],
    );
  }

  Future<void> _openMerchantPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setPageState) {
              return Scaffold(
                appBar: AppBar(title: const Text('Merchant')),
                body: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(AppLayout.pagePadding),
                    children: [
                      _merchantContent(
                        onChanged: () => setPageState(() {}),
                        onContinue: () {
                          update(battle.continueAfterMerchant);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
    _refresh();
  }

  Future<void> _buyTargetedXpPotion({
    required int xp,
    required int cost,
    required String label,
    VoidCallback? onChanged,
  }) async {
    final hero = await _pickHero(
      title: label,
      heroes: battle.heroes.alive,
      showXp: true,
    );
    if (hero == null) return;
    update(() => battle.buyXpPotion(hero, xp: xp, cost: cost, label: label));
    await _resolvePendingLevelUps();
    _refresh();
    onChanged?.call();
  }

  Future<void> _buyTargetedHealingPotion({VoidCallback? onChanged}) async {
    final hero = await _pickHero(
      title: 'Healing potion',
      heroes: battle.heroes.alive.where((hero) => hero.hp < hero.maxHp),
      subtitleFor: (hero) => 'HP ${fmt(hero.hp)}/${fmt(hero.maxHp)}',
    );
    if (hero == null) return;
    update(() => battle.buySinglePotion(hero));
    onChanged?.call();
  }

  Future<void> _buyTargetedSpecialPotion({VoidCallback? onChanged}) async {
    final hero = await _pickHero(
      title: 'Special attack potion',
      heroes: battle.heroes.alive.where((hero) {
        final skill = hero.skill;
        return skill != null && skill.charge < skill.maxCharge;
      }),
      subtitleFor: _specialSubtitle,
    );
    if (hero == null) return;
    update(() => battle.buySpecialPotion(hero));
    onChanged?.call();
  }

  Future<void> _buyTargetedSpecialBarUpgrade({VoidCallback? onChanged}) async {
    final hero = await _pickHero(
      title: 'Special bar upgrade',
      heroes: battle.heroes.alive.where((hero) => hero.skill != null),
      subtitleFor: _specialSubtitle,
    );
    if (hero == null) return;
    update(() => battle.buySpecialBarUpgrade(hero));
    onChanged?.call();
  }

  Future<Fighter?> _pickHero({
    required String title,
    required Iterable<Fighter> heroes,
    String Function(Fighter hero)? subtitleFor,
    bool showXp = false,
  }) {
    final choices = heroes.toList();
    return showDialog<Fighter>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(title),
          children: choices
              .map(
                (hero) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(hero),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hero.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (subtitleFor != null) Text(subtitleFor(hero)),
                      if (showXp) ...[
                        const SizedBox(height: AppLayout.tinyGap),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Level ${hero.level}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              'XP ${hero.xp}/${hero.xpCap}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.tinyGap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppLayout.progressRadius,
                          ),
                          child: LinearProgressIndicator(
                            minHeight: AppLayout.progressBarHeight,
                            value: (hero.xpCap == 0 ? 1 : hero.xp / hero.xpCap)
                                .clamp(0, 1)
                                .toDouble(),
                            backgroundColor: AppColors.progressTrack(context),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.xpProgress,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _openInventory() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void useItem(_InventoryItemKind kind, Fighter hero) {
              final used = _useInventoryItem(kind, hero);
              if (!used) return;
              setDialogState(() {});
            }

            return AlertDialog(
              title: const Text('Inventory'),
              content: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppLayout.controlGap,
                      runSpacing: AppLayout.controlGap,
                      children: _inventoryItems()
                          .map(
                            (item) => _InventoryDraggable(
                              item: item,
                              enabled: item.count > 0,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    Text(
                      'Drop on a hero',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppLayout.controlGap),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: AppLayout.controlGap,
                          runSpacing: AppLayout.controlGap,
                          children: battle.heroes.members.map((hero) {
                            return _InventoryHeroTarget(
                              hero: hero,
                              canUse: _canUseAnyInventoryItem(hero),
                              onAccept: useItem,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_InventoryItem> _inventoryItems() {
    return [
      _InventoryItem(
        kind: _InventoryItemKind.healing,
        icon: Icons.healing,
        label: 'Healing',
        count: battle.healingPotionStock,
      ),
      _InventoryItem(
        kind: _InventoryItemKind.team,
        icon: Icons.groups,
        label: 'Team',
        count: battle.teamPotionStock,
      ),
      _InventoryItem(
        kind: _InventoryItemKind.special,
        icon: Icons.auto_awesome,
        label: 'Special',
        count: battle.specialPotionStock,
      ),
    ];
  }

  bool _useInventoryItem(_InventoryItemKind kind, Fighter hero) {
    if (!hero.isAlive) return false;
    switch (kind) {
      case _InventoryItemKind.healing:
        if (battle.healingPotionStock <= 0 || hero.hp >= hero.maxHp) {
          return false;
        }
        update(() => battle.useHealingPotion(hero));
        return true;
      case _InventoryItemKind.team:
        if (battle.teamPotionStock <= 0 || !battle.hasInjuredHero) return false;
        update(battle.useTeamPotion);
        return true;
      case _InventoryItemKind.special:
        final skill = hero.skill;
        if (battle.specialPotionStock <= 0 ||
            skill == null ||
            skill.charge >= skill.maxCharge) {
          return false;
        }
        update(() => battle.useSpecialPotion(hero));
        return true;
    }
  }

  bool _canUseAnyInventoryItem(Fighter hero) {
    return hero.isAlive &&
        ((battle.healingPotionStock > 0 && hero.hp < hero.maxHp) ||
            battle.teamPotionStock > 0 ||
            (battle.specialPotionStock > 0 &&
                hero.skill != null &&
                hero.skill!.charge < hero.skill!.maxCharge));
  }

  bool _hasHeroWithSkill() {
    return battle.heroes.alive.any((hero) => hero.skill != null);
  }

  bool _hasRechargeableHero() {
    return battle.heroes.alive.any((hero) {
      final skill = hero.skill;
      return skill != null && skill.charge < skill.maxCharge;
    });
  }

  String _specialSubtitle(Fighter hero) {
    final skill = hero.skill;
    if (skill == null) return '';
    return '${skill.name}: ${skill.charge}/${skill.maxCharge}';
  }

  Widget _gridTeamPanel(String title, Team team, bool heroes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppLayout.controlGap),
        Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: AppLayout.fighterCardMaxWidth,
              mainAxisExtent: heroes
                  ? AppLayout.heroCardHeight
                  : AppLayout.enemyCardHeight,
              crossAxisSpacing: AppLayout.controlGap,
              mainAxisSpacing: AppLayout.controlGap,
            ),
            children: _fighterCards(team, heroes, padded: false),
          ),
        ),
      ],
    );
  }

  Widget _compactGridTeamPanel(String title, Team team, bool heroes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppLayout.controlGap),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = _compactTeamColumns(team);
              final rows = (team.members.length / columns).ceil();
              final safeRows = rows == 0 ? 1 : rows;
              final preferredHeight = heroes
                  ? AppLayout.compactHeroCardHeight
                  : AppLayout.compactEnemyCardHeight;
              final availableHeight =
                  constraints.maxHeight -
                  (safeRows - 1) * AppLayout.controlGap;
              final cardHeight = (availableHeight / safeRows)
                  .clamp(heroes ? 68.0 : 54.0, preferredHeight)
                  .toDouble();

              return GridView(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: cardHeight,
                  crossAxisSpacing: AppLayout.controlGap,
                  mainAxisSpacing: AppLayout.controlGap,
                ),
                children: _fighterCards(
                  team,
                  heroes,
                  padded: false,
                  compact: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  int _compactTeamColumns(Team team) {
    final size = team.members.length;
    if (size <= 0) return 1;
    if (size <= 3) return 1;
    return 2;
  }

  List<Widget> _fighterCards(
    Team team,
    bool heroes, {
    bool padded = true,
    bool compact = false,
  }) {
    return team.members.map((fighter) {
      final canPickHero =
          heroes &&
          !battle.autoAttackEnabled &&
          !battle.merchantAvailable &&
          fighter.isAlive &&
          battle.availableHeroes.contains(fighter);
      final hasActed =
          heroes && fighter.isAlive && battle.actedHeroes.contains(fighter);
      final selected =
          battle.selectedHero == fighter ||
          battle.activeMob == fighter ||
          battle.activeMobTarget == fighter ||
          battle.selectedTarget == fighter;
      final canToggleTarget = !heroes && battle.canToggleEnemyTarget(fighter);
      final card = FighterCard(
        fighter: fighter,
        selected: selected,
        pickable: canPickHero,
        acted: hasActed,
        compact: compact,
        onTap: canPickHero && !battle.isAnimating && !battle.autoAttackEnabled
            ? () => update(() => battle.selectHero(fighter))
            : canToggleTarget
            ? () => update(() => battle.toggleEnemyTarget(fighter))
            : null,
      );
      if (!padded) return card;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppLayout.controlGap),
        child: card,
      );
    }).toList();
  }
}

class _TargetPreviewLabel extends StatelessWidget {
  const _TargetPreviewLabel({required this.name, required this.preview});

  final String name;
  final String preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name),
        if (preview.isNotEmpty)
          Text(
            preview,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

enum _InventoryItemKind { healing, team, special }

class _InventoryItem {
  const _InventoryItem({
    required this.kind,
    required this.icon,
    required this.label,
    required this.count,
  });

  final _InventoryItemKind kind;
  final IconData icon;
  final String label;
  final int count;
}

class _InventoryDraggable extends StatelessWidget {
  const _InventoryDraggable({required this.item, required this.enabled});

  final _InventoryItem item;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chip = _InventoryChip(item: item, enabled: enabled);
    if (!enabled) return chip;
    return Draggable<_InventoryItemKind>(
      data: item.kind,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
        child: _InventoryChip(item: item, enabled: true),
      ),
      childWhenDragging: Opacity(opacity: .45, child: chip),
      child: chip,
    );
  }
}

class _InventoryChip extends StatelessWidget {
  const _InventoryChip({required this.item, required this.enabled});

  final _InventoryItem item;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.warningHorizontalPadding,
          vertical: AppLayout.warningVerticalPadding,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLayout.borderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: AppLayout.iconMedium),
            const SizedBox(width: AppLayout.controlGap),
            Text('${item.label} x${item.count}'),
          ],
        ),
      ),
    );
  }
}

class _InventoryHeroTarget extends StatelessWidget {
  const _InventoryHeroTarget({
    required this.hero,
    required this.canUse,
    required this.onAccept,
  });

  final Fighter hero;
  final bool canUse;
  final void Function(_InventoryItemKind kind, Fighter hero) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_InventoryItemKind>(
      onWillAcceptWithDetails: (_) => canUse,
      onAcceptWithDetails: (details) {
        onAccept(details.data, hero);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 180,
          padding: const EdgeInsets.all(AppLayout.cardPadding),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.cardSelected(context) : null,
            borderRadius: BorderRadius.circular(AppLayout.borderRadius),
            border: Border.all(
              color: highlighted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Opacity(
            opacity: hero.isAlive ? 1 : .42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppLayout.tinyGap),
                Text('HP ${fmt(hero.hp)}/${fmt(hero.maxHp)}'),
                if (hero.skill != null)
                  Text(
                    '${hero.skill!.charge}/${hero.skill!.maxCharge} special',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MerchantAction extends StatelessWidget {
  const _MerchantAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int cost;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppLayout.compactGap),
        child: Row(
          children: [
            Icon(icon, size: AppLayout.iconMedium),
            const SizedBox(width: AppLayout.controlGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: AppLayout.controlGap),
            Text('${cost}g'),
          ],
        ),
      ),
    );
  }
}

class _LevelUpDialog extends StatelessWidget {
  const _LevelUpDialog({required this.pending, required this.battle});

  final PendingLevelUp pending;
  final BattleController battle;

  @override
  Widget build(BuildContext context) {
    final hero = pending.hero;
    return AlertDialog(
      title: Text('${hero.name} gagne un niveau'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: LevelUpStat.values.map((stat) {
          final increase = battle.levelUpIncreaseFor(hero, stat);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.controlGap),
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(stat),
              child: Text(stat.describe(hero, increase)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BossWarning extends StatelessWidget {
  const _BossWarning({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = AppColors.warningForeground(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.warningHorizontalPadding,
        vertical: AppLayout.warningVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBackground(context),
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
        border: Border.all(color: AppColors.warningBorder(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: AppLayout.iconMedium),
          const SizedBox(width: AppLayout.controlGap),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
