import '../data/heroes.dart';
import 'hero_stat_points.dart';
import '../models/level_up_stat.dart';

class PlayerProgress {
  PlayerProgress({
    required this.gems,
    required Set<String> unlockedHeroes,
    required Map<String, HeroStatPoints> heroStats,
  }) : unlockedHeroes = {...unlockedHeroes},
       heroStats = {...heroStats};

  factory PlayerProgress.initial() {
    return PlayerProgress(gems: 0, unlockedHeroes: {}, heroStats: {});
  }

  factory PlayerProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PlayerProgress.initial();
    final heroStats = <String, HeroStatPoints>{};
    final rawStats = json['heroStats'] as Map<String, dynamic>? ?? const {};
    for (final entry in rawStats.entries) {
      heroStats[entry.key] = HeroStatPoints.fromJson(
        entry.value as Map<String, dynamic>?,
      );
    }
    final legacyLevels =
        json['heroLevels'] as Map<String, dynamic>? ?? const {};
    for (final entry in legacyLevels.entries) {
      heroStats.putIfAbsent(
        entry.key,
        () => balancedPointsForLevel((entry.value as num?)?.toInt() ?? 1),
      );
    }
    return PlayerProgress(
      gems: json['gems'] as int? ?? 0,
      unlockedHeroes: (json['unlockedHeroes'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toSet(),
      heroStats: heroStats,
    );
  }

  static const heroCost = 50;
  static const heroLevelCost = 5;
  static const maxPermanentHeroLevel = 50;

  int gems;
  final Set<String> unlockedHeroes;
  final Map<String, HeroStatPoints> heroStats;

  bool get hasUnlockedHero => unlockedHeroes.isNotEmpty;

  int levelFor(String heroName) {
    return (1 + statPointsFor(heroName).total).clamp(1, maxPermanentHeroLevel);
  }

  HeroStatPoints statPointsFor(String heroName) {
    return heroStats[heroName] ?? const HeroStatPoints();
  }

  bool isUnlocked(String heroName) {
    return unlockedHeroes.contains(heroName);
  }

  bool canClaimStarterHero(String heroName) {
    return !hasUnlockedHero && heroNames.contains(heroName);
  }

  bool claimStarterHero(String heroName) {
    if (!canClaimStarterHero(heroName)) return false;
    unlockedHeroes.add(heroName);
    heroStats[heroName] = const HeroStatPoints();
    return true;
  }

  bool canBuyHero(String heroName) {
    return heroNames.contains(heroName) &&
        !isUnlocked(heroName) &&
        gems >= heroCost;
  }

  bool buyHero(String heroName) {
    if (!canBuyHero(heroName)) return false;
    gems -= heroCost;
    unlockedHeroes.add(heroName);
    heroStats[heroName] = const HeroStatPoints();
    return true;
  }

  bool canUpgradeHero(String heroName, LevelUpStat stat) {
    return isUnlocked(heroName) &&
        levelFor(heroName) < maxPermanentHeroLevel &&
        gems >= heroLevelCost;
  }

  bool upgradeHero(String heroName, LevelUpStat stat) {
    if (!canUpgradeHero(heroName, stat)) return false;
    gems -= heroLevelCost;
    heroStats[heroName] = statPointsFor(heroName).add(stat);
    return true;
  }

  bool canReallocateHeroStats(String heroName, HeroStatPoints stats) {
    if (!isUnlocked(heroName)) return false;
    if (stats.maxHp < 0 || stats.attack < 0 || stats.defence < 0) {
      return false;
    }
    return stats.total == statPointsFor(heroName).total &&
        stats.total <= maxPermanentHeroLevel - 1;
  }

  bool reallocateHeroStats(String heroName, HeroStatPoints stats) {
    if (!canReallocateHeroStats(heroName, stats)) return false;
    heroStats[heroName] = stats;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'gems': gems,
      'unlockedHeroes': unlockedHeroes.toList()..sort(),
      'heroStats': heroStats.map(
        (name, stats) => MapEntry(name, stats.toJson()),
      ),
    };
  }

  static HeroStatPoints balancedPointsForLevel(int level) {
    var stats = const HeroStatPoints();
    final points = (level - 1).clamp(0, maxPermanentHeroLevel - 1);
    for (var i = 0; i < points; i++) {
      stats = stats.add(LevelUpStat.values[i % LevelUpStat.values.length]);
    }
    return stats;
  }
}
