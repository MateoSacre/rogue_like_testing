import 'dart:math';

import 'package:flutter/material.dart';

import '../data/creatures.dart';
import '../data/heroes.dart';
import '../game/game_balance.dart';
import '../game/game_screen.dart';
import '../l10n/app_localizations.dart';
import '../models/fighter.dart';
import '../persistence/save_service.dart';
import '../progression/player_progress.dart';
import '../progression/summon.dart';
import '../settings/game_settings.dart';
import '../settings/settings_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../utils/format.dart';
import '../widgets/rarity_stars.dart';
import '../widgets/summon_reveal.dart';

part 'hero_progress_tile.dart';
part 'header_line.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({
    required this.settings,
    required this.progress,
    required this.battleJson,
    required this.onSettingsChanged,
    required this.onProgressChanged,
    required this.onBattleSaved,
    required this.onResetProgress,
    super.key,
  });

  final GameSettings settings;
  final PlayerProgress progress;
  final Map<String, dynamic>? battleJson;
  final ValueChanged<GameSettings> onSettingsChanged;
  final ValueChanged<PlayerProgress> onProgressChanged;
  final ValueChanged<Map<String, dynamic>?> onBattleSaved;
  final Future<void> Function() onResetProgress;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final Set<String> selectedHeroes;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    selectedHeroes = _defaultSelection();
  }

  /// Up to [GameBalance.maxTeamSize] unlocked creatures, in catalog order — a
  /// launchable team that respects the run cap even when many are unlocked.
  Set<String> _defaultSelection() {
    return creatureCatalog
        .where((creature) => widget.progress.isUnlocked(creature.id))
        .take(GameBalance.maxTeamSize)
        .map((creature) => creature.id)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(K.appTitle)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppLayout.pagePadding),
              child: Center(
                child: Text(context.tr(K.gemsCount, [widget.progress.gems])),
              ),
            ),
            IconButton(
              tooltip: context.tr(K.settings),
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.play_arrow), text: context.tr(K.tabRun)),
              Tab(
                icon: const Icon(Icons.auto_awesome),
                text: context.tr(K.tabSummon),
              ),
            ],
          ),
        ),
        body: SafeArea(child: TabBarView(children: [_runTab(), _summonTab()])),
      ),
    );
  }

  Widget _runTab() {
    // Any unlocked creature (starters + summoned mobs) is playable.
    final unlocked = creatureCatalog
        .where((creature) => widget.progress.isUnlocked(creature.id))
        .map((creature) => creature.buildBase())
        .toList();
    return ListView(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      children: [
        _HeaderLine(
          icon: Icons.groups,
          title: context.tr(K.startTeamTitle),
          subtitle: widget.progress.hasUnlockedHero
              ? context.tr(K.heroesSelected, [
                  selectedHeroes.length,
                  GameBalance.maxTeamSize,
                ])
              : context.tr(K.chooseFirstHero),
        ),
        const SizedBox(height: AppLayout.sectionGap),
        if (!widget.progress.hasUnlockedHero)
          ...starterCreatures.map((c) => _starterHeroTile(c.buildBase()))
        else ...[
          Wrap(
            spacing: AppLayout.controlGap,
            runSpacing: AppLayout.controlGap,
            children: unlocked.map(_teamChoice).toList(),
          ),
          const SizedBox(height: AppLayout.panelGap),
          FilledButton.icon(
            onPressed: selectedHeroes.isEmpty ? null : _startNewRun,
            icon: const Icon(Icons.play_arrow),
            label: Text(context.tr(K.launchRun)),
          ),
          if (widget.battleJson != null) ...[
            const SizedBox(height: AppLayout.controlGap),
            OutlinedButton.icon(
              onPressed: _continueRun,
              icon: const Icon(Icons.history),
              label: Text(context.tr(K.continueSavedRun)),
            ),
          ],
        ],
      ],
    );
  }

  Widget _summonTab() {
    final children = <Widget>[
      _HeaderLine(
        icon: Icons.auto_awesome,
        title: context.tr(K.summonTitle),
        subtitle: context.tr(K.summonSubtitle, [
          GameBalance.summonCostSingle,
          GameBalance.summonCostTen,
        ]),
      ),
      const SizedBox(height: AppLayout.sectionGap),
    ];

    if (!widget.progress.hasUnlockedHero) {
      // The first summon is the free starter choice, done in the Run tab.
      children.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppLayout.cardPadding),
            child: Text(context.tr(K.summonFirstFree)),
          ),
        ),
      );
    } else {
      children
        ..add(
          Wrap(
            spacing: AppLayout.controlGap,
            runSpacing: AppLayout.controlGap,
            children: [
              FilledButton.icon(
                onPressed: widget.progress.canSummonSingle
                    ? () => _summon(1)
                    : null,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  context.tr(K.summonX1, [GameBalance.summonCostSingle]),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: widget.progress.canSummonTen
                    ? () => _summon(GameBalance.summonBatchSize)
                    : null,
                icon: const Icon(Icons.auto_awesome_motion),
                label: Text(
                  context.tr(K.summonX10, [GameBalance.summonCostTen]),
                ),
              ),
            ],
          ),
        )
        ..add(const SizedBox(height: AppLayout.sectionGap))
        ..add(
          _HeaderLine(
            icon: Icons.collections_bookmark,
            title: context.tr(K.collectionTitle),
          ),
        )
        ..add(const SizedBox(height: AppLayout.controlGap))
        ..addAll(_collectionTiles());
    }

    return ListView(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      children: children,
    );
  }

  List<Widget> _collectionTiles() {
    return creatureCatalog
        .where((creature) => widget.progress.isUnlocked(creature.id))
        .map(
          (creature) => InkWell(
            borderRadius: BorderRadius.circular(AppLayout.borderRadius),
            onTap: () => _showCreatureSheet(creature),
            child: _HeroProgressTile(
              hero: _heroWithProgress(creature.buildBase()),
              progress: widget.progress,
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        )
        .toList();
  }

  /// Detailed creature sheet (stats, skill) with the evolution action, opened
  /// from a collection tile.
  Future<void> _showCreatureSheet(CreatureDef def) {
    final fighter = _heroWithProgress(def.buildBase());
    final cost = widget.progress.evolutionCostOf(def.id);
    final skill = fighter.skill;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.creatureName(def.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              context.tr(K.level, [fighter.level]),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        content: SizedBox(
          width: AppLayout.dialogWidth(context, 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RarityStars(rarity: def.rarity, size: 18),
                  const SizedBox(width: AppLayout.compactGap),
                  Text(
                    context.l10n.creatureRarity(def.rarity),
                    style: TextStyle(
                      color: AppColors.creatureRarity(def.rarity),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.sectionGap),
              Text(context.tr(K.hp, [fmt(fighter.maxHp), fmt(fighter.maxHp)])),
              Text(
                context.tr(K.atkDef, [
                  fmt(fighter.attackPower),
                  fmt(fighter.baseDefence),
                ]),
              ),
              Text(
                context.tr(K.sheetCrit, [
                  (fighter.critChance * 100).round(),
                  fmt(GameBalance.criticalHitModifier),
                ]),
              ),
              if (skill != null) ...[
                const SizedBox(height: AppLayout.controlGap),
                Text(
                  context.tr(K.skillChargeLine, [
                    skill.name,
                    skill.description,
                    skill.charge,
                    skill.maxCharge,
                  ]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (cost != null)
            FilledButton.tonalIcon(
              onPressed: widget.progress.canEvolve(def.id)
                  ? () {
                      Navigator.of(context).pop();
                      _evolve(def.id);
                    }
                  : null,
              icon: const Icon(Icons.upgrade),
              label: Text(context.tr(K.evolveCost, [cost])),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr(K.close)),
          ),
        ],
      ),
    );
  }

  Future<void> _evolve(String id) async {
    String? newId;
    await _mutateProgress(
      clearBattle: false,
      action: () {
        newId = widget.progress.evolve(id);
        // Carry the team slot over to the evolved form.
        if (newId != null &&
            selectedHeroes.remove(id) &&
            selectedHeroes.length < GameBalance.maxTeamSize) {
          selectedHeroes.add(newId!);
        }
      },
    );
    if (newId != null && mounted) {
      await _showEvolution(id, newId!);
    }
  }

  Future<void> _showEvolution(String fromId, String toId) {
    final rarity = creatureById(toId)?.rarity;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(K.evolveTitle)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rarity != null) ...[
              RarityStars(rarity: rarity, size: 20),
              const SizedBox(height: AppLayout.controlGap),
            ],
            Text(
              context.tr(K.evolveResult, [
                context.l10n.creatureName(fromId),
                context.l10n.creatureName(toId),
              ]),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr(K.close)),
          ),
        ],
      ),
    );
  }

  Future<void> _summon(int count) async {
    var results = const <SummonResult>[];
    await _mutateProgress(
      clearBattle: false,
      action: () {
        results = count == 1
            ? [?widget.progress.summonSingle(_random)]
            : widget.progress.summonTen(_random);
      },
    );
    if (results.isNotEmpty && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => SummonRevealDialog(results: results),
      );
    }
  }

  Widget _starterHeroTile(Fighter hero) {
    return _HeroProgressTile(
      hero: hero,
      progress: widget.progress,
      trailing: FilledButton.icon(
        onPressed: () => _mutateProgress(
          clearBattle: false,
          action: () {
            widget.progress.claimStarterHero(hero.name);
            selectedHeroes
              ..clear()
              ..add(hero.name);
          },
        ),
        icon: const Icon(Icons.flag),
        label: Text(context.tr(K.choose)),
      ),
    );
  }

  Widget _teamChoice(Fighter hero) {
    final selected = selectedHeroes.contains(hero.name);
    final level = widget.progress.levelFor(hero.name);
    final atCap = selectedHeroes.length >= GameBalance.maxTeamSize;
    return FilterChip(
      selected: selected,
      avatar: Icon(selected ? Icons.check : Icons.person),
      label: Text(
        context.tr(K.heroNameLevel, [
          context.l10n.creatureName(hero.name),
          level,
        ]),
      ),
      // Unselected chips are disabled once the run team is full.
      onSelected: (!selected && atCap)
          ? null
          : (value) {
              setState(() {
                if (value) {
                  selectedHeroes.add(hero.name);
                } else {
                  selectedHeroes.remove(hero.name);
                }
              });
            },
    );
  }

  Future<void> _startNewRun() async {
    final team = _selectedTeam();
    widget.onBattleSaved(null);
    await SaveService.save(
      settings: widget.settings,
      progress: widget.progress,
    );
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return GameScreen(
            settings: widget.settings,
            progress: widget.progress,
            initialHeroes: team,
            onSettingsChanged: widget.onSettingsChanged,
            onProgressChanged: widget.onProgressChanged,
            onBattleSaved: widget.onBattleSaved,
            onResetProgress: widget.onResetProgress,
          );
        },
      ),
    );
    setState(() {});
  }

  Future<void> _continueRun() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return GameScreen(
            settings: widget.settings,
            progress: widget.progress,
            initialHeroes: _selectedTeam(),
            initialBattleJson: widget.battleJson,
            onSettingsChanged: widget.onSettingsChanged,
            onProgressChanged: widget.onProgressChanged,
            onBattleSaved: widget.onBattleSaved,
            onResetProgress: widget.onResetProgress,
          );
        },
      ),
    );
    setState(() {});
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return SettingsScreen(
            settings: widget.settings,
            onChanged: (settings) {
              widget.onSettingsChanged(settings);
              SaveService.save(settings: settings, progress: widget.progress);
            },
            onResetProgress: widget.onResetProgress,
          );
        },
      ),
    );
    selectedHeroes
      ..clear()
      ..addAll(_defaultSelection());
    if (mounted) setState(() {});
  }

  List<Fighter> _selectedTeam() {
    return buildTeamFromProgress(
      selectedHeroNames: selectedHeroes,
      levelFor: widget.progress.levelFor,
      xpFor: widget.progress.xpFor,
    );
  }

  Fighter _heroWithProgress(Fighter hero) {
    return heroAtLevel(
      hero,
      widget.progress.levelFor(hero.name),
      xp: widget.progress.xpFor(hero.name),
    );
  }

  Future<void> _mutateProgress({
    required VoidCallback action,
    required bool clearBattle,
  }) async {
    setState(action);
    widget.onProgressChanged(widget.progress);
    if (clearBattle) {
      widget.onBattleSaved(null);
    }
    await SaveService.save(
      settings: widget.settings,
      progress: widget.progress,
      battleJson: clearBattle ? null : widget.battleJson,
    );
  }
}
