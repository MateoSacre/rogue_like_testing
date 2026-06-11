import '../l10n/app_language.dart';
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
    this.language = AppLanguage.fr,
    this.autoAttackSpeed = AutoAttackSpeed.normal,
    this.autoUseSkills = false,
    this.autoBuyHealingItems = false,
    this.autoUseHealingItems = false,
    this.devMode = false,
    this.devAutoRestartOnDefeat = false,
    this.seedString = '',
    this.levelUpMode = LevelUpMode.manual,
  });

  final bool darkTheme;
  final AppLanguage language;
  final AutoAttackSpeed autoAttackSpeed;
  final bool autoUseSkills;
  final bool autoBuyHealingItems;
  final bool autoUseHealingItems;
  final bool devMode;
  final bool devAutoRestartOnDefeat;
  final String seedString;
  final LevelUpMode levelUpMode;

  GameSettings copyWith({
    bool? darkTheme,
    AppLanguage? language,
    AutoAttackSpeed? autoAttackSpeed,
    bool? autoUseSkills,
    bool? autoBuyHealingItems,
    bool? autoUseHealingItems,
    bool? devMode,
    bool? devAutoRestartOnDefeat,
    String? seedString,
    LevelUpMode? levelUpMode,
  }) {
    return GameSettings(
      darkTheme: darkTheme ?? this.darkTheme,
      language: language ?? this.language,
      autoAttackSpeed: autoAttackSpeed ?? this.autoAttackSpeed,
      autoUseSkills: autoUseSkills ?? this.autoUseSkills,
      autoBuyHealingItems: autoBuyHealingItems ?? this.autoBuyHealingItems,
      autoUseHealingItems: autoUseHealingItems ?? this.autoUseHealingItems,
      devMode: devMode ?? this.devMode,
      devAutoRestartOnDefeat:
          devAutoRestartOnDefeat ?? this.devAutoRestartOnDefeat,
      seedString: seedString ?? this.seedString,
      levelUpMode: levelUpMode ?? this.levelUpMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkTheme': darkTheme,
      'language': language.name,
      'autoAttackSpeed': autoAttackSpeed.name,
      'autoUseSkills': autoUseSkills,
      'autoBuyHealingItems': autoBuyHealingItems,
      'autoUseHealingItems': autoUseHealingItems,
      'devMode': devMode,
      'devAutoRestartOnDefeat': devAutoRestartOnDefeat,
      'seedString': seedString,
      'levelUpMode': levelUpMode.name,
    };
  }

  static GameSettings fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GameSettings();
    final devMode = json['devMode'] == true;
    final autoAttackSpeed = AutoAttackSpeed.values.firstWhere(
      (speed) => speed.name == json['autoAttackSpeed'],
      orElse: () => AutoAttackSpeed.normal,
    );
    return GameSettings(
      darkTheme: json['darkTheme'] == true,
      language: AppLanguage.fromName(json['language'] as String?),
      autoAttackSpeed: !devMode && autoAttackSpeed == AutoAttackSpeed.instant
          ? AutoAttackSpeed.normal
          : autoAttackSpeed,
      autoUseSkills: json['autoUseSkills'] == true,
      autoBuyHealingItems: json['autoBuyHealingItems'] == true,
      autoUseHealingItems: json['autoUseHealingItems'] == true,
      devMode: devMode,
      devAutoRestartOnDefeat: json['devAutoRestartOnDefeat'] == true,
      seedString: json['seedString'] as String? ?? '',
      levelUpMode: LevelUpMode.values.firstWhere(
        (mode) => mode.name == json['levelUpMode'],
        orElse: () => LevelUpMode.manual,
      ),
    );
  }
}
