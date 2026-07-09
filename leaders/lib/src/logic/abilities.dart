import '../models/character.dart';
import '../models/game_state.dart';
import '../models/hex.dart';
import '../models/piece.dart';
import 'action_option.dart';
import 'hex_geometry.dart';
import 'passives.dart';

/// Signature for an active ability: given the state and the acting piece,
/// produces the list of concrete [ActionOption]s the player may pick.
typedef AbilityFn = List<ActionOption> Function(GameState state, Piece piece);

/// Resolves the active-ability options for [piece], applying global gates:
/// the piece must have an active ability and must not be jailed by a Geôlier.
List<ActionOption> abilityOptions(GameState state, Piece piece) {
  final id = piece.type.activeAbilityId;
  if (id == null) return const [];
  if (Passives.isAbilityBlocked(state, piece)) return const [];
  final fn = _registry[id];
  if (fn == null) return const [];
  return fn(state, piece);
}

final Map<String, AbilityFn> _registry = {
  'illusionniste': _illusionniste,
  'lance_grappin': _lanceGrappin,
  'rodeuse': _rodeuse,
  'tavernier': _tavernier,
  'manipulatrice': _manipulatrice,
  'cogneur': _cogneur,
  'sauteur': _sauteur,
  'garde_royal': _gardeRoyalStub,
};

// --- Helpers ---

/// Unit step from [from] toward an aligned cell [to].
Hex _step(Hex from, Hex to) => Hex.directions[from.directionTo(to)!];

bool _empty(GameState s, Hex h) => s.board.contains(h) && !s.isOccupied(h);

// --- Abilities ---

/// Illusionniste: swap position with a visible piece in a straight line that is
/// not adjacent. Enemy targets shielded by a Protecteur cannot be swapped.
List<ActionOption> _illusionniste(GameState state, Piece piece) {
  final options = <ActionOption>[];
  for (final cell in HexGeometry.visiblePieceCells(state, piece.pos)) {
    if (piece.pos.isAdjacentTo(cell)) continue; // must be non-adjacent
    final target = state.pieceAt(cell)!;
    if (Passives.isMoveShielded(state, piece, target)) continue;
    options.add(ActionOption(
      target: cell,
      kind: 'illusionniste',
      label: 'Échanger avec ${target.type.displayName}',
      apply: (before) => before.withPiecesSwapped(piece.id, target.id),
    ));
  }
  return options;
}

/// Lance-grappin: for each visible piece in a straight line, either move next to
/// it ("aller à") or pull it next to oneself ("attirer").
List<ActionOption> _lanceGrappin(GameState state, Piece piece) {
  final options = <ActionOption>[];
  final usedTargets = <Hex>{};
  for (final cell in HexGeometry.visiblePieceCells(state, piece.pos)) {
    final target = state.pieceAt(cell)!;
    final step = _step(piece.pos, cell);

    // "Aller à": move to the empty cell adjacent to the target, on our side.
    final landing = cell - step;
    if (landing != piece.pos && _empty(state, landing)) {
      usedTargets.add(landing);
      options.add(ActionOption(
        target: landing,
        kind: 'lance_grappin',
        label: 'Aller vers ${target.type.displayName}',
        apply: (before) => before.withPieceMoved(piece.id, landing),
      ));
    }

    // "Attirer": pull the target to the empty cell adjacent to us.
    final pullDest = piece.pos + step;
    if (pullDest != cell &&
        _empty(state, pullDest) &&
        !usedTargets.contains(pullDest) && // avoid tap-collision (distance 2)
        !Passives.isMoveShielded(state, piece, target)) {
      options.add(ActionOption(
        target: pullDest,
        kind: 'lance_grappin',
        label: 'Attirer ${target.type.displayName}',
        apply: (before) => before.withPieceMoved(target.id, pullDest),
      ));
    }
  }
  return options;
}

/// Rôdeuse: move to any empty cell that is not adjacent to an enemy.
List<ActionOption> _rodeuse(GameState state, Piece piece) {
  final enemyCells = state
      .piecesOf(piece.owner.opponent)
      .map((p) => p.pos)
      .toSet();
  final options = <ActionOption>[];
  for (final cell in state.board.cells) {
    if (cell == piece.pos) continue;
    if (state.isOccupied(cell)) continue;
    final adjacentToEnemy =
        enemyCells.any((e) => e.isAdjacentTo(cell));
    if (adjacentToEnemy) continue;
    options.add(ActionOption(
      target: cell,
      kind: 'rodeuse',
      label: 'Infiltration',
      apply: (before) => before.withPieceMoved(piece.id, cell),
    ));
  }
  return options;
}

/// Tavernier: move one adjacent ally by a single cell.
List<ActionOption> _tavernier(GameState state, Piece piece) {
  final options = <ActionOption>[];
  final used = <Hex>{};
  for (final ally in state.piecesOf(piece.owner)) {
    if (ally.id == piece.id) continue;
    if (!ally.pos.isAdjacentTo(piece.pos)) continue;
    for (final dest in ally.pos.neighbors) {
      if (!_empty(state, dest)) continue;
      if (!used.add(dest)) continue; // first ally wins this destination cell
      options.add(ActionOption(
        target: dest,
        kind: 'tavernier',
        label: 'Déplacer ${ally.type.displayName}',
        apply: (before) => before.withPieceMoved(ally.id, dest),
      ));
    }
  }
  return options;
}

/// Manipulatrice: move an enemy that is visible in a straight line and not
/// adjacent, by a single cell (subject to Protecteur).
List<ActionOption> _manipulatrice(GameState state, Piece piece) {
  final options = <ActionOption>[];
  final used = <Hex>{};
  for (final cell in HexGeometry.visiblePieceCells(state, piece.pos)) {
    final target = state.pieceAt(cell)!;
    if (target.owner == piece.owner) continue;
    if (piece.pos.isAdjacentTo(cell)) continue;
    if (Passives.isMoveShielded(state, piece, target)) continue;
    for (final dest in cell.neighbors) {
      if (!_empty(state, dest)) continue;
      if (!used.add(dest)) continue;
      options.add(ActionOption(
        target: dest,
        kind: 'manipulatrice',
        label: 'Manipuler ${target.type.displayName}',
        apply: (before) => before.withPieceMoved(target.id, dest),
      ));
    }
  }
  return options;
}

/// Cogneur: push an adjacent piece one cell straight away (subject to Protecteur
/// for enemies).
List<ActionOption> _cogneur(GameState state, Piece piece) {
  final options = <ActionOption>[];
  for (final dir in Hex.directions) {
    final cell = piece.pos + dir;
    final target = state.pieceAt(cell);
    if (target == null) continue;
    final dest = cell + dir; // straight beyond the target
    if (!_empty(state, dest)) continue;
    if (Passives.isMoveShielded(state, piece, target)) continue;
    options.add(ActionOption(
      target: cell,
      kind: 'cogneur',
      label: 'Repousser ${target.type.displayName}',
      apply: (before) => before.withPieceMoved(target.id, dest),
    ));
  }
  return options;
}

/// Sauteur: jump over an adjacent piece to the empty cell straight beyond it.
List<ActionOption> _sauteur(GameState state, Piece piece) {
  final options = <ActionOption>[];
  for (final dir in Hex.directions) {
    final over = piece.pos + dir;
    if (!state.isOccupied(over)) continue;
    final landing = over + dir;
    if (!_empty(state, landing)) continue;
    options.add(ActionOption(
      target: landing,
      kind: 'sauteur',
      label: 'Saut',
      apply: (before) => before.withPieceMoved(piece.id, landing),
    ));
  }
  return options;
}

/// Garde Royal: shield mechanic not yet specified. TODO: implement once the box
/// rules are known. For now exposes no active option.
List<ActionOption> _gardeRoyalStub(GameState state, Piece piece) => const [];
