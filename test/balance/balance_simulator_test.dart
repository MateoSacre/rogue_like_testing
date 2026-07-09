/// Fast unit tests for the balance simulator's sampling helper. Unlike
/// `balance_test.dart` these don't run any battles, so they run in
/// milliseconds under the default test timeout.
library;

import 'package:flutter_test/flutter_test.dart';

import 'balance_simulator.dart';

void main() {
  group('sampleCompositions', () {
    final pool = List.generate(10, (i) => 'C$i');

    test('returns the requested number of samples when the pool allows it', () {
      final result = sampleCompositions(pool, sizes: [3], samplesPerSize: 5);
      expect(result, hasLength(5));
    });

    test('every sample has the requested size and no duplicate creature', () {
      final result = sampleCompositions(pool, sizes: [4], samplesPerSize: 6);
      for (final team in result) {
        expect(team, hasLength(4));
        expect(team.toSet(), hasLength(4));
      }
    });

    test('samples across multiple sizes are all present', () {
      final result = sampleCompositions(
        pool,
        sizes: [1, 2, 3],
        samplesPerSize: 2,
      );
      expect(result.map((t) => t.length).toSet(), {1, 2, 3});
      expect(result, hasLength(6));
    });

    test('never returns a duplicate composition', () {
      final result = sampleCompositions(pool, sizes: [2], samplesPerSize: 8);
      final keys = result.map((t) => ([...t]..sort()).join('|')).toSet();
      expect(keys, hasLength(result.length));
    });

    test('is deterministic for a given seed', () {
      final a = sampleCompositions(
        pool,
        sizes: [3, 5],
        samplesPerSize: 4,
        seed: 42,
      );
      final b = sampleCompositions(
        pool,
        sizes: [3, 5],
        samplesPerSize: 4,
        seed: 42,
      );
      expect(a, equals(b));
    });

    test('skips sizes larger than the pool without throwing', () {
      final result = sampleCompositions(
        pool,
        sizes: [11, 20],
        samplesPerSize: 3,
      );
      expect(result, isEmpty);
    });

    test(
      'stops early instead of looping forever when a size has fewer '
      'possible combinations than requested',
      () {
        // Only 1 possible team when size == pool.length.
        final result = sampleCompositions(
          pool,
          sizes: [pool.length],
          samplesPerSize: 5,
        );
        expect(result, hasLength(1));
      },
    );
  });
}
