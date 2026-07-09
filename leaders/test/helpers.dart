import 'package:leaders/src/models/board.dart';
import 'package:leaders/src/models/character.dart';
import 'package:leaders/src/models/game_phase.dart';
import 'package:leaders/src/models/game_state.dart';
import 'package:leaders/src/models/hex.dart';
import 'package:leaders/src/models/piece.dart';
import 'package:leaders/src/models/player.dart';

/// Builds a piece quickly for tests.
Piece pc(String id, PlayerId owner, CharacterType type, Hex pos) =>
    Piece(id: id, owner: owner, type: type, pos: pos);

/// Builds a game state from a list of pieces, with sensible defaults.
GameState makeState(
  List<Piece> pieces, {
  int radius = 4,
  PlayerId current = PlayerId.one,
  GamePhase phase = GamePhase.action,
  List<CharacterType> river = const [],
  List<CharacterType> deck = const [],
}) {
  return GameState(
    board: Board.hexagon(radius: radius),
    pieces: {for (final p in pieces) p.id: p},
    currentPlayer: current,
    phase: phase,
    turnNumber: 1,
    activatedPieceIds: const {},
    river: river,
    deck: deck,
    recruitsDone: const {PlayerId.one: 0, PlayerId.two: 0},
  );
}
