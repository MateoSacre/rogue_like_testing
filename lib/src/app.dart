import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'persistence/save_service.dart';
import 'progression/player_progress.dart';
import 'settings/game_settings.dart';
import 'start/start_screen.dart';
import 'theme/app_colors.dart';

class RogueLiteApp extends StatefulWidget {
  const RogueLiteApp({super.key});

  @override
  State<RogueLiteApp> createState() => _RogueLiteAppState();
}

class _RogueLiteAppState extends State<RogueLiteApp>
    with WidgetsBindingObserver {
  GameSettings settings = const GameSettings();
  PlayerProgress progress = PlayerProgress.initial();
  Map<String, dynamic>? battleJson;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadSave();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      SaveService.flush();
    }
  }

  Future<void> loadSave() async {
    final save = await SaveService.load();
    if (!mounted) return;
    setState(() {
      settings = GameSettings.fromJson(
        save?['settings'] as Map<String, dynamic>?,
      );
      progress = PlayerProgress.fromJson(
        save?['progression'] as Map<String, dynamic>?,
      );
      // Very old saves had no `progression` block — reconstruct the roster
      // (unlocked + level) from the heroes embedded in the saved battle.
      if (save?['progression'] == null) {
        final oldBattle = save?['battle'] as Map<String, dynamic>?;
        progress.gems = oldBattle?['gems'] as int? ?? 0;
        final oldHeroes = oldBattle?['heroes'] as List<dynamic>? ?? const [];
        for (final hero in oldHeroes.whereType<Map<String, dynamic>>()) {
          final name = hero['name'] as String?;
          if (name == null) continue;
          progress.unlockedHeroes.add(name);
          progress.heroProgress[name] = HeroProgress(
            level: (hero['level'] as num?)?.toInt() ?? 1,
          );
        }
      }
      battleJson = save?['battle'] as Map<String, dynamic>?;
      loaded = true;
    });
  }

  void updateSettings(GameSettings value) {
    setState(() => settings = value);
  }

  void updateProgress(PlayerProgress value) {
    setState(() => progress = value);
  }

  void updateBattleJson(Map<String, dynamic>? value) {
    setState(() => battleJson = value);
  }

  Future<void> resetProgress() async {
    final nextProgress = PlayerProgress.initial();
    setState(() {
      progress = nextProgress;
      battleJson = null;
    });
    await SaveService.save(settings: settings, progress: nextProgress);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RogueLite Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkScaffoldBackground,
        useMaterial3: true,
      ),
      themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
      // builder wraps the Navigator, so AppLocalizations is an ancestor of
      // every route AND every dialog/popup pushed on the root navigator.
      builder: (context, child) => AppLocalizations(
        language: settings.language,
        child: child ?? const SizedBox.shrink(),
      ),
      home: loaded
          ? StartScreen(
              settings: settings,
              progress: progress,
              battleJson: battleJson,
              onSettingsChanged: updateSettings,
              onProgressChanged: updateProgress,
              onBattleSaved: updateBattleJson,
              onResetProgress: resetProgress,
            )
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
