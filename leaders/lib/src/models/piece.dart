import 'character.dart';
import 'hex.dart';
import 'player.dart';

/// A piece on the board: either a Leader or a recruited Champion.
class Piece {
  /// Stable unique id for the lifetime of a game (e.g. 'p1-leader', 'p2-3').
  final String id;
  final PlayerId owner;
  final CharacterType type;
  final Hex pos;

  const Piece({
    required this.id,
    required this.owner,
    required this.type,
    required this.pos,
  });

  bool get isLeader => type == CharacterType.leader;

  Piece copyWith({Hex? pos}) => Piece(
        id: id,
        owner: owner,
        type: type,
        pos: pos ?? this.pos,
      );

  @override
  String toString() => 'Piece($id, ${type.name}@$pos)';
}
