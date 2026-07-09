import 'board.dart';
import 'character.dart';
import 'game_phase.dart';
import 'hex.dart';
import 'piece.dart';
import 'player.dart';

/// Immutable snapshot of an entire game. All mutations produce a new instance
/// via [copyWith]; this enables a simple undo stack and predictable testing.
class GameState {
  final Board board;
  final Map<String, Piece> pieces;
  final PlayerId currentPlayer;
  final GamePhase phase;

  /// 1-based count of completed half-turns + 1 (i.e. how many times a player has
  /// started a turn). Used for the "player two recruits twice on turn one" rule.
  final int turnNumber;

  /// Ids of pieces already activated during the current action phase.
  final Set<String> activatedPieceIds;

  /// The face-up draft river (up to 3 characters).
  final List<CharacterType> river;

  /// Remaining face-down draft deck.
  final List<CharacterType> deck;

  /// Number of champions each player has recruited so far.
  final Map<PlayerId, int> recruitsDone;

  /// Recruitments the current player still owes this turn (recruitment phase).
  final int pendingRecruits;

  final PlayerId? winner;

  const GameState({
    required this.board,
    required this.pieces,
    required this.currentPlayer,
    required this.phase,
    required this.turnNumber,
    required this.activatedPieceIds,
    required this.river,
    required this.deck,
    required this.recruitsDone,
    this.pendingRecruits = 0,
    this.winner,
  });

  GameState copyWith({
    Map<String, Piece>? pieces,
    PlayerId? currentPlayer,
    GamePhase? phase,
    int? turnNumber,
    Set<String>? activatedPieceIds,
    List<CharacterType>? river,
    List<CharacterType>? deck,
    Map<PlayerId, int>? recruitsDone,
    int? pendingRecruits,
    PlayerId? winner,
    bool clearWinner = false,
  }) {
    return GameState(
      board: board,
      pieces: pieces ?? this.pieces,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      phase: phase ?? this.phase,
      turnNumber: turnNumber ?? this.turnNumber,
      activatedPieceIds: activatedPieceIds ?? this.activatedPieceIds,
      river: river ?? this.river,
      deck: deck ?? this.deck,
      recruitsDone: recruitsDone ?? this.recruitsDone,
      pendingRecruits: pendingRecruits ?? this.pendingRecruits,
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }

  // --- Queries ---

  Iterable<Piece> get allPieces => pieces.values;

  Iterable<Piece> piecesOf(PlayerId player) =>
      pieces.values.where((p) => p.owner == player);

  Piece leaderOf(PlayerId player) =>
      pieces.values.firstWhere((p) => p.owner == player && p.isLeader);

  Piece? pieceAt(Hex h) {
    for (final p in pieces.values) {
      if (p.pos == h) return p;
    }
    return null;
  }

  bool isOccupied(Hex h) => pieceAt(h) != null;

  /// A piece is selectable in the action phase if it belongs to the current
  /// player and has not yet acted.
  bool canActivate(Piece p) =>
      phase == GamePhase.action &&
      p.owner == currentPlayer &&
      !activatedPieceIds.contains(p.id);

  /// Whether every piece of the current player has acted this action phase.
  bool get allActivated =>
      piecesOf(currentPlayer).every((p) => activatedPieceIds.contains(p.id));

  /// Replaces a piece (same id) at a new position.
  GameState withPieceMoved(String id, Hex to) {
    final updated = Map<String, Piece>.from(pieces);
    updated[id] = updated[id]!.copyWith(pos: to);
    return copyWith(pieces: updated);
  }

  /// Swaps the positions of two pieces.
  GameState withPiecesSwapped(String idA, String idB) {
    final updated = Map<String, Piece>.from(pieces);
    final a = updated[idA]!;
    final b = updated[idB]!;
    updated[idA] = a.copyWith(pos: b.pos);
    updated[idB] = b.copyWith(pos: a.pos);
    return copyWith(pieces: updated);
  }

  GameState withPieceAdded(Piece p) {
    final updated = Map<String, Piece>.from(pieces)..[p.id] = p;
    return copyWith(pieces: updated);
  }
}
