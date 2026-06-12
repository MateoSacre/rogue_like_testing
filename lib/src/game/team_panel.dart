part of 'game_screen.dart';

/// Renders one team (heroes or enemies) as a grid of [FighterCard]s, in either
/// the wide or compact layout. Reads selection/turn state from the controller
/// and routes taps back through the screen's [_GameScreenState.update].
class _TeamPanel extends StatelessWidget {
  const _TeamPanel({
    required this.state,
    required this.team,
    required this.isHeroes,
    required this.compact,
  });

  final _GameScreenState state;
  final Team team;
  final bool isHeroes;
  final bool compact;

  BattleController get battle => state.battle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(isHeroes ? K.heroesPanel : K.enemiesPanel),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppLayout.controlGap),
        Expanded(child: compact ? _compactGrid() : _grid()),
      ],
    );
  }

  Widget _grid() {
    return GridView(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppLayout.fighterCardMaxWidth,
        mainAxisExtent: isHeroes
            ? AppLayout.heroCardHeight
            : AppLayout.enemyCardHeight,
        crossAxisSpacing: AppLayout.controlGap,
        mainAxisSpacing: AppLayout.controlGap,
      ),
      children: _cards(),
    );
  }

  Widget _compactGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columns();
        final rows = (team.members.length / columns).ceil();
        final safeRows = rows == 0 ? 1 : rows;
        final preferredHeight = isHeroes
            ? AppLayout.compactHeroCardHeight
            : AppLayout.compactEnemyCardHeight;
        final availableHeight =
            constraints.maxHeight - (safeRows - 1) * AppLayout.controlGap;
        final cardHeight = (availableHeight / safeRows)
            .clamp(isHeroes ? 68.0 : 54.0, preferredHeight)
            .toDouble();

        return GridView(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: cardHeight,
            crossAxisSpacing: AppLayout.controlGap,
            mainAxisSpacing: AppLayout.controlGap,
          ),
          children: _cards(),
        );
      },
    );
  }

  int _columns() {
    final size = team.members.length;
    if (size <= 0) return 1;
    if (size <= 3) return 1;
    return 2;
  }

  List<Widget> _cards() {
    return team.members.map((fighter) {
      final canPickHero =
          isHeroes &&
          !battle.autoAttackEnabled &&
          !battle.merchantAvailable &&
          fighter.isAlive &&
          battle.availableHeroes.contains(fighter);
      final hasActed =
          isHeroes && fighter.isAlive && battle.actedHeroes.contains(fighter);
      final selected =
          battle.selectedHero == fighter ||
          battle.activeMob == fighter ||
          battle.activeMobTarget == fighter ||
          battle.selectedTarget == fighter;
      final canToggleTarget = !isHeroes && battle.canToggleEnemyTarget(fighter);
      final canSelect =
          canPickHero && !battle.isAnimating && !battle.autoAttackEnabled;
      // Tap priority: select / toggle target when available; tapping the
      // already-selected hero (or a card with no gameplay action — see the
      // onTap fallback in FighterCard) opens the character sheet instead.
      return FighterCard(
        fighter: fighter,
        selected: selected,
        pickable: canPickHero,
        acted: hasActed,
        compact: compact,
        showDevInfo: state.settings.devMode && !isHeroes,
        onTap: canSelect && battle.selectedHero != fighter
            ? () => state.update(() => battle.selectHero(fighter))
            : canToggleTarget
            ? () => state.update(() => battle.toggleEnemyTarget(fighter))
            : null,
        onInfo: () => state._openCharacterSheet(fighter),
      );
    }).toList();
  }
}
