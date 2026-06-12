import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/items.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/fighter.dart';
import '../models/item.dart';
import '../models/level_up_stat.dart';
import '../models/skill_preview.dart';
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

part 'battle_controls.dart';
part 'battle_summary.dart';
part 'boss_warning.dart';
part 'character_sheet_dialog.dart';
part 'dev_tools_panel.dart';
part 'inventory_widgets.dart';
part 'item_drop_dialog.dart';
part 'level_up_dialog.dart';
part 'merchant_action.dart';
part 'merchant_view.dart';
part 'target_preview_label.dart';
part 'team_panel.dart';

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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final BattleController battle;
  late GameSettings settings;
  bool _resumeAutoAttackAfterRestart = false;
  final ScrollController _heroesScrollController = ScrollController();
  final ScrollController _centerScrollController = ScrollController();
  final ScrollController _enemiesScrollController = ScrollController();

  // Saving is throttled (leading edge + trailing): during auto-attack the
  // `notify` callback fires many times per second, and saving on every call
  // would serialize the whole battle to JSON and hit the disk dozens of
  // times a second. We coalesce those into at most one save per window, and
  // flush immediately at critical moments (game over, dispose, app pause).
  static const _saveThrottle = Duration(milliseconds: 500);
  Timer? _saveTimer;
  bool _saveQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    // Persist the latest state to disk, but WITHOUT the parent callbacks:
    // calling setState on an ancestor while this route unmounts would throw.
    _saveTimer?.cancel();
    _saveTimer = null;
    _saveQueued = false;
    _saveToDiskOnly();
    _heroesScrollController.dispose();
    _centerScrollController.dispose();
    _enemiesScrollController.dispose();
    super.dispose();
  }

  void _saveToDiskOnly() {
    // Shared-reference mutation is safe; the parent is not notified here.
    widget.progress.gems = battle.gems;
    SaveService.save(
      settings: settings,
      progress: widget.progress,
      battleJson: battle.toJson(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _flushSaveNow();
    }
  }

  /// Requests a save, throttled to at most one per [_saveThrottle].
  /// Leading edge: the first request in a quiet period saves immediately;
  /// further requests within the window are coalesced into one trailing save.
  void _scheduleSave() {
    if (_saveTimer != null) {
      _saveQueued = true;
      return;
    }
    saveGame();
    _saveTimer = Timer(_saveThrottle, _onSaveCooldownEnd);
  }

  void _onSaveCooldownEnd() {
    _saveTimer = null;
    if (_saveQueued) {
      _saveQueued = false;
      _scheduleSave();
    }
  }

  /// Cancels any pending throttled save and saves the current state now.
  void _flushSaveNow() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _saveQueued = false;
    saveGame();
  }

  void update(void Function() action) {
    setState(action);
    _scheduleSave();
  }

  Future<void> _mobAttackDelay() {
    return Future<void>.delayed(settings.autoAttackSpeed.duration);
  }

  void _refresh() {
    _autoRestartAfterDefeat();
    if (mounted) setState(() {});
    // Game over is a rare, important transition — persist it right away.
    if (battle.gameOver) {
      _flushSaveNow();
    } else {
      _scheduleSave();
    }
    _resumeRestartedAutoAttackIfReady();
  }

  void _autoRestartAfterDefeat() {
    if (!settings.devMode ||
        !settings.devAutoRestartOnDefeat ||
        !battle.gameOver) {
      return;
    }
    final earnedGems = battle.gems;
    _resumeAutoAttackAfterRestart = battle.autoAttackWasEnabledOnGameOver;
    battle.resetGame(heroes: widget.initialHeroes, gems: earnedGems);
    battle.devMode = settings.devMode;
  }

  void _resumeRestartedAutoAttackIfReady() {
    if (!_resumeAutoAttackAfterRestart || battle.isAutoAttackRunning) return;
    _resumeAutoAttackAfterRestart = false;
    Future<void>.microtask(_runAutoAttack);
  }

  Future<void> _restartRun({required bool resumeAutoAttack}) async {
    update(() {
      _resumeAutoAttackAfterRestart = resumeAutoAttack;
      battle.stopAutoAttack();
      battle.resetGame(
        heroes: widget.initialHeroes,
        gems: widget.progress.gems,
      );
      battle.devMode = settings.devMode;
    });
    _resumeRestartedAutoAttackIfReady();
  }

  Future<void> _runAutoAttack() async {
    if (!mounted || battle.gameOver) return;
    if (!battle.autoAttackEnabled) {
      update(() => battle.autoAttackEnabled = true);
    }
    await battle.performAutoAttack(
      pause: _mobAttackDelay,
      notify: _refresh,
      useSkills: settings.autoUseSkills,
      autoBuyHealingItems: settings.autoBuyHealingItems,
      useHealingItems: settings.autoUseHealingItems,
      levelUpMode: settings.levelUpMode,
    );
    await _resolvePendingLevelUps();
    await _resolvePendingItemDrops();
    _refresh();
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
          context.tr(K.waveTitle, [
            battle.waveCounter,
            context.l10n.mobCategory(battle.waveInfo.category),
          ]),
        ),
        actions: [
          IconButton(
            tooltip: context.tr(K.restart),
            onPressed: () =>
                _restartRun(resumeAutoAttack: battle.autoAttackEnabled),
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            tooltip: context.tr(K.settings),
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
              Expanded(
                child: _TeamPanel(
                  state: this,
                  team: battle.heroes,
                  isHeroes: true,
                  compact: false,
                ),
              ),
              const SizedBox(width: AppLayout.panelGap),
              Expanded(
                child: _TeamPanel(
                  state: this,
                  team: battle.mobs,
                  isHeroes: false,
                  compact: false,
                ),
              ),
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
          child: _TeamPanel(
            state: this,
            team: battle.mobs,
            isHeroes: false,
            compact: true,
          ),
        ),
        const SizedBox(height: AppLayout.controlGap),
        Expanded(flex: 28, child: _centerPanel()),
        const SizedBox(height: AppLayout.controlGap),
        Expanded(
          flex: 36,
          child: _TeamPanel(
            state: this,
            team: battle.heroes,
            isHeroes: true,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _centerPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: _BattleControls(state: this, showSummary: true, compact: true),
          ),
        );
      },
    );
  }

  Widget _topPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.summaryPadding),
        child: _BattleControls(state: this, showSummary: true),
      ),
    );
  }

  Future<void> _actWithSelectedHero() async {
    await battle.performSelectedAction(
      pause: _mobAttackDelay,
      notify: _refresh,
      levelUpMode: settings.levelUpMode,
    );
    await _resolvePendingLevelUps();
    await _resolvePendingItemDrops();
    _refresh();
  }

  Future<void> _toggleAutoAttack() async {
    if (battle.autoAttackEnabled) {
      update(battle.stopAutoAttack);
      return;
    }
    await _runAutoAttack();
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
              title: Text(context.tr(K.applyDevEffect)),
              content: SizedBox(
                width: AppLayout.dialogWidth(context, 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<_DevEffectPreset>(
                      initialValue: selectedEffect,
                      decoration: InputDecoration(
                        labelText: context.tr(K.effectLabel),
                      ),
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
                      initialValue: selectedTarget,
                      decoration: InputDecoration(
                        labelText: context.tr(K.targetLabel),
                      ),
                      items: targets
                          .map(
                            (fighter) => DropdownMenuItem(
                              value: fighter,
                              child: Text(
                                context.tr(K.targetOption, [
                                  fighter.isHero
                                      ? context.tr(K.ally)
                                      : context.tr(K.enemy),
                                  fighter.name,
                                ]),
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
                  child: Text(context.tr(K.cancel)),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check),
                  label: Text(context.tr(K.apply)),
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

  Future<void> _resolvePendingItemDrops() async {
    while (mounted && battle.pendingItemDrops.isNotEmpty) {
      final pending = battle.pendingItemDrops.first;
      if (battle.gameOver) {
        // Run is over: items are per-run, silently sell what's left.
        update(() => battle.resolvePendingItemDrop(pending));
        continue;
      }
      final choice = await showDialog<_ItemDropChoice>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return _ItemDropDialog(def: pending.def, heroes: battle.heroes.alive);
        },
      );
      if (choice == null) return;
      update(() => battle.resolvePendingItemDrop(pending, hero: choice.hero));
    }
  }

  Future<void> _openMerchantPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setPageState) {
              return Scaffold(
                appBar: AppBar(title: Text(context.tr(K.merchant))),
                body: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(AppLayout.pagePadding),
                    children: [
                      _MerchantView(
                        state: this,
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
    await _resolvePendingItemDrops();
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
      title: context.tr(K.potionHealing),
      heroes: battle.heroes.alive.where((hero) => hero.hp < hero.maxHp),
      subtitleFor: (hero) =>
          context.tr(K.hp, [fmt(hero.hp), fmt(hero.maxHp)]),
    );
    if (hero == null) return;
    update(() => battle.buySinglePotion(hero));
    onChanged?.call();
  }

  Future<void> _buyTargetedSpecialPotion({VoidCallback? onChanged}) async {
    final hero = await _pickHero(
      title: context.tr(K.potionSpecial),
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
      title: context.tr(K.specialBarUpgrade),
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
                                context.tr(K.level, [hero.level]),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              context.tr(K.xpValue, [hero.xp, hero.xpCap]),
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

  Future<void> _openInventory() {
    return showDialog<void>(
      context: context,
      builder: (_) => _InventoryDialog(state: this),
    );
  }

  Future<void> _openCharacterSheet(Fighter fighter) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CharacterSheetDialog(fighter: fighter),
    );
  }

  List<_InventoryItem> _inventoryItems() {
    return [
      _InventoryItem(
        kind: _InventoryItemKind.healing,
        icon: Icons.healing,
        label: context.tr(K.invHealing),
        count: battle.healingPotionStock,
      ),
      _InventoryItem(
        kind: _InventoryItemKind.team,
        icon: Icons.groups,
        label: context.tr(K.invTeam),
        count: battle.teamPotionStock,
      ),
      _InventoryItem(
        kind: _InventoryItemKind.special,
        icon: Icons.auto_awesome,
        label: context.tr(K.invSpecial),
        count: battle.specialPotionStock,
      ),
    ];
  }

  bool _useInventoryItem(_InventoryItemKind kind, Fighter hero) {
    // The controller methods own all the validation (stock, HP, charge,
    // alive…) and report whether the item was actually consumed, so the UI
    // just acts on the result instead of re-checking the same conditions.
    final used = switch (kind) {
      _InventoryItemKind.healing => battle.useHealingPotion(hero),
      _InventoryItemKind.team => battle.useTeamPotion(),
      _InventoryItemKind.special => battle.useSpecialPotion(hero),
    };
    if (used) {
      setState(() {});
      _scheduleSave();
    }
    return used;
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
