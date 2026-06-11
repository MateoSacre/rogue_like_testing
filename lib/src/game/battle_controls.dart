part of 'game_screen.dart';

/// The central control panel: optional summary, dev tools, then the
/// context-sensitive body — game-over restart, merchant actions, or the
/// hero action controls (attack/skill, target chips, act/auto buttons).
class _BattleControls extends StatelessWidget {
  const _BattleControls({
    required this.state,
    required this.showSummary,
    this.compact = false,
  });

  final _GameScreenState state;
  final bool showSummary;
  final bool compact;

  BattleController get battle => state.battle;

  @override
  Widget build(BuildContext context) {
    final hero = battle.selectedHero;
    final skill = hero?.skill;
    final targets = battle.targetsForSelectedAction();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSummary) ...[
          _BattleSummary(state: state, compact: compact),
          SizedBox(
            height: compact ? AppLayout.compactGap : AppLayout.sectionGap,
          ),
        ],
        if (state.settings.devMode) ...[
          _DevToolsPanel(state: state, compact: compact),
          SizedBox(
            height: compact ? AppLayout.compactGap : AppLayout.sectionGap,
          ),
        ],
        if (battle.gameOver)
          FilledButton.icon(
            onPressed: () => state._restartRun(
              resumeAutoAttack: battle.autoAttackWasEnabledOnGameOver,
            ),
            icon: const Icon(Icons.restart_alt),
            label: Text(context.tr(K.restartRun)),
          )
        else if (battle.merchantAvailable)
          compact
              ? _compactMerchantActions(context)
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppLayout.cardPadding),
                    child: _MerchantView(state: state),
                  ),
                )
        else ...[
          Text(
            context.tr(K.heroAction),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppLayout.controlGap),
          SegmentedButton<ActionMode>(
            segments: [
              ButtonSegment(
                value: ActionMode.attack,
                icon: const Icon(Icons.gps_fixed),
                label: Text(context.tr(K.attack)),
              ),
              ButtonSegment(
                value: ActionMode.skill,
                enabled: skill?.isReady == true,
                icon: const Icon(Icons.auto_awesome),
                label: Text(skill == null ? context.tr(K.skill) : skill.name),
              ),
            ],
            selected: {battle.actionMode},
            onSelectionChanged: battle.isAnimating || battle.autoAttackEnabled
                ? null
                : (selection) =>
                      state.update(() => battle.setAction(selection.first)),
          ),
          SizedBox(
            height: compact ? AppLayout.compactGap : AppLayout.controlGap,
          ),
          if (skill != null && !compact)
            Text(
              context.tr(K.skillChargeLine, [
                skill.name,
                skill.description,
                skill.charge,
                skill.maxCharge,
              ]),
            ),
          if (!compact) ...[
            const SizedBox(height: AppLayout.sectionGap),
            Wrap(
              spacing: AppLayout.controlGap,
              runSpacing: AppLayout.controlGap,
              children: targets.map((target) {
                return ChoiceChip(
                  selected: battle.selectedTarget == target,
                  label: _TargetPreviewLabel(
                    name: target.name,
                    preview: battle.previewForTarget(target),
                  ),
                  onSelected: battle.isAnimating || battle.autoAttackEnabled
                      ? null
                      : (_) =>
                            state.update(() => battle.selectedTarget = target),
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
                onPressed: battle.canAct ? state._actWithSelectedHero : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  compact
                      ? (hero == null
                            ? context.tr(K.heroShort)
                            : context.tr(K.actShort))
                      : (hero == null
                            ? context.tr(K.chooseHero)
                            : context.tr(K.actWith, [hero.name])),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    battle.gameOver ||
                        (battle.isAnimating && !battle.autoAttackEnabled)
                    ? null
                    : state._toggleAutoAttack,
                icon: Icon(
                  battle.autoAttackEnabled
                      ? Icons.pause_circle
                      : Icons.flash_auto,
                ),
                label: Text(
                  compact
                      ? (battle.autoAttackEnabled
                            ? context.tr(K.autoOnShort)
                            : context.tr(K.autoShort))
                      : (battle.autoAttackEnabled
                            ? context.tr(K.autoOn)
                            : context.tr(K.autoOff)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _compactMerchantActions(BuildContext context) {
    return Wrap(
      spacing: AppLayout.controlGap,
      runSpacing: AppLayout.controlGap,
      children: [
        FilledButton.icon(
          onPressed: state._openMerchantPage,
          icon: const Icon(Icons.storefront),
          label: Text(context.tr(K.openShop)),
        ),
        OutlinedButton.icon(
          onPressed: state._continueAfterMerchant,
          icon: const Icon(Icons.skip_next),
          label: Text(context.tr(K.skipShop)),
        ),
      ],
    );
  }
}
