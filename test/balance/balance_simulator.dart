/// Headless balance simulator.
///
/// Runs the real [BattleController] auto-attack loop with no UI, no purchases
/// and balanced level-up allocation, to measure how far a given team
/// composition can reach against the procedurally generated waves.
///
/// This is pure Dart logic (no Flutter widgets), so it runs fast under
/// `flutter test` without a device.
library;

import 'dart:math';

import 'package:flutter_testing_shit/src/data/creatures.dart';
import 'package:flutter_testing_shit/src/data/heroes.dart';
import 'package:flutter_testing_shit/src/game/battle_controller.dart';
import 'package:flutter_testing_shit/src/models/fighter.dart';

/// Starting level tiers each composition is tested at.
const List<int> kLevelTiers = [1, 25, 50];

/// Number of runs per (composition, level). The same seeds are reused across
/// every composition so they all face the exact same gauntlets — a fair
/// comparison that also averages out per-run RNG (crits, AI, merchant rolls).
///
/// Override from the CLI: `flutter test --dart-define=balanceTrials=10`.
const int kTrialsPerCell = int.fromEnvironment('balanceTrials', defaultValue: 7);

/// Wave cap: a very strong team would otherwise clear waves forever.
/// Reaching this cap is reported as "capped" rather than a death wave.
///
/// Stalemates inside a single wave can't happen anymore: the game itself
/// decides any wave still unresolved after `maxRoundsPerWave` rounds by
/// HP ratio, so each wave always terminates.
///
/// Raise it for longer tests:
/// `flutter test --dart-define=balanceWaveCap=400`.
const int kMaxWaves = int.fromEnvironment('balanceWaveCap', defaultValue: 250);

/// Whether heroes use their skills during the simulated auto-attack.
const bool kUseSkills = true;

/// Outcome of a single simulated run.
class RunOutcome {
  const RunOutcome(this.waveReached, this.capped);

  /// Wave number reached (the wave the team died on, or [kMaxWaves] if capped).
  final int waveReached;

  /// True when the run hit [kMaxWaves] without the team being wiped.
  final bool capped;
}

/// Aggregated results for one composition at one level tier.
class LevelResult {
  const LevelResult({
    required this.median,
    required this.best,
    required this.worst,
    required this.cappedCount,
    required this.trials,
  });

  final int median;
  final int best;
  final int worst;
  final int cappedCount;
  final int trials;

  /// Median wave, with a `+` marker if any trial hit the wave cap.
  String get display => cappedCount > 0 ? '$median+' : '$median';
}

/// Full result for one composition across all level tiers.
class CompositionResult {
  CompositionResult(this.heroes, this.byLevel);

  final List<String> heroes;
  final Map<int, LevelResult> byLevel;

  int get size => heroes.length;
  String get label => heroes.join('+');
}

/// Every non-empty subset of [names], ordered by size then roster order.
List<List<String>> allCompositions(List<String> names) {
  final result = <List<String>>[];
  final count = names.length;
  for (var mask = 1; mask < (1 << count); mask++) {
    final subset = <String>[];
    for (var i = 0; i < count; i++) {
      if (mask & (1 << i) != 0) subset.add(names[i]);
    }
    result.add(subset);
  }
  result.sort((a, b) {
    final bySize = a.length.compareTo(b.length);
    if (bySize != 0) return bySize;
    return a.join().compareTo(b.join());
  });
  return result;
}

/// Deterministically samples up to [samplesPerSize] unique team compositions
/// (order-independent, no repeated creature within a team) for each size in
/// [sizes], drawn from [pool].
///
/// Used where the full pool is too large to enumerate exhaustively (see
/// [allCompositions]) — e.g. spot-checking 4★/5★ creature teams, since ~19
/// eligible creatures already means tens of thousands of size-6 subsets.
/// Deterministic across runs via [seed] so reports stay comparable.
List<List<String>> sampleCompositions(
  List<String> pool, {
  required List<int> sizes,
  required int samplesPerSize,
  int seed = 0,
}) {
  final rng = Random(seed);
  final seen = <String>{};
  final result = <List<String>>[];
  for (final size in sizes) {
    if (size <= 0 || size > pool.length) continue;
    var picked = 0;
    var attempts = 0;
    // Bounded retries: once the pool is nearly exhausted for this size there
    // may be fewer distinct combinations than requested — stop instead of
    // looping forever.
    final maxAttempts = samplesPerSize * 20;
    while (picked < samplesPerSize && attempts < maxAttempts) {
      attempts++;
      final subset = ([...pool]..shuffle(rng)).take(size).toList()..sort();
      final key = subset.join('|');
      if (seen.add(key)) {
        result.add(subset);
        picked++;
      }
    }
  }
  return result;
}

/// Builds a team of [names], each hero starting at [level] (degressive
/// stat scaling), with no carried XP.
List<Fighter> buildTeamAtLevel(List<String> names, int level) {
  return buildTeamFromProgress(
    selectedHeroNames: names,
    levelFor: (_) => level,
    xpFor: (_) => 0,
  );
}

/// Runs a single headless auto-attack run for [team] using [seed].
///
/// No real-time waiting happens: [pause] resolves synchronously (instant),
/// so combat plays out as fast as the CPU allows — like dev-mode instant
/// speed, but without even the zero-duration timer hop.
Future<RunOutcome> runOnce(
  List<Fighter> team, {
  required String seed,
  int maxWaves = kMaxWaves,
  bool useSkills = kUseSkills,
}) async {
  final battle = BattleController(heroes: team, seedString: seed);

  // pause() is the instant "no wait" callback. It also doubles as the wave-cap
  // kill switch: setting autoAttackEnabled false makes the controller's
  // internal loop break out cleanly on its next check.
  Future<void> pause() {
    if (battle.waveCounter > maxWaves) battle.autoAttackEnabled = false;
    return Future<void>.value();
  }

  void notify() {}

  while (true) {
    await battle.performAutoAttack(
      pause: pause,
      notify: notify,
      useSkills: useSkills,
      autoBuyHealingItems: false,
      useHealingItems: false,
    );

    if (battle.gameOver) return RunOutcome(battle.waveCounter, false);
    if (battle.waveCounter > maxWaves) return RunOutcome(maxWaves, true);
    if (battle.merchantAvailable) {
      // "No purchase": skip the merchant and move to the next wave.
      battle.continueAfterMerchant();
      continue;
    }
    // Any other stop is unexpected; bail safely.
    return RunOutcome(battle.waveCounter, false);
  }
}

/// Runs [trials] runs for one composition at one level and aggregates them.
Future<LevelResult> simulateCell(
  List<String> names,
  int level, {
  int trials = kTrialsPerCell,
  int maxWaves = kMaxWaves,
  bool useSkills = kUseSkills,
}) async {
  final waves = <int>[];
  var cappedCount = 0;
  for (var t = 0; t < trials; t++) {
    final team = buildTeamAtLevel(names, level);
    final outcome = await runOnce(
      team,
      seed: 'balance-$t',
      maxWaves: maxWaves,
      useSkills: useSkills,
    );
    waves.add(outcome.waveReached);
    if (outcome.capped) cappedCount++;
  }
  waves.sort();
  return LevelResult(
    median: _median(waves),
    best: waves.last,
    worst: waves.first,
    cappedCount: cappedCount,
    trials: trials,
  );
}

/// Called just before a (composition, level) cell starts.
typedef CellStartCallback = void Function(CellContext ctx);

/// Called when a (composition, level) cell finishes, with its [elapsed] time.
typedef CellDoneCallback =
    void Function(CellContext ctx, LevelResult result, Duration elapsed);

/// Identifies a single cell within the overall simulation, for logging.
class CellContext {
  const CellContext({
    required this.names,
    required this.level,
    required this.index,
    required this.total,
  });

  final List<String> names;
  final int level;

  /// 1-based index of this cell across the whole run.
  final int index;

  /// Total number of cells in the whole run.
  final int total;

  String get label => names.join('+');
}

/// Simulates every composition across all level tiers.
Future<List<CompositionResult>> simulateAll({
  List<String>? roster,
  List<int> levels = kLevelTiers,
  int trials = kTrialsPerCell,
  int maxWaves = kMaxWaves,
  bool useSkills = kUseSkills,
  CellStartCallback? onCellStart,
  CellDoneCallback? onCellDone,
}) {
  final names = roster ?? heroNames;
  return simulateCompositions(
    allCompositions(names),
    levels: levels,
    trials: trials,
    maxWaves: maxWaves,
    useSkills: useSkills,
    onCellStart: onCellStart,
    onCellDone: onCellDone,
  );
}

/// Simulates an explicit list of [compositions] across all level tiers.
///
/// Shared by [simulateAll] (exhaustive subsets of a small roster) and callers
/// that instead pass a [sampleCompositions] result (a large pool that can't be
/// enumerated exhaustively).
Future<List<CompositionResult>> simulateCompositions(
  List<List<String>> compositions, {
  List<int> levels = kLevelTiers,
  int trials = kTrialsPerCell,
  int maxWaves = kMaxWaves,
  bool useSkills = kUseSkills,
  CellStartCallback? onCellStart,
  CellDoneCallback? onCellDone,
}) async {
  final results = <CompositionResult>[];
  final total = compositions.length * levels.length;
  var index = 0;
  for (final composition in compositions) {
    final byLevel = <int, LevelResult>{};
    for (final level in levels) {
      final ctx = CellContext(
        names: composition,
        level: level,
        index: ++index,
        total: total,
      );
      onCellStart?.call(ctx);
      final sw = Stopwatch()..start();
      final result = await simulateCell(
        composition,
        level,
        trials: trials,
        maxWaves: maxWaves,
        useSkills: useSkills,
      );
      sw.stop();
      byLevel[level] = result;
      onCellDone?.call(ctx, result, sw.elapsed);
    }
    results.add(CompositionResult(composition, byLevel));
  }
  return results;
}

int _median(List<int> sorted) {
  if (sorted.isEmpty) return 0;
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}
