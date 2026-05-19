import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/level_up_stat.dart';
import '../models/status_effect.dart';
import '../models/team.dart';
import '../persistence/save_service.dart';
import '../progression/player_progress.dart';
import '../settings/game_settings.dart';
import '../settings/settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../utils/format.dart';
import '../widgets/fighter_card.dart';
import 'battle_controller.dart';
import 'game_balance.dart';

part 'boss_warning.dart';
part 'inventory_widgets.dart';
part 'level_up_dialog.dart';
part 'merchant_action.dart';
part 'target_preview_label.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.settings,
    required this.progress,
    required this.initialHeroes,
    required this.onSettingsChanged,
    required this.onProgressChanged,
    required this.onBattleSaved,
    required this.onResetProgress,
    this.initialBattleJson,
    super.key,
  });

  final GameSettings settings;
  final PlayerProgress progress;
  final Map<String, dynamic>? initialBattleJson;
  final List<Fighter> initialHeroes;
  final ValueChanged<GameSettings> onSettingsChanged;
  final ValueChanged<PlayerProgress> onProgressChanged;
  final ValueChanged<Map<String, dynamic>?> onBattleSaved;
  final Future<void> Function() onResetProgress;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BattleController battle;
  late GameSettings settings;
  final ScrollController _heroesScrollController = ScrollController();
  final ScrollController _centerScrollController = ScrollController();
  final ScrollController _enemiesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
    battle = widget.initialBattleJson == null
        ? BattleController(
            heroes: widget.initialHeroes,
            gems: widget.progress.gems,
            seedString: settings.seedString,
          )
        : BattleController.fromJson(
            widget.initialBattleJson!,
            seedString: settings.seedString,
          );
    battle.devMode = settings.devMode;
    _syncProgressGems();
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
    return Future<void>.delayed(settings.autoAttackSpeed.duration);
  }

  void _refresh() {
    if (mounted) setState(() {});
    saveGame();
  }

  Future<void> saveGame() {
    _syncProgressGems();
    final battleJson = battle.toJson();
    widget.onBattleSaved(battleJson);
    return SaveService.save(
      settings: settings,
      progress: widget.progress,
      battleJson: battleJson,
    );
  }

  void _syncProgressGems() {
    if (widget.progress.gems == battle.gems) return;
    widget.progress.gems = battle.gems;
    widget.onProgressChanged(widget.progress);
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
            onPressed: () => update(
              () => battle.resetGame(
                heroes: widget.initialHeroes,
                gems: widget.progress.gems,
              ),
            ),
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
    final reset = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return SettingsScreen(
            settings: settings,
            onChanged: (value) {
              setState(() => settings = value);
              battle.devMode = value.devMode;
              battle.seedString = value.seedString;
              widget.onSettingsChanged(value);
              SaveService.save(
                settings: value,
                progress: widget.progress,
                battle: battle,
              );
            },
            onResetProgress: widget.onResetProgress,
          );
        },
      ),
    );
    if (reset == true && mounted) {
      Navigator.of(context).pop();
    }
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
        if (settings.devMode) ...[
          _devToolsPanel(compact: compact),
          SizedBox(
            height: compact ? AppLayout.compactGap : AppLayout.sectionGap,
          ),
        ],
        if (battle.gameOver)
          FilledButton.icon(
            onPressed: () => update(
              () => battle.resetGame(
                heroes: widget.initialHeroes,
                gems: widget.progress.gems,
              ),
            ),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Restart run'),
          )
        else if (battle.merchantAvailable)
          compact ? _compactMerchantActions() : _merchantPanel()
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
                          levelUpMode: settings.levelUpMode,
                        );
                        await _resolvePendingLevelUps();
                        _refresh();
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  compact
                      ? (hero == null ? 'Hero' : 'Act')
                      : (hero == null
                            ? 'Choose a hero'
                            : 'Act with ${hero.name}'),
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
                          useSkills: settings.autoUseSkills,
                          autoBuyHealingItems: settings.autoBuyHealingItems,
                          useHealingItems: settings.autoUseHealingItems,
                          levelUpMode: settings.levelUpMode,
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

  Widget _compactMerchantActions() {
    return Wrap(
      spacing: AppLayout.controlGap,
      runSpacing: AppLayout.controlGap,
      children: [
        FilledButton.icon(
          onPressed: _openMerchantPage,
          icon: const Icon(Icons.storefront),
          label: const Text('Open shop'),
        ),
        OutlinedButton.icon(
          onPressed: _continueAfterMerchant,
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip shop'),
        ),
      ],
    );
  }

  Widget _devToolsPanel({required bool compact}) {
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
              compact ? 'Dev' : 'Dev tools',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            OutlinedButton.icon(
              onPressed: () => update(battle.devAddGold),
              icon: const Icon(Icons.paid),
              label: Text(compact ? '+Gold' : '+9999 gold'),
            ),
            OutlinedButton.icon(
              onPressed: () => update(battle.devAddGems),
              icon: const Icon(Icons.diamond),
              label: Text(compact ? '+Gems' : '+999 gems'),
            ),
            OutlinedButton.icon(
              onPressed: _openDevEffectDialog,
              icon: const Icon(Icons.bolt),
              label: Text(compact ? 'Effect' : 'Apply effect'),
            ),
            OutlinedButton.icon(
              onPressed: battle.gameOver || battle.isAnimating
                  ? null
                  : _devOpenMerchant,
              icon: const Icon(Icons.storefront),
              label: Text(compact ? 'Shop' : 'Open merchant'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _devOpenMerchant() async {
    update(battle.devOpenMerchant);
    await _openMerchantPage();
  }

  Future<void> _openDevEffectDialog() async {
    final targets = battle.allFighters;
    if (targets.isEmpty) return;
    var selectedTarget = targets.first;
    var selectedEffect = _devEffectPresets.first;

    final applied = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Apply dev effect'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<_DevEffectPreset>(
                      value: selectedEffect,
                      decoration: const InputDecoration(labelText: 'Effect'),
                      items: _devEffectPresets
                          .map(
                            (effect) => DropdownMenuItem(
                              value: effect,
                              child: Text(effect.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedEffect = value);
                      },
                    ),
                    const SizedBox(height: AppLayout.sectionGap),
                    DropdownButtonFormField<Fighter>(
                      value: selectedTarget,
                      decoration: const InputDecoration(labelText: 'Target'),
                      items: targets
                          .map(
                            (fighter) => DropdownMenuItem(
                              value: fighter,
                              child: Text(
                                '${fighter.isHero ? 'Ally' : 'Enemy'} - ${fighter.name}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedTarget = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (applied != true) return;
    update(() => battle.devApplyEffect(selectedTarget, selectedEffect.build()));
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
        Text('H ${battle.heroes.alive.length}/${battle.heroes.members.length}'),
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

  Widget _merchantContent({VoidCallback? onChanged, VoidCallback? onContinue}) {
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
          onPressed: () => _buyTargetedSpecialBarUpgrade(onChanged: onChanged),
        ),
        const Divider(height: AppLayout.panelGap),
        OutlinedButton.icon(
          onPressed: onContinue ?? () => _continueAfterMerchant(),
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
                          _continueAfterMerchant();
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

  Future<void> _continueAfterMerchant() async {
    final shouldResumeAuto = battle.resumeAutoAttackAfterMerchant;
    update(() {
      if (settings.autoBuyHealingItems) {
        battle.autoBuyHealingItems();
      }
      battle.continueAfterMerchant();
    });
    if (!shouldResumeAuto || !mounted) return;
    await battle.performAutoAttack(
      pause: _mobAttackDelay,
      notify: _refresh,
      useSkills: settings.autoUseSkills,
      autoBuyHealingItems: settings.autoBuyHealingItems,
      useHealingItems: settings.autoUseHealingItems,
      levelUpMode: settings.levelUpMode,
    );
    await _resolvePendingLevelUps();
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
                  constraints.maxHeight - (safeRows - 1) * AppLayout.controlGap;
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
        showDevInfo: settings.devMode && !heroes,
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

final List<_DevEffectPreset> _devEffectPresets = [
  _DevEffectPreset(
    label: 'Protect (+10 defence, 3 turns)',
    name: 'Protect',
    kind: EffectKind.buff,
    duration: 3,
    defenceBonus: 10,
  ),
  _DevEffectPreset(
    label: 'Deep cut (5 damage, 5 turns)',
    name: 'Deep cut',
    kind: EffectKind.recurrent,
    duration: 5,
    damage: 5,
  ),
  _DevEffectPreset(
    label: 'Poison Arrow (2 damage, 5 turns)',
    name: 'Poison Arrow',
    kind: EffectKind.recurrent,
    duration: 5,
    damage: 2,
  ),
  _DevEffectPreset(
    label: 'Heavy poison (10 damage, 5 turns)',
    name: 'Heavy poison',
    kind: EffectKind.recurrent,
    duration: 5,
    damage: 10,
  ),
  _DevEffectPreset(
    label: 'Iron Skin (+25 defence, 5 turns)',
    name: 'Iron Skin',
    kind: EffectKind.buff,
    duration: 5,
    defenceBonus: 25,
  ),
];

class _DevEffectPreset {
  const _DevEffectPreset({
    required this.label,
    required this.name,
    required this.kind,
    required this.duration,
    this.damage = 0,
    this.defenceBonus = 0,
  });

  final String label;
  final String name;
  final EffectKind kind;
  final int duration;
  final double damage;
  final double defenceBonus;

  StatusEffect build() {
    return StatusEffect(
      name: name,
      kind: kind,
      duration: duration,
      damage: damage,
      defenceBonus: defenceBonus,
    );
  }
}
