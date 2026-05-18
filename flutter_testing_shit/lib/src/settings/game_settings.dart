import '../theme/app_durations.dart';

enum AutoAttackSpeed {
  instant('Instantane', AppDurations.autoAttackInstant),
  fast('Rapide', AppDurations.autoAttackFast),
  normal('Normal', AppDurations.autoAttackNormal),
  slow('Lente', AppDurations.autoAttackSlow);

  const AutoAttackSpeed(this.label, this.duration);

  final String label;
  final Duration duration;
}

enum LevelUpMode {
  manual('Choix manuel'),
  random('Aleatoire'),
  strongest('Stat la plus forte'),
  balanced('Equilibrer le profil');

  const LevelUpMode(this.label);

  final String label;
}

class GameSettings {
  const GameSettings({
    this.darkTheme = false,
    this.autoAttackSpeed = AutoAttackSpeed.normal,
    this.autoUseSkills = false,
    this.autoBuyHealingItems = false,
    this.autoUseHealingItems = false,
    this.devMode = false,
    this.seedString = '',
    this.levelUpMode = LevelUpMode.manual,
  });

  final bool darkTheme;
  final AutoAttackSpeed autoAttackSpeed;
  final bool autoUseSkills;
  final bool autoBuyHealingItems;
  final bool autoUseHealingItems;
  final bool devMode;
  final String seedString;
  final LevelUpMode levelUpMode;

  GameSettings copyWith({
    bool? darkTheme,
    AutoAttackSpeed? autoAttackSpeed,
    bool? autoUseSkills,
    bool? autoBuyHealingItems,
    bool? autoUseHealingItems,
    bool? devMode,
    String? seedString,
    LevelUpMode? levelUpMode,
  }) {
    return GameSettings(
      darkTheme: darkTheme ?? this.darkTheme,
      autoAttackSpeed: autoAttackSpeed ?? this.autoAttackSpeed,
      autoUseSkills: autoUseSkills ?? this.autoUseSkills,
      autoBuyHealingItems: autoBuyHealingItems ?? this.autoBuyHealingItems,
      autoUseHealingItems: autoUseHealingItems ?? this.autoUseHealingItems,
      devMode: devMode ?? this.devMode,
      seedString: seedString ?? this.seedString,
      levelUpMode: levelUpMode ?? this.levelUpMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkTheme': darkTheme,
      'autoAttackSpeed': autoAttackSpeed.name,
      'autoUseSkills': autoUseSkills,
      'autoBuyHealingItems': autoBuyHealingItems,
      'autoUseHealingItems': autoUseHealingItems,
      'devMode': devMode,
      'seedString': seedString,
      'levelUpMode': levelUpMode.name,
    };
  }

  static GameSettings fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GameSettings();
    return GameSettings(
      darkTheme: json['darkTheme'] == true,
      autoAttackSpeed: AutoAttackSpeed.values.firstWhere(
        (speed) => speed.name == json['autoAttackSpeed'],
        orElse: () => AutoAttackSpeed.normal,
      ),
      autoUseSkills: json['autoUseSkills'] == true,
      autoBuyHealingItems: json['autoBuyHealingItems'] == true,
      autoUseHealingItems: json['autoUseHealingItems'] == true,
      devMode: json['devMode'] == true,
      seedString: json['seedString'] as String? ?? '',
      levelUpMode: LevelUpMode.values.firstWhere(
        (mode) => mode.name == json['levelUpMode'],
        orElse: () => LevelUpMode.manual,
      ),
    );
  }
}
