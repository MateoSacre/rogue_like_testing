import '../../models/enums.dart';
import '../../models/fighter.dart';
import '../../utils/format.dart';
import '../game_balance.dart';
import 'battle_state.dart';

/// Handles all shop and inventory logic: buying/using potions,
/// XP potions, special upgrades, and the merchant phase.
mixin InventoryMixin on BattleControllerBase {
  // ── Merchant phase ────────────────────────────────────────────────────────

  @override
  void continueAfterMerchant() {
    if (!merchantAvailable) return;
    merchantAvailable = false;
    autoAttackEnabled = resumeAutoAttackAfterMerchant;
    resumeAutoAttackAfterMerchant = false;
    startNextWave();
  }

  @override
  int autoBuyHealingItems() {
    if (!merchantAvailable) return 0;
    var bought = 0;
    if (_shouldBuyTeamPotionAutomatically() && buyTeamPotionStock()) bought++;
    while (buySinglePotionStock()) {
      bought++;
    }
    return bought;
  }

  bool _shouldBuyTeamPotionAutomatically() {
    final alive = heroes.alive;
    return alive.length > 1 &&
        alive.every((hero) => hero.hp < hero.maxHp) &&
        gold >= GameBalance.teamPotionCost;
  }

  // ── Healing potions ───────────────────────────────────────────────────────

  bool buySinglePotion(Fighter hero) {
    if (!merchantAvailable ||
        !hero.isAlive ||
        hero.hp >= hero.maxHp ||
        gold < GameBalance.singlePotionCost) {
      return false;
    }
    gold -= GameBalance.singlePotionCost;
    healingPotionStock++;
    addLog('Bought healing potion');
    return useHealingPotion(hero);
  }

  bool buySinglePotionStock() {
    if (!merchantAvailable || gold < GameBalance.singlePotionCost) return false;
    gold -= GameBalance.singlePotionCost;
    healingPotionStock++;
    addLog('Stored healing potion');
    return true;
  }

  @override
  bool useHealingPotion(Fighter hero) {
    if (!hero.isAlive || hero.hp >= hero.maxHp || healingPotionStock <= 0) {
      return false;
    }
    healingPotionStock--;
    final healed = hero.heal(hero.maxHp * GameBalance.singlePotionHealRatio);
    addLog('Healing potion on ${hero.name}: +${fmt(healed)} HP');
    return true;
  }

  // ── Team potions ──────────────────────────────────────────────────────────

  bool buyTeamPotion() {
    if (!merchantAvailable || !hasInjuredHero || gold < GameBalance.teamPotionCost) {
      return false;
    }
    gold -= GameBalance.teamPotionCost;
    teamPotionStock++;
    addLog('Bought team potion');
    return useTeamPotion();
  }

  bool buyTeamPotionStock() {
    if (!merchantAvailable || gold < GameBalance.teamPotionCost) return false;
    gold -= GameBalance.teamPotionCost;
    teamPotionStock++;
    addLog('Stored team potion');
    return true;
  }

  @override
  bool useTeamPotion() {
    if (teamPotionStock <= 0 || !hasInjuredHero) return false;
    teamPotionStock--;
    for (final hero in heroes.alive) {
      hero.heal(hero.maxHp * GameBalance.teamPotionHealRatio);
    }
    addLog('Team potion used');
    return true;
  }

  // ── XP potions ────────────────────────────────────────────────────────────

  bool buyXpPotion(
    Fighter hero, {
    required int xp,
    required int cost,
    required String label,
  }) {
    if (!merchantAvailable || !hero.isAlive || gold < cost) return false;
    gold -= cost;
    gainXp(hero, xp, currentLevelUpMode);
    addLog('$label used on ${hero.name}');
    return true;
  }

  // ── Special potions ───────────────────────────────────────────────────────

  bool buySpecialPotionStock() {
    if (!merchantAvailable || gold < GameBalance.specialPotionCost) return false;
    gold -= GameBalance.specialPotionCost;
    specialPotionStock++;
    addLog('Stored special potion');
    return true;
  }

  bool buySpecialPotion(Fighter hero) {
    final skill = hero.skill;
    if (!hero.isAlive || skill == null || skill.charge >= skill.maxCharge) {
      return false;
    }
    if (!buySpecialPotionStock()) return false;
    return useSpecialPotion(hero);
  }

  bool useSpecialPotion(Fighter hero) {
    final skill = hero.skill;
    if (!hero.isAlive ||
        skill == null ||
        skill.charge >= skill.maxCharge ||
        specialPotionStock <= 0) {
      return false;
    }
    specialPotionStock--;
    skill.fullyRecharge();
    actionMode = selectedHero?.skill?.isReady == true
        ? ActionMode.skill
        : ActionMode.attack;
    addLog('Special potion recharges ${hero.name}');
    return true;
  }

  // ── Skill bar upgrade ─────────────────────────────────────────────────────

  bool buySpecialBarUpgrade(Fighter hero) {
    final skill = hero.skill;
    if (!merchantAvailable ||
        !hero.isAlive ||
        skill == null ||
        gold < GameBalance.specialBarUpgradeCost) {
      return false;
    }
    gold -= GameBalance.specialBarUpgradeCost;
    skill.chargeBars++;
    addLog('${hero.name} gains a special charge bar');
    return true;
  }
}
