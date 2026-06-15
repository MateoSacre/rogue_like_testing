import 'package:flutter/material.dart';

import '../data/heroes.dart';
import '../game/game_balance.dart';
import '../game/game_screen.dart';
import '../l10n/app_localizations.dart';
import '../models/fighter.dart';
import '../persistence/save_service.dart';
import '../progression/player_progress.dart';
import '../settings/game_settings.dart';
import '../settings/settings_screen.dart';
import '../theme/app_layout.dart';
import '../utils/format.dart';

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

  @override
  void initState() {
    super.initState();
    selectedHeroes = {...widget.progress.unlockedHeroes};
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
                icon: const Icon(Icons.storefront),
                text: context.tr(K.tabHeroes),
              ),
            ],
          ),
        ),
        body: SafeArea(child: TabBarView(children: [_runTab(), _shopTab()])),
      ),
    );
  }

  Widget _runTab() {
    final unlocked = buildHeroRoster()
        .where((hero) => widget.progress.isUnlocked(hero.name))
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
                  unlocked.length,
                ])
              : context.tr(K.chooseFirstHero),
        ),
        const SizedBox(height: AppLayout.sectionGap),
        if (!widget.progress.hasUnlockedHero)
          ...buildHeroRoster().map(_starterHeroTile)
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

  Widget _shopTab() {
    return ListView(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      children: [
        _HeaderLine(
          icon: Icons.diamond,
          title: context.tr(K.buyHeroesTitle),
          subtitle: context.tr(K.gemsPerHero, [PlayerProgress.heroCost]),
        ),
        const SizedBox(height: AppLayout.sectionGap),
        ...buildHeroRoster().map((hero) {
          final unlocked = widget.progress.isUnlocked(hero.name);
          final progressHero = unlocked ? _heroWithProgress(hero) : hero;
          return _HeroProgressTile(
            hero: progressHero,
            progress: widget.progress,
            trailing: FilledButton.tonalIcon(
              onPressed: unlocked || !widget.progress.canBuyHero(hero.name)
                  ? null
                  : () => _mutateProgress(
                      clearBattle: true,
                      action: () {
                        widget.progress.buyHero(hero.name);
                        selectedHeroes.add(hero.name);
                      },
                    ),
              icon: Icon(unlocked ? Icons.check : Icons.shopping_bag),
              label: Text(
                unlocked ? context.tr(K.unlocked) : '${PlayerProgress.heroCost}',
              ),
            ),
          );
        }),
      ],
    );
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
    return FilterChip(
      selected: selected,
      avatar: Icon(selected ? Icons.check : Icons.person),
      label: Text(context.tr(K.heroNameLevel, [hero.name, level])),
      onSelected: (value) {
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
      ..addAll(widget.progress.unlockedHeroes);
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
