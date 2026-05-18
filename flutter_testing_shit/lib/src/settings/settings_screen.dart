import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import 'game_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.onChanged,
    this.onResetProgress,
    super.key,
  });

  final GameSettings settings;
  final ValueChanged<GameSettings> onChanged;
  final Future<void> Function()? onResetProgress;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings settings;
  late final TextEditingController seedController;

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
    seedController = TextEditingController(text: settings.seedString);
  }

  @override
  void dispose() {
    seedController.dispose();
    super.dispose();
  }

  void update(GameSettings value) {
    setState(() => settings = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reglages')),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.pagePadding),
        children: [
          SwitchListTile(
            title: const Text('Theme sombre'),
            value: settings.darkTheme,
            onChanged: (value) => update(settings.copyWith(darkTheme: value)),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          Text(
            'Vitesse attaque auto',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppLayout.controlGap),
          SegmentedButton<AutoAttackSpeed>(
            segments: AutoAttackSpeed.values
                .map(
                  (speed) =>
                      ButtonSegment(value: speed, label: Text(speed.label)),
                )
                .toList(),
            selected: {settings.autoAttackSpeed},
            onSelectionChanged: (selection) {
              update(settings.copyWith(autoAttackSpeed: selection.first));
            },
          ),
          const SizedBox(height: AppLayout.sectionGap),
          SwitchListTile(
            title: const Text('Competences en auto'),
            subtitle: const Text(
              'Les heros utilisent leurs capacites quand elles sont pretes.',
            ),
            value: settings.autoUseSkills,
            onChanged: (value) =>
                update(settings.copyWith(autoUseSkills: value)),
          ),
          SwitchListTile(
            title: const Text('Achat auto soins'),
            subtitle: const Text(
              'Le marchand stocke des soins avec l or disponible.',
            ),
            value: settings.autoBuyHealingItems,
            onChanged: (value) =>
                update(settings.copyWith(autoBuyHealingItems: value)),
          ),
          SwitchListTile(
            title: const Text('Soins auto'),
            subtitle: const Text(
              'Les potions stockees sont utilisees a 25% PV ou moins.',
            ),
            value: settings.autoUseHealingItems,
            onChanged: (value) =>
                update(settings.copyWith(autoUseHealingItems: value)),
          ),
          SwitchListTile(
            title: const Text('Dev mode'),
            subtitle: const Text(
              'Affiche progressivement des informations de debug.',
            ),
            value: settings.devMode,
            onChanged: (value) => update(settings.copyWith(devMode: value)),
          ),
          if (settings.devMode) ...[
            const SizedBox(height: AppLayout.controlGap),
            TextField(
              controller: seedController,
              decoration: const InputDecoration(
                labelText: 'Seed',
                hintText: 'ex: test-build-1',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                update(settings.copyWith(seedString: value));
              },
            ),
          ],
          const SizedBox(height: AppLayout.sectionGap),
          Text('Level-up', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppLayout.controlGap),
          SegmentedButton<LevelUpMode>(
            segments: LevelUpMode.values
                .map(
                  (mode) => ButtonSegment(value: mode, label: Text(mode.label)),
                )
                .toList(),
            selected: {settings.levelUpMode},
            onSelectionChanged: (selection) {
              update(settings.copyWith(levelUpMode: selection.first));
            },
          ),
          if (widget.onResetProgress != null) ...[
            const SizedBox(height: AppLayout.panelGap),
            const Divider(),
            const SizedBox(height: AppLayout.sectionGap),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: _confirmResetProgress,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset progression'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset progression'),
          content: const Text(
            'Toutes les gemmes, heros debloques, ameliorations et runs sauvegardees seront supprimes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await widget.onResetProgress?.call();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
