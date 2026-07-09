import 'package:flutter/material.dart';

import '../data/creatures.dart';
import '../game/game_balance.dart';
import '../l10n/app_localizations.dart';
import '../progression/player_progress.dart';
import '../theme/app_layout.dart';
import '../widgets/creature_tile.dart';

/// Full-screen roster editor for one team preset: a square-tile grid of every
/// unlocked creature. Tapping a tile toggles it in team slot [teamIndex] —
/// selects it if not already in the roster, deselects it if it is, and does
/// nothing once the roster is already at [GameBalance.maxTeamSize].
class TeamEditorScreen extends StatefulWidget {
  const TeamEditorScreen({
    required this.progress,
    required this.teamIndex,
    required this.onChanged,
    super.key,
  });

  final PlayerProgress progress;
  final int teamIndex;

  /// Called after every toggle so the caller can persist [progress] — it is
  /// mutated in place, so this screen and the start screen share one instance.
  final Future<void> Function() onChanged;

  @override
  State<TeamEditorScreen> createState() => _TeamEditorScreenState();
}

class _TeamEditorScreenState extends State<TeamEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final roster = widget.progress.teamRoster(widget.teamIndex);
    final tiles = creatureCatalog
        .where((creature) => widget.progress.isUnlocked(creature.id))
        .map((creature) {
          final name = context.l10n.creatureName(creature.id);
          return SizedBox(
            width: AppLayout.creatureTileSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CreatureTile(
                  name: name,
                  rarity: creature.rarity,
                  imageAsset: creature.portraitAsset,
                  selected: widget.progress.isInTeam(
                    widget.teamIndex,
                    creature.id,
                  ),
                  onTap: () => _toggle(creature.id),
                ),
                const SizedBox(height: AppLayout.tinyGap),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          );
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(K.teamSlotLabel, [widget.teamIndex + 1])),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppLayout.controlGap),
            child: Text(
              context.tr(K.heroesSelected, [
                roster.length,
                GameBalance.maxTeamSize,
              ]),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.pagePadding),
          children: [
            Wrap(
              spacing: AppLayout.controlGap,
              runSpacing: AppLayout.controlGap,
              children: tiles,
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String heroId) {
    setState(() => widget.progress.toggleInTeam(widget.teamIndex, heroId));
    widget.onChanged();
  }
}
