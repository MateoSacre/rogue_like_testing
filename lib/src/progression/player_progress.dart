import 'dart:math';

import '../data/creatures.dart';
import '../data/heroes.dart';
import '../game/game_balance.dart';
import 'summon.dart';

/// Persistent level + XP for one hero. The level is unified: in-run XP and
/// (later) duplicate XP both feed this single bar, and it carries across runs.
class HeroProgress {
  HeroProgress({this.level = 1, this.xp = 0});

  factory HeroProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HeroProgress();
    return HeroProgress(
      level: ((json['level'] as num?)?.toInt() ?? 1).clamp(
        1,
        GameBalance.maxHeroLevel,
      ),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
    );
  }

  int level;
  int xp;

  Map<String, dynamic> toJson() => {'level': level, 'xp': xp};
}

class PlayerProgress {
  PlayerProgress({
    required this.gems,
    required Set<String> unlockedHeroes,
    required Map<String, HeroProgress> heroProgress,
  }) : unlockedHeroes = {...unlockedHeroes},
       heroProgress = {...heroProgress};

  factory PlayerProgress.initial() {
    return PlayerProgress(gems: 0, unlockedHeroes: {}, heroProgress: {});
  }

  factory PlayerProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PlayerProgress.initial();
    final heroProgress = <String, HeroProgress>{};
    final raw = json['heroProgress'] as Map<String, dynamic>? ?? const {};
    for (final entry in raw.entries) {
      heroProgress[entry.key] = HeroProgress.fromJson(
        entry.value as Map<String, dynamic>?,
      );
    }
    final unlocked =
        (json['unlockedHeroes'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toSet();

    // ── Legacy migration ──────────────────────────────────────────────────
    // Old saves stored allocated stat points (heroStats) or raw heroLevels.
    // Convert them to a starting level (total points + 1).
    final legacyStats = json['heroStats'] as Map<String, dynamic>? ?? const {};
    for (final entry in legacyStats.entries) {
      final pts = entry.value as Map<String, dynamic>?;
      final total = pts == null
          ? 0
          : ((pts['maxHp'] as num?)?.toInt() ?? 0) +
                ((pts['attack'] as num?)?.toInt() ?? 0) +
                ((pts['defence'] as num?)?.toInt() ?? 0) +
                ((pts['unassigned'] as num?)?.toInt() ?? 0);
      unlocked.add(entry.key);
      heroProgress.putIfAbsent(
        entry.key,
        () => HeroProgress(level: (1 + total).clamp(1, GameBalance.maxHeroLevel)),
      );
    }
    final legacyLevels = json['heroLevels'] as Map<String, dynamic>? ?? const {};
    for (final entry in legacyLevels.entries) {
      unlocked.add(entry.key);
      heroProgress.putIfAbsent(
        entry.key,
        () => HeroProgress(
          level: ((entry.value as num?)?.toInt() ?? 1).clamp(
            1,
            GameBalance.maxHeroLevel,
          ),
        ),
      );
    }
    // Every unlocked hero must have a progress entry.
    for (final name in unlocked) {
      heroProgress.putIfAbsent(name, HeroProgress.new);
    }

    return PlayerProgress(
      gems: json['gems'] as int? ?? 0,
      unlockedHeroes: unlocked,
      heroProgress: heroProgress,
    );
  }

  static int get maxLevel => GameBalance.maxHeroLevel;

  int gems;
  final Set<String> unlockedHeroes;
  final Map<String, HeroProgress> heroProgress;

  bool get hasUnlockedHero => unlockedHeroes.isNotEmpty;

  bool isUnlocked(String heroName) => unlockedHeroes.contains(heroName);

  int levelFor(String heroName) => heroProgress[heroName]?.level ?? 1;

  int xpFor(String heroName) => heroProgress[heroName]?.xp ?? 0;

  void _ensureEntry(String heroName) {
    heroProgress.putIfAbsent(heroName, HeroProgress.new);
  }

  bool canClaimStarterHero(String heroName) {
    return !hasUnlockedHero && heroNames.contains(heroName);
  }

  bool claimStarterHero(String heroName) {
    if (!canClaimStarterHero(heroName)) return false;
    unlockedHeroes.add(heroName);
    _ensureEntry(heroName);
    return true;
  }

  // ── Summoning ───────────────────────────────────────────────────────────

  bool get canSummonSingle => gems >= GameBalance.summonCostSingle;
  bool get canSummonTen => gems >= GameBalance.summonCostTen;

  /// Spends gems for a single summon and applies the result. Returns null when
  /// the player cannot afford it.
  SummonResult? summonSingle(Random random) {
    if (!canSummonSingle) return null;
    gems -= GameBalance.summonCostSingle;
    return _applySummon(rollSummon(random));
  }

  /// Spends gems for a ten-pull (epic pity guaranteed) and applies every
  /// result. Returns an empty list when the player cannot afford it.
  List<SummonResult> summonTen(Random random) {
    if (!canSummonTen) return const [];
    gems -= GameBalance.summonCostTen;
    return rollSummonBatch(random).map(_applySummon).toList();
  }

  /// Unlocks a freshly summoned creature, or converts a duplicate into fixed
  /// XP toward its persistent level.
  SummonResult _applySummon(CreatureDef def) {
    if (!isUnlocked(def.id)) {
      unlockedHeroes.add(def.id);
      _ensureEntry(def.id);
      return SummonResult(
        creatureId: def.id,
        rarity: def.rarity,
        isNew: true,
        xpGained: 0,
      );
    }
    _ensureEntry(def.id);
    final entry = heroProgress[def.id]!;
    final granted = entry.level >= GameBalance.maxHeroLevel
        ? 0
        : GameBalance.summonDuplicateXp;
    _grantXp(entry, granted);
    return SummonResult(
      creatureId: def.id,
      rarity: def.rarity,
      isNew: false,
      xpGained: granted,
    );
  }

  /// Advances a persisted level/XP entry, mirroring the in-run level-up loop
  /// (`LevelingMixin.gainXp`) but on level/XP only — stats are derived later.
  void _grantXp(HeroProgress entry, int xp) {
    if (xp <= 0 || entry.level >= GameBalance.maxHeroLevel) return;
    entry.xp += xp;
    while (entry.level < GameBalance.maxHeroLevel &&
        entry.xp >= GameBalance.xpForLevel(entry.level)) {
      entry.xp -= GameBalance.xpForLevel(entry.level);
      entry.level++;
    }
    if (entry.level >= GameBalance.maxHeroLevel) entry.xp = 0;
  }

  // ── Evolution ───────────────────────────────────────────────────────────

  /// Id of the form [heroName] evolves into, or null if terminal/unknown.
  String? evolutionTargetOf(String heroName) => evolutionTargetId(heroName);

  /// Gem cost to evolve [heroName], or null when it cannot evolve.
  int? evolutionCostOf(String heroName) {
    final targetId = evolutionTargetId(heroName);
    final target = targetId == null ? null : creatureById(targetId);
    return target == null ? null : GameBalance.evolutionCost(target.rarity);
  }

  /// Whether [heroName] is unlocked, maxed, has a next form and is affordable.
  bool canEvolve(String heroName) {
    final cost = evolutionCostOf(heroName);
    return cost != null &&
        isUnlocked(heroName) &&
        levelFor(heroName) >= GameBalance.maxHeroLevel &&
        gems >= cost;
  }

  /// Evolves [heroName] into its next form: spends gems, unlocks the target at
  /// level 1 and consumes the source. Returns the new form's id, or null when
  /// the evolution is not allowed.
  String? evolve(String heroName) {
    if (!canEvolve(heroName)) return null;
    final targetId = evolutionTargetId(heroName)!;
    gems -= evolutionCostOf(heroName)!;
    unlockedHeroes
      ..remove(heroName)
      ..add(targetId);
    heroProgress.remove(heroName);
    heroProgress[targetId] = HeroProgress();
    return targetId;
  }

  /// Writes a hero's level/XP back after a run (only for unlocked heroes).
  void recordHeroProgress(String heroName, int level, int xp) {
    final entry = heroProgress[heroName];
    if (entry == null) return;
    entry.level = level.clamp(1, GameBalance.maxHeroLevel);
    entry.xp = xp;
  }

  Map<String, dynamic> toJson() {
    return {
      'gems': gems,
      'unlockedHeroes': unlockedHeroes.toList()..sort(),
      'heroProgress': heroProgress.map(
        (name, entry) => MapEntry(name, entry.toJson()),
      ),
    };
  }
}
