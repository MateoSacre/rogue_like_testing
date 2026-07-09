import 'dart:math';

import '../logic/abilities.dart';
import '../logic/action_option.dart';
import '../logic/moves.dart';
import '../logic/victory.dart';
import '../models/board.dart';
import '../models/character.dart';
import '../models/game_phase.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player.dart';

/// Pure rules engine. Every method takes a [GameState] and returns a new one;
/// nothing is mutated in place.
class GameEngine {
  const GameEngine._();

  /// Builds a fresh game: leaders placed, draft river revealed.
  static GameState setupGame({int radius = 4, int? seed}) {
    final board = Board.hexagon(radius: radius);

    final pieces = <String, Piece>{
      'p1-leader': Piece(
        id: 'p1-leader',
        owner: PlayerId.one,
        type: CharacterType.leader,
        pos: board.leaderStart(PlayerId.one),
      ),
      'p2-leader': Piece(
        id: 'p2-leader',
        owner: PlayerId.two,
        type: CharacterType.leader,
        pos: board.leaderStart(PlayerId.two),
      ),
    };

    final deck = CharacterTypeMeta.champions;
    deck.shuffle(Random(seed));
    final river = <CharacterType>[];
    while (river.length < 3 && deck.isNotEmpty) {
      river.add(deck.removeAt(0));
    }

    return GameState(
      board: board,
      pieces: pieces,
      currentPlayer: PlayerId.one,
      phase: GamePhase.action,
      turnNumber: 1,
      activatedPieceIds: const {},
      river: river,
      deck: deck,
      recruitsDone: const {PlayerId.one: 0, PlayerId.two: 0},
    );
  }

  /// All legal actions (normal moves + ability options) for [piece].
  static List<ActionOption> legalActions(GameState state, Piece piece) {
    return [
      ...Moves.normalMoves(state, piece),
      ...abilityOptions(state, piece),
    ];
  }

  /// Applies [option] performed by [piece], records the activation, checks for a
  /// win, and advances to the recruitment phase if every piece has acted.
  static GameState performAction(
    GameState state,
    Piece piece,
    ActionOption option,
  ) {
    var next = option.applyTo(state);
    next = next.copyWith(
      activatedPieceIds: {...next.activatedPieceIds, piece.id},
    );

    final winner = Victory.check(next);
    if (winner != null) {
      return next.copyWith(phase: GamePhase.gameOver, winner: winner);
    }

    if (next.allActivated) {
      next = _enterRecruitment(next);
    }
    return next;
  }

  /// How many champions the current player must recruit this turn.
  static int recruitsThisTurn(GameState state) {
    final player = state.currentPlayer;
    final slotsNeeded = 5 - state.piecesOf(player).length;
    if (slotsNeeded <= 0) return 0;
    if (state.river.isEmpty) return 0;
    final firstTurnOfTwo =
        player == PlayerId.two && (state.recruitsDone[PlayerId.two] ?? 0) == 0;
    final allowance = firstTurnOfTwo ? 2 : 1;
    return min(allowance, slotsNeeded);
  }

  static GameState _enterRecruitment(GameState state) {
    final required = recruitsThisTurn(state);
    if (required == 0) return _endTurn(state);
    return state.copyWith(
      phase: GamePhase.recruitment,
      pendingRecruits: required,
    );
  }

  /// Recruits [type] from the river: places the new piece on the current
  /// player's first free recruitment cell, refills the river from the deck, and
  /// either continues the recruitment phase or ends the turn.
  static GameState doRecruit(GameState state, CharacterType type) {
    assert(state.phase == GamePhase.recruitment);
    assert(state.river.contains(type));

    final player = state.currentPlayer;
    final cell = state.board
        .recruitCells(player)
        .firstWhere((h) => !state.isOccupied(h));

    final index = state.piecesOf(player).length;
    final piece = Piece(
      id: '${player.name}-$index',
      owner: player,
      type: type,
      pos: cell,
    );

    final river = [...state.river]..remove(type);
    final deck = [...state.deck];
    if (deck.isNotEmpty) river.add(deck.removeAt(0));

    final recruitsDone = {...state.recruitsDone};
    recruitsDone[player] = (recruitsDone[player] ?? 0) + 1;

    var next = state
        .withPieceAdded(piece)
        .copyWith(
          river: river,
          deck: deck,
          recruitsDone: recruitsDone,
          pendingRecruits: state.pendingRecruits - 1,
        );

    final stillOwes = next.pendingRecruits > 0 &&
        next.river.isNotEmpty &&
        next.piecesOf(player).length < 5;
    if (!stillOwes) {
      next = _endTurn(next);
    }
    return next;
  }

  static GameState _endTurn(GameState state) {
    return state.copyWith(
      currentPlayer: state.currentPlayer.opponent,
      phase: GamePhase.action,
      turnNumber: state.turnNumber + 1,
      activatedPieceIds: const {},
      pendingRecruits: 0,
    );
  }
}
