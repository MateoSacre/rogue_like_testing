import 'package:flutter_test/flutter_test.dart';
import 'package:leaders/src/engine/game_engine.dart';
import 'package:leaders/src/models/character.dart';
import 'package:leaders/src/models/game_phase.dart';
import 'package:leaders/src/models/hex.dart';
import 'package:leaders/src/models/player.dart';

import 'helpers.dart';

void main() {
  test('setup gives each player a leader and a 3-card river', () {
    final s = GameEngine.setupGame(seed: 1);
    expect(s.piecesOf(PlayerId.one).length, 1);
    expect(s.piecesOf(PlayerId.two).length, 1);
    expect(s.river.length, 3);
    expect(s.currentPlayer, PlayerId.one);
  });

  test('player one recruits once and the river refills', () {
    var s = GameEngine.setupGame(seed: 1);
    final leader = s.leaderOf(PlayerId.one);
    final move = GameEngine.legalActions(s, leader).first;
    s = GameEngine.performAction(s, leader, move);
    expect(s.phase, GamePhase.recruitment);
    expect(s.pendingRecruits, 1);

    final pick = s.river.first;
    s = GameEngine.doRecruit(s, pick);

    expect(s.piecesOf(PlayerId.one).length, 2);
    expect(s.recruitsDone[PlayerId.one], 1);
    expect(s.river.length, 3); // refilled from the deck
    expect(s.currentPlayer, PlayerId.two); // turn passed
    expect(s.phase, GamePhase.action);

    // The new champion sits on a recruitment cell.
    final champ =
        s.piecesOf(PlayerId.one).firstWhere((p) => !p.isLeader);
    expect(s.board.recruitCells(PlayerId.one).contains(champ.pos), isTrue);
  });

  test('player two recruits twice on their first turn', () {
    var s = GameEngine.setupGame(seed: 1);
    // Finish player one's turn.
    var leader = s.leaderOf(PlayerId.one);
    s = GameEngine.performAction(s, leader, GameEngine.legalActions(s, leader).first);
    s = GameEngine.doRecruit(s, s.river.first);

    // Player two's turn.
    expect(s.currentPlayer, PlayerId.two);
    leader = s.leaderOf(PlayerId.two);
    s = GameEngine.performAction(s, leader, GameEngine.legalActions(s, leader).first);
    expect(s.phase, GamePhase.recruitment);
    expect(s.pendingRecruits, 2);

    s = GameEngine.doRecruit(s, s.river.first);
    expect(s.phase, GamePhase.recruitment); // still owes one
    expect(s.pendingRecruits, 1);

    s = GameEngine.doRecruit(s, s.river.first);
    expect(s.recruitsDone[PlayerId.two], 2);
    expect(s.piecesOf(PlayerId.two).length, 3); // leader + 2 champions
    expect(s.currentPlayer, PlayerId.one);
  });

  test('a full team (5 pieces) owes no recruitment', () {
    final s = makeState(
      [
        pc('L', PlayerId.one, CharacterType.leader, const Hex(0, 0)),
        pc('1', PlayerId.one, CharacterType.geolier, const Hex(2, 0)),
        pc('2', PlayerId.one, CharacterType.cogneur, const Hex(-2, 0)),
        pc('3', PlayerId.one, CharacterType.sauteur, const Hex(0, 2)),
        pc('4', PlayerId.one, CharacterType.vizir, const Hex(0, -2)),
      ],
      river: [CharacterType.archere],
    );
    expect(GameEngine.recruitsThisTurn(s), 0);
  });
}
