/// Tests for the persistent team-preset logic on [PlayerProgress]: toggling
/// a creature in/out of a slot, the 6-hero cap, JSON round-tripping, and
/// keeping saved teams valid across an evolution.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/progression/player_progress.dart';

PlayerProgress _owning(Set<String> ids, {int level = 1}) {
  return PlayerProgress(
    gems: 0,
    unlockedHeroes: ids,
    heroProgress: {for (final id in ids) id: HeroProgress(level: level)},
  );
}

void main() {
  group('PlayerProgress team presets', () {
    test('starts with teamSlotCount empty slots', () {
      final progress = _owning({'Paladin'});
      expect(progress.teams, hasLength(GameBalance.teamSlotCount));
      expect(progress.teams.every((slot) => slot.isEmpty), isTrue);
    });

    test('toggleInTeam selects, then deselects, the same id', () {
      final progress = _owning({'Paladin'});
      progress.toggleInTeam(0, 'Paladin');
      expect(progress.isInTeam(0, 'Paladin'), isTrue);
      expect(progress.teamRoster(0), ['Paladin']);

      progress.toggleInTeam(0, 'Paladin');
      expect(progress.isInTeam(0, 'Paladin'), isFalse);
      expect(progress.teamRoster(0), isEmpty);
    });

    test('toggleInTeam does nothing once the slot is at the cap', () {
      final ids = List.generate(7, (i) => 'H$i').toSet();
      final progress = _owning(ids);
      for (final id in ids.take(GameBalance.maxTeamSize)) {
        progress.toggleInTeam(0, id);
      }
      expect(progress.teamRoster(0), hasLength(GameBalance.maxTeamSize));

      // A 7th id, with the roster already full: ignored.
      progress.toggleInTeam(0, 'H6');
      expect(progress.teamRoster(0), hasLength(GameBalance.maxTeamSize));
      expect(progress.isInTeam(0, 'H6'), isFalse);

      // Freeing a slot lets a new one in.
      progress.toggleInTeam(0, ids.first);
      expect(progress.teamRoster(0), hasLength(GameBalance.maxTeamSize - 1));
      progress.toggleInTeam(0, 'H6');
      expect(progress.isInTeam(0, 'H6'), isTrue);
    });

    test('slots are independent of one another', () {
      final progress = _owning({'Paladin', 'Warrior'});
      progress.toggleInTeam(0, 'Paladin');
      progress.toggleInTeam(1, 'Warrior');
      expect(progress.teamRoster(0), ['Paladin']);
      expect(progress.teamRoster(1), ['Warrior']);
    });

    test('claimStarterHero seeds team slot 0', () {
      final progress = PlayerProgress.initial();
      progress.claimStarterHero('Paladin');
      expect(progress.teamRoster(0), ['Paladin']);
    });

    test('teamRoster drops ids that are no longer unlocked', () {
      final progress = _owning({'Paladin', 'Warrior'});
      progress.toggleInTeam(0, 'Paladin');
      progress.toggleInTeam(0, 'Warrior');
      progress.unlockedHeroes.remove('Warrior');
      // Stale id is filtered out of the playable roster...
      expect(progress.teamRoster(0), ['Paladin']);
      // ...but left in raw storage rather than silently mutated.
      expect(progress.isInTeam(0, 'Warrior'), isTrue);
    });

    test('evolving a hero swaps its id in every team slot that has it', () {
      final progress = _owning({'Paladin'}, level: GameBalance.maxHeroLevel)
        ..gems = 999999;
      progress.toggleInTeam(0, 'Paladin');
      progress.toggleInTeam(2, 'Paladin');

      final newId = progress.evolve('Paladin');

      expect(newId, isNotNull);
      expect(progress.teamRoster(0), [newId]);
      expect(progress.teamRoster(2), [newId]);
    });

    test('round-trips through JSON', () {
      final progress = _owning({'Paladin', 'Warrior', 'Slime'});
      progress.toggleInTeam(0, 'Paladin');
      progress.toggleInTeam(0, 'Warrior');
      progress.toggleInTeam(3, 'Slime');

      final restored = PlayerProgress.fromJson(progress.toJson());

      expect(restored.teamRoster(0), ['Paladin', 'Warrior']);
      expect(restored.teamRoster(3), ['Slime']);
      expect(restored.teams, hasLength(GameBalance.teamSlotCount));
    });

    test('fromJson pads missing slots and caps oversized ones', () {
      final restored = PlayerProgress.fromJson({
        'gems': 0,
        'unlockedHeroes': ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        'heroProgress': <String, dynamic>{},
        'teams': [
          ['A', 'B', 'C', 'D', 'E', 'F', 'G'], // 7 ids, over the cap of 6
        ],
      });

      expect(restored.teams, hasLength(GameBalance.teamSlotCount));
      expect(restored.teams[0], hasLength(GameBalance.maxTeamSize));
      expect(restored.teams[1], isEmpty);
    });
  });
}
