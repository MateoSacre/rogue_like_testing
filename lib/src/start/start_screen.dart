import 'package:flutter/material.dart';

import '../data/heroes.dart';
import '../game/game_screen.dart';
import '../models/fighter.dart';
import '../models/level_up_stat.dart';
import '../persistence/save_service.dart';
import '../progression/hero_stat_points.dart';
import '../progression/player_progress.dart';
import '../settings/game_settings.dart';
import '../settings/settings_screen.dart';
import '../theme/app_layout.dart';
import '../utils/format.dart';

part 'hero_progress_tile.dart';
part 'header_line.dart';
part 'stat_allocation_dialog.dart';
part 'stat_helpers.dart';

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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RogueLite'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppLayout.pagePadding),
              child: Center(child: Text('Gemmes: ${widget.progress.gems}')),
            ),
            IconButton(
              tooltip: 'Reglages',
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.play_arrow), text: 'Run'),
              Tab(icon: Icon(Icons.storefront), text: 'Heros'),
              Tab(icon: Icon(Icons.upgrade), text: 'Niveaux'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(children: [_runTab(), _shopTab(), _upgradeTab()]),
        ),
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
          title: 'Equipe de depart',
          subtitle: widget.progress.hasUnlockedHero
              ? '${selectedHeroes.length}/${unlocked.length} heros selectionnes'
              : 'Choisis ton premier hero gratuitement',
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
            label: const Text('Lancer une run'),
          ),
          if (widget.battleJson != null) ...[
            const SizedBox(height: AppLayout.controlGap),
            OutlinedButton.icon(
              onPressed: _continueRun,
              icon: const Icon(Icons.history),
              label: const Text('Continuer la run sauvegardee'),
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
          title: 'Acheter des heros',
          subtitle: '${PlayerProgress.heroCost} gemmes par hero',
        ),
        const SizedBox(height: AppLayout.sectionGap),
        ...buildHeroRoster().map((hero) {
          final unlocked = widget.progress.isUnlocked(hero.name);
          final progressHero = unlocked ? _heroWithProgress(hero) : hero;
          return _HeroProgressTile(
            hero: progressHero,
            progress: widget.progress,
            trailing: Wrap(
              spacing: AppLayout.tinyGap,
              runSpacing: AppLayout.tinyGap,
              children: [
                FilledButton.tonalIcon(
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
                    unlocked ? 'Debloque' : '${PlayerProgress.heroCost}',
                  ),
                ),
                if (unlocked)
                  OutlinedButton.icon(
                    onPressed: () => _openStatAllocationDialog(hero),
                    icon: const Icon(Icons.tune),
                    label: const Text('Stats'),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _upgradeTab() {
    final unlocked = buildHeroRoster()
        .where((hero) => widget.progress.isUnlocked(hero.name))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      children: [
        _HeaderLine(
          icon: Icons.trending_up,
          title: 'Ameliorer les heros',
          subtitle:
              '${PlayerProgress.heroLevelCost} gemmes par point, max niveau ${PlayerProgress.maxPermanentHeroLevel}',
        ),
        const SizedBox(height: AppLayout.sectionGap),
        if (unlocked.isEmpty)
          const Text('Debloque d abord un hero pour l ameliorer.')
        else
          ...unlocked.map((hero) {
            final level = widget.progress.levelFor(hero.name);
            return _HeroProgressTile(
              hero: _heroWithProgress(hero),
              progress: widget.progress,
              trailing: Wrap(
                spacing: AppLayout.tinyGap,
                runSpacing: AppLayout.tinyGap,
                children: LevelUpStat.values.map((stat) {
                  return FilledButton.tonalIcon(
                    onPressed: widget.progress.canUpgradeHero(hero.name, stat)
                        ? () => _mutateProgress(
                            clearBattle: true,
                            action: () =>
                                widget.progress.upgradeHero(hero.name, stat),
                          )
                        : null,
                    icon: const Icon(Icons.add),
                    label: Text(
                      level >= PlayerProgress.maxPermanentHeroLevel
                          ? 'Max'
                          : '${_shortStat(stat)} ${PlayerProgress.heroLevelCost}',
                    ),
                  );
                }).toList(),
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
        label: const Text('Choisir'),
      ),
    );
  }

  Widget _teamChoice(Fighter hero) {
    final selected = selectedHeroes.contains(hero.name);
    final level = widget.progress.levelFor(hero.name);
    return FilterChip(
      selected: selected,
      avatar: Icon(selected ? Icons.check : Icons.person),
      label: Text('${hero.name} Lv $level'),
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
      statPointsFor: (heroName, stat) =>
          widget.progress.statPointsFor(heroName).valueFor(stat),
    );
  }

  Fighter _heroWithProgress(Fighter hero) {
    final stats = widget.progress.statPointsFor(hero.name);
    return heroWithPermanentStats(
      hero,
      widget.progress.levelFor(hero.name),
      (stat) => stats.valueFor(stat),
    );
  }

  Future<void> _openStatAllocationDialog(Fighter hero) async {
    final total = widget.progress.statPointsFor(hero.name).total;
    final nextStats = await showDialog<HeroStatPoints>(
      context: context,
      builder: (context) {
        return _StatAllocationDialog(
          hero: hero,
          initialStats: widget.progress.statPointsFor(hero.name),
        );
      },
    );
    if (nextStats == null || nextStats.total != total) return;
    await _mutateProgress(
      clearBattle: true,
      action: () => widget.progress.reallocateHeroStats(hero.name, nextStats),
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
