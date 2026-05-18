import 'package:flutter/material.dart';

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

class _RogueLiteAppState extends State<RogueLiteApp> {
  GameSettings settings = const GameSettings();
  PlayerProgress progress = PlayerProgress.initial();
  Map<String, dynamic>? battleJson;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    loadSave();
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
      if (save?['progression'] == null) {
        final oldBattle = save?['battle'] as Map<String, dynamic>?;
        progress.gems = oldBattle?['gems'] as int? ?? 0;
        final oldHeroes = oldBattle?['heroes'] as List<dynamic>? ?? const [];
        for (final hero in oldHeroes.whereType<Map<String, dynamic>>()) {
          final name = hero['name'] as String?;
          if (name == null) continue;
          progress.unlockedHeroes.add(name);
          progress.heroStats[name] = PlayerProgress.balancedPointsForLevel(
            hero['level'] as int? ?? 1,
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
