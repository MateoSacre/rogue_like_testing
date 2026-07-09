/// Balance report — not a pass/fail test.
///
/// Simulates every team composition (all 63 non-empty subsets of the 6 heroes)
/// at starting levels 1 / 25 / 50, in auto mode, with balanced stat allocation
/// and no purchases. Prints a console table and writes `balance_report.csv`
/// so balance can be compared across hero/skill updates.
///
/// Run with:  flutter test test/balance_test.dart
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/creatures.dart';
import 'package:flutter_testing_shit/src/data/heroes.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';

import 'balance/balance_simulator.dart';

/// Team sizes sampled for the 4★/5★ spot-check (decision 12 — the ~19
/// eligible creatures make exhaustive enumeration infeasible above size 2).
const List<int> kHighTierSizes = [1, 2, 3, 4, 5, 6];

/// Unique compositions sampled per size, via `--dart-define=balanceHighTierSamples=N`.
const int kHighTierSamplesPerSize = int.fromEnvironment(
  'balanceHighTierSamples',
  defaultValue: 6,
);

void main() {
  test(
    'balance report: all compositions x levels (auto, balanced, no purchase)',
    () async {
      _printConfigHeader();
      final runStopwatch = Stopwatch()..start();
      var totalCellTime = Duration.zero;

      final results = await simulateAll(
        onCellStart: (ctx) {
          // ignore: avoid_print
          print(
            '${_progress(ctx)} ▶ ${_padLabel(ctx.label)} @ Lvl ${_padLevel(ctx.level)}  '
            '($kTrialsPerCell runs)',
          );
        },
        onCellDone: (ctx, result, elapsed) {
          totalCellTime += elapsed;
          // ignore: avoid_print
          print(
            '${_progress(ctx)} ✓ ${_padLabel(ctx.label)} @ Lvl ${_padLevel(ctx.level)}  '
            '→ médiane ${result.display.padLeft(4)} '
            '(best ${result.best}, worst ${result.worst})  '
            '[${_ms(elapsed)}]',
          );
        },
      );

      runStopwatch.stop();
      final cells = results.length * kLevelTiers.length;
      // ignore: avoid_print
      print(
        '\nTerminé : $cells cellules en ${_secs(runStopwatch.elapsed)} '
        '(cumul calcul ${_secs(totalCellTime)}, '
        'moy ${(totalCellTime.inMilliseconds / cells).round()} ms/cellule)',
      );

      _printTable(results);
      final path = _writeCsv(results, 'balance_report.csv');
      // ignore: avoid_print
      print('\nCSV written to: $path');

      // Sanity check: the simulation actually produced data.
      expect(results, isNotEmpty);
      expect(
        results.every((r) => r.byLevel.length == kLevelTiers.length),
        isTrue,
      );

      // --- 4★/5★ spot-check (decision 12) -------------------------------
      // The full-enumeration approach above only works because the roster is
      // 6 starters (63 subsets). The catalog also has ~19 epic/legendary
      // creatures (bestiary epics + the starters' title-evolution lines), and
      // C(19, 6) alone is > 27k — so instead we sample a handful of unique
      // teams per size.
      final highTierPool = creatureCatalog
          .where((c) => c.rarity.stars == 4 || c.rarity.stars == 5)
          .map((c) => c.id)
          .toList();
      final highTierCompositions = sampleCompositions(
        highTierPool,
        sizes: kHighTierSizes,
        samplesPerSize: kHighTierSamplesPerSize,
      );

      // ignore: avoid_print
      print(
        '\n=== Échantillon 4★/5★ (${highTierPool.length} créatures éligibles, '
        '${highTierCompositions.length} équipes échantillonnées) ===\n',
      );

      final highTierResults = await simulateCompositions(
        highTierCompositions,
        onCellStart: (ctx) {
          // ignore: avoid_print
          print(
            '${_progress(ctx)} ▶ ${_padLabel(ctx.label)} @ Lvl ${_padLevel(ctx.level)}  '
            '($kTrialsPerCell runs)',
          );
        },
        onCellDone: (ctx, result, elapsed) {
          // ignore: avoid_print
          print(
            '${_progress(ctx)} ✓ ${_padLabel(ctx.label)} @ Lvl ${_padLevel(ctx.level)}  '
            '→ médiane ${result.display.padLeft(4)} '
            '(best ${result.best}, worst ${result.worst})  '
            '[${_ms(elapsed)}]',
          );
        },
      );

      _printTable(highTierResults);
      final highTierPath = _writeCsv(
        highTierResults,
        'balance_report_hightier.csv',
      );
      // ignore: avoid_print
      print('\nCSV written to: $highTierPath');

      expect(highTierResults, isNotEmpty);
    },
    // Hundreds of headless runs; well beyond the 30s default.
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

void _printConfigHeader() {
  // 63 non-empty subsets of the 6-hero roster.
  final compCount = (1 << heroNames.length) - 1;
  // ignore: avoid_print
  print('\n=== Simulation d\'équilibrage ===');
  // ignore: avoid_print
  print(
    'Config : niveaux $kLevelTiers · $kTrialsPerCell runs/cellule · '
    'cap $kMaxWaves vagues · skills ${kUseSkills ? 'on' : 'off'} · '
    'auto, stats équilibrées, sans achat',
  );
  // ignore: avoid_print
  print(
    'Vague non résolue après ${GameBalance.maxRoundsPerWave} tours : '
    'décidée au ratio de PV',
  );
  // ignore: avoid_print
  print('Configurable via --dart-define : balanceWaveCap, balanceTrials');
  // ignore: avoid_print
  print(
    '$compCount compositions × ${kLevelTiers.length} niveaux = '
    '${compCount * kLevelTiers.length} cellules\n',
  );
}

String _progress(CellContext ctx) =>
    '[${ctx.index.toString().padLeft(3)}/${ctx.total}]';

String _padLabel(String label) => label.padRight(46);

String _padLevel(int level) => level.toString().padLeft(2);

String _ms(Duration d) => '${d.inMilliseconds} ms';

String _secs(Duration d) => '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';

void _printTable(List<CompositionResult> results) {
  final sorted = [...results]..sort((a, b) {
    final bySize = a.size.compareTo(b.size);
    if (bySize != 0) return bySize;
    final byBest = b.byLevel[50]!.median.compareTo(a.byLevel[50]!.median);
    if (byBest != 0) return byBest;
    return a.label.compareTo(b.label);
  });

  final labelWidth = results
      .map((r) => r.label.length)
      .fold(11, (a, b) => a > b ? a : b);

  String cell(String value, int width) => value.padRight(width);
  String numCell(String value) => value.padLeft(8);

  final header =
      '${cell('Composition', labelWidth)} ${numCell('Lvl 1')} '
      '${numCell('Lvl 25')} ${numCell('Lvl 50')}';

  // ignore: avoid_print
  print('\n=== Balance report — median wave reached ('
      '$kTrialsPerCell runs/cell, "+" = hit cap $kMaxWaves) ===\n');
  // ignore: avoid_print
  print(header);
  // ignore: avoid_print
  print('-' * header.length);

  var currentSize = -1;
  for (final result in sorted) {
    if (result.size != currentSize) {
      currentSize = result.size;
      // ignore: avoid_print
      print('· ${currentSize == 1 ? 'Solo' : '$currentSize héros'}');
    }
    final line =
        '${cell(result.label, labelWidth)} '
        '${numCell(result.byLevel[1]!.display)} '
        '${numCell(result.byLevel[25]!.display)} '
        '${numCell(result.byLevel[50]!.display)}';
    // ignore: avoid_print
    print(line);
  }
}

String _writeCsv(List<CompositionResult> results, String fileName) {
  final buffer = StringBuffer()
    ..writeln(
      'composition,size,'
      'lvl1_median,lvl1_best,lvl1_worst,lvl1_capped,'
      'lvl25_median,lvl25_best,lvl25_worst,lvl25_capped,'
      'lvl50_median,lvl50_best,lvl50_worst,lvl50_capped',
    );

  final sorted = [...results]..sort((a, b) {
    final bySize = a.size.compareTo(b.size);
    return bySize != 0 ? bySize : a.label.compareTo(b.label);
  });

  for (final r in sorted) {
    final l1 = r.byLevel[1]!;
    final l25 = r.byLevel[25]!;
    final l50 = r.byLevel[50]!;
    buffer.writeln(
      '${r.label},${r.size},'
      '${l1.median},${l1.best},${l1.worst},${l1.cappedCount},'
      '${l25.median},${l25.best},${l25.worst},${l25.cappedCount},'
      '${l50.median},${l50.best},${l50.worst},${l50.cappedCount}',
    );
  }

  final file = File(fileName);
  file.writeAsStringSync(buffer.toString());
  return file.absolute.path;
}
