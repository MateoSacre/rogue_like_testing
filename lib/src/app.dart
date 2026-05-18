import 'package:flutter/material.dart';

import 'game/game_screen.dart';
import 'persistence/save_service.dart';
import 'settings/game_settings.dart';
import 'theme/app_colors.dart';

class RogueLiteApp extends StatefulWidget {
  const RogueLiteApp({super.key});

  @override
  State<RogueLiteApp> createState() => _RogueLiteAppState();
}

class _RogueLiteAppState extends State<RogueLiteApp> {
  GameSettings settings = const GameSettings();
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
      battleJson = save?['battle'] as Map<String, dynamic>?;
      loaded = true;
    });
  }

  void updateSettings(GameSettings value) {
    setState(() => settings = value);
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
          ? GameScreen(
              settings: settings,
              initialBattleJson: battleJson,
              onSettingsChanged: updateSettings,
            )
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
