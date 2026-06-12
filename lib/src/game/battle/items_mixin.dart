import '../../data/items.dart';
import '../../l10n/app_language.dart';
import '../../models/fighter.dart';
import '../../models/item.dart';
import '../game_balance.dart';
import 'battle_state.dart';

/// Item drops and ownership: rolls drops on kills, routes them to a hero
/// (immediately in auto mode, via the pending queue in manual mode), and
/// owns the equip/replace/sell arithmetic.
mixin ItemsMixin on BattleControllerBase {
  // ── Drop rolls ────────────────────────────────────────────────────────────

  @override
  void rollItemDrop(Fighter mob) {
    if (heroes.alive.isEmpty) return;
    final ItemDef? drop;
    if (mob.isBoss) {
      drop = bossItemFor(waveInfo.category);
    } else {
      if (random.nextInt(GameBalance.itemDropChanceDivisor) != 0) return;
      drop = _rollStandardItem();
    }
    if (drop == null) return;
    addLog('${mob.name} drops ${drop.name.of(AppLanguage.en)}');
    if (autoAttackEnabled) {
      autoAssignItem(drop);
    } else {
      pendingItemDrops.add(PendingItemDrop(drop));
    }
  }

  ItemDef? _rollStandardItem() {
    final roll = random.nextInt(100);
    final rarity = roll < GameBalance.itemUncommonThreshold
        ? ItemRarity.common
        : roll < GameBalance.itemLegendaryThreshold
        ? ItemRarity.uncommon
        : ItemRarity.legendary;
    final pool = itemsOfRarity(rarity);
    if (pool.isEmpty) return null;
    return pool[random.nextInt(pool.length)];
  }

  // ── Assignment ────────────────────────────────────────────────────────────

  /// Auto mode policy: give the item to the least-equipped living hero it
  /// actually improves. If no hero benefits (all slots hold something at
  /// least as rare), the item is sold.
  void autoAssignItem(ItemDef def) {
    final candidates = heroes.alive
        .where((hero) => _improves(hero, def))
        .toList();
    if (candidates.isEmpty) {
      sellItem(def);
      return;
    }
    candidates.sort((a, b) => a.itemCount.compareTo(b.itemCount));
    equipItem(candidates.first, def);
  }

  /// Manual mode resolution: [hero] receives the item, or null to sell it.
  void resolvePendingItemDrop(PendingItemDrop pending, {Fighter? hero}) {
    pendingItemDrops.remove(pending);
    if (hero == null || !hero.isAlive) {
      sellItem(pending.def);
    } else {
      equipItem(hero, pending.def);
    }
  }

  bool _improves(Fighter hero, ItemDef def) {
    if (def.isRelic) return true;
    final currentId = hero.equipment[def.slot];
    if (currentId == null) return true;
    final current = itemById(currentId);
    return current == null || def.rarity.index > current.rarity.index;
  }

  // ── Equip / sell ──────────────────────────────────────────────────────────

  /// Equips [def] on [hero], baking its stat bonuses into the hero's stats.
  /// A replaced slot item is automatically sold (its bonuses removed first).
  void equipItem(Fighter hero, ItemDef def) {
    if (def.isRelic) {
      hero.relics.add(def.id);
    } else {
      final previousId = hero.equipment[def.slot];
      if (previousId != null) {
        final previous = itemById(previousId);
        if (previous != null) {
          _removeBonuses(hero, previous);
          _creditSale(previous);
        }
      }
      hero.equipment[def.slot] = def.id;
    }
    _applyBonuses(hero, def);
    addLog('${hero.name} equips ${def.name.of(AppLanguage.en)}');
  }

  void sellItem(ItemDef def) {
    _creditSale(def);
  }

  void _creditSale(ItemDef def) {
    final value = itemSellValue(def.rarity);
    gold += value;
    addLog('${def.name.of(AppLanguage.en)} sold for $value gold');
  }

  void _applyBonuses(Fighter hero, ItemDef def) {
    hero.maxHp += def.hpBonus;
    hero.hp += def.hpBonus;
    hero.attackPower += def.atkBonus;
    hero.baseDefence += def.defBonus;
  }

  void _removeBonuses(Fighter hero, ItemDef def) {
    hero.maxHp -= def.hpBonus;
    if (hero.hp > hero.maxHp) hero.hp = hero.maxHp;
    hero.attackPower -= def.atkBonus;
    hero.baseDefence -= def.defBonus;
  }
}
