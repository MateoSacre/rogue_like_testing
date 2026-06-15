import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
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

  List<AutoAttackSpeed> get _availableAutoAttackSpeeds {
    if (settings.devMode) return AutoAttackSpeed.values;
    return AutoAttackSpeed.values
        .where((speed) => speed != AutoAttackSpeed.instant)
        .toList();
  }

  GameSettings _withDevMode(bool enabled) {
    var next = settings.copyWith(devMode: enabled);
    if (!enabled && next.autoAttackSpeed == AutoAttackSpeed.instant) {
      next = next.copyWith(autoAttackSpeed: AutoAttackSpeed.normal);
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(K.settings))),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.pagePadding),
        children: [
          SwitchListTile(
            title: Text(context.tr(K.darkTheme)),
            value: settings.darkTheme,
            onChanged: (value) => update(settings.copyWith(darkTheme: value)),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          Text(context.tr(K.language), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppLayout.controlGap),
          SegmentedButton<AppLanguage>(
            segments: AppLanguage.values
                .map(
                  (language) => ButtonSegment(
                    value: language,
                    label: Text(language.nativeLabel),
                  ),
                )
                .toList(),
            selected: {settings.language},
            onSelectionChanged: (selection) =>
                update(settings.copyWith(language: selection.first)),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          Text(
            context.tr(K.autoAttackSpeedTitle),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppLayout.controlGap),
          SegmentedButton<AutoAttackSpeed>(
            segments: _availableAutoAttackSpeeds
                .map(
                  (speed) => ButtonSegment(
                    value: speed,
                    label: Text(context.l10n.autoAttackSpeed(speed)),
                  ),
                )
                .toList(),
            selected: {
              _availableAutoAttackSpeeds.contains(settings.autoAttackSpeed)
                  ? settings.autoAttackSpeed
                  : AutoAttackSpeed.normal,
            },
            onSelectionChanged: (selection) {
              update(settings.copyWith(autoAttackSpeed: selection.first));
            },
          ),
          const SizedBox(height: AppLayout.sectionGap),
          SwitchListTile(
            title: Text(context.tr(K.autoUseSkills)),
            subtitle: Text(context.tr(K.autoUseSkillsDesc)),
            value: settings.autoUseSkills,
            onChanged: (value) =>
                update(settings.copyWith(autoUseSkills: value)),
          ),
          SwitchListTile(
            title: Text(context.tr(K.autoBuyHealing)),
            subtitle: Text(context.tr(K.autoBuyHealingDesc)),
            value: settings.autoBuyHealingItems,
            onChanged: (value) =>
                update(settings.copyWith(autoBuyHealingItems: value)),
          ),
          SwitchListTile(
            title: Text(context.tr(K.autoUseHealing)),
            subtitle: Text(context.tr(K.autoUseHealingDesc)),
            value: settings.autoUseHealingItems,
            onChanged: (value) =>
                update(settings.copyWith(autoUseHealingItems: value)),
          ),
          SwitchListTile(
            title: Text(context.tr(K.devMode)),
            subtitle: Text(context.tr(K.devModeDesc)),
            value: settings.devMode,
            onChanged: (value) => update(_withDevMode(value)),
          ),
          if (settings.devMode) ...[
            const SizedBox(height: AppLayout.controlGap),
            SwitchListTile(
              title: Text(context.tr(K.devAutoRestart)),
              subtitle: Text(context.tr(K.devAutoRestartDesc)),
              value: settings.devAutoRestartOnDefeat,
              onChanged: (value) =>
                  update(settings.copyWith(devAutoRestartOnDefeat: value)),
            ),
            const SizedBox(height: AppLayout.controlGap),
            TextField(
              controller: seedController,
              decoration: InputDecoration(
                labelText: context.tr(K.seedLabel),
                hintText: context.tr(K.seedHint),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                update(settings.copyWith(seedString: value));
              },
            ),
          ],
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
              label: Text(context.tr(K.resetProgress)),
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
          title: Text(context.tr(K.resetProgress)),
          content: Text(context.tr(K.resetProgressConfirm)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr(K.cancel)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr(K.reset)),
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
