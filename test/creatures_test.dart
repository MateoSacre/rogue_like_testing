import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_testing_shit/src/data/creatures.dart';
import 'package:flutter_testing_shit/src/data/heroes.dart';
import 'package:flutter_testing_shit/src/data/mobs.dart';
import 'package:flutter_testing_shit/src/game/game_balance.dart';
import 'package:flutter_testing_shit/src/models/creature_rarity.dart';

void main() {
  group('Creature catalog', () {
    test('unifies the six starters and every bestiary mob, with unique ids', () {
      // Starters + every mob (incl. evolution-form mobs) + starter evolutions.
      expect(
        creatureCatalog.length,
        greaterThanOrEqualTo(heroNames.length + mobRoster.length),
      );
      final ids = creatureCatalog.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length)); // unique
      // Every hero id and every mob id is present.
      for (final id in heroNames) {
        expect(creatureById(id), isNotNull, reason: 'missing hero $id');
      }
      for (final mob in mobRoster) {
        expect(creatureById(mob.name), isNotNull, reason: 'missing mob ${mob.name}');
      }
    });

    test('every entry has non-empty FR and EN display names', () {
      for (final def in creatureCatalog) {
        expect(def.name.fr, isNotEmpty, reason: 'FR name for ${def.id}');
        expect(def.name.en, isNotEmpty, reason: 'EN name for ${def.id}');
      }
    });

    test('starters are exactly the six classic heroes at 3★', () {
      final starters = starterCreatures;
      expect(starters.map((c) => c.id).toSet(), heroNames.toSet());
      expect(starters.every((c) => c.rarity == CreatureRarity.rare), isTrue);
      expect(starters.every((c) => c.isStarter), isTrue);
    });

    test('unknown id resolves to null', () {
      expect(creatureById('Not A Creature'), isNull);
    });
  });

  group('Summoned base fighters', () {
    test('a summoned mob becomes a hero form: hero flag, no boss/value/rarity '
        'loss', () {
      final boss = creatureById('Lich King')!;
      expect(boss.rarity, CreatureRarity.mythic);
      final fighter = boss.buildBase();
      expect(fighter.isHero, isTrue);
      expect(fighter.isBoss, isFalse); // ally form, not an enemy boss
      expect(fighter.value, 0);
      expect(fighter.rarity, CreatureRarity.mythic);
      expect(fighter.skill, isNotNull);
      // Same derived stats as its enemy form (rarity + weights are shared).
      final template = mobRoster.firstWhere((m) => m.name == 'Lich King');
      expect(fighter.maxHp, closeTo(template.hp, 1e-9));
      expect(fighter.attackPower, closeTo(template.attack, 1e-9));
    });

    test('a summoned starter keeps its hero identity', () {
      final paladin = creatureById('Paladin')!.buildBase();
      expect(paladin.isHero, isTrue);
      expect(paladin.rarity, CreatureRarity.rare);
    });
  });

  group('Summon pools', () {
    test('each populated tier has summonable creatures and weights are sane', () {
      // common→epic, plus mythic, are summonable; legendary is evolution-only.
      for (final rarity in [
        CreatureRarity.common,
        CreatureRarity.uncommon,
        CreatureRarity.rare,
        CreatureRarity.epic,
        CreatureRarity.mythic,
      ]) {
        expect(summonableByRarity(rarity), isNotEmpty, reason: '$rarity pool');
        expect(GameBalance.summonWeight(rarity), greaterThan(0));
      }
      // No summonable 5★, but evolution forms exist at that tier.
      expect(summonableByRarity(CreatureRarity.legendary), isEmpty);
      expect(creaturesByRarity(CreatureRarity.legendary), isNotEmpty);
      expect(GameBalance.summonWeight(CreatureRarity.legendary), 0);
    });

    test('rarer tiers are weighted lower than commoner ones', () {
      expect(
        GameBalance.summonWeight(CreatureRarity.common),
        greaterThan(GameBalance.summonWeight(CreatureRarity.epic)),
      );
      expect(
        GameBalance.summonWeight(CreatureRarity.epic),
        greaterThan(GameBalance.summonWeight(CreatureRarity.mythic)),
      );
    });
  });

  group('Catalog-driven team building', () {
    test('builds any unlocked creature (mob or hero) at its persisted level', () {
      final team = buildTeamFromProgress(
        selectedHeroNames: const ['Paladin', 'Slime'],
        levelFor: (id) => id == 'Slime' ? 7 : 1,
        xpFor: (_) => 0,
      );
      expect(team.map((f) => f.name), containsAll(['Paladin', 'Slime']));
      final slime = team.firstWhere((f) => f.name == 'Slime');
      expect(slime.isHero, isTrue);
      expect(slime.level, 7);
      expect(slime.rarity, CreatureRarity.common);
    });

    test('old saves keep working: classic hero ids resolve as 3★ starters', () {
      // Migration guarantee — unlockedHeroes from legacy saves are hero names.
      for (final id in heroNames) {
        final def = creatureById(id)!;
        expect(def.isStarter, isTrue);
        expect(def.rarity, CreatureRarity.rare);
      }
    });
  });
}
