import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import 'game_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.onChanged,
    super.key,
  });

  final GameSettings settings;
  final ValueChanged<GameSettings> onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings settings;

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
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
        ],
      ),
    );
  }
}
