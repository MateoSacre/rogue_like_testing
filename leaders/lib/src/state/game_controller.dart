import 'package:flutter/foundation.dart';

import '../engine/game_engine.dart';
import '../logic/action_option.dart';
import '../models/character.dart';
import '../models/game_phase.dart';
import '../models/game_state.dart';
import '../models/hex.dart';
import '../models/piece.dart';

/// Holds the live [GameState] and selection, exposes intent methods to the UI,
/// and maintains an undo stack of prior states.
class GameController extends ChangeNotifier {
  GameController({int radius = 4, int? seed})
      : _radius = radius,
        _seed = seed,
        _state = GameEngine.setupGame(radius: radius, seed: seed);

  final int _radius;
  final int? _seed;

  GameState _state;
  Piece? _selected;
  Map<Hex, ActionOption> _targets = {};
  final List<GameState> _history = [];

  GameState get state => _state;
  Piece? get selected => _selected;
  bool get canUndo => _history.isNotEmpty;

  /// Cells the selected piece can act on (for highlighting).
  Set<Hex> get targetCells => _targets.keys.toSet();

  /// Ids of pieces the current player may still activate (for highlighting).
  Set<String> get selectablePieceIds => {
        for (final p in _state.piecesOf(_state.currentPlayer))
          if (_state.canActivate(p)) p.id,
      };

  void selectPiece(Piece piece) {
    if (!_state.canActivate(piece)) return;
    _selected = piece;
    _targets = {
      for (final opt in GameEngine.legalActions(_state, piece)) opt.target: opt,
    };
    notifyListeners();
  }

  void clearSelection() {
    if (_selected == null) return;
    _selected = null;
    _targets = {};
    notifyListeners();
  }

  /// Handles a tap on board cell [hex] during the action phase.
  void tapHex(Hex hex) {
    if (_state.phase != GamePhase.action) return;

    // Resolve a pending action on a highlighted target first.
    final option = _targets[hex];
    if (_selected != null && option != null) {
      _pushHistory();
      _state = GameEngine.performAction(_state, _selected!, option);
      _selected = null;
      _targets = {};
      notifyListeners();
      return;
    }

    // Otherwise (de)select a piece.
    final piece = _state.pieceAt(hex);
    if (piece != null && _state.canActivate(piece)) {
      selectPiece(piece);
    } else {
      clearSelection();
    }
  }

  void chooseRecruit(CharacterType type) {
    if (_state.phase != GamePhase.recruitment) return;
    if (!_state.river.contains(type)) return;
    _pushHistory();
    _state = GameEngine.doRecruit(_state, type);
    _selected = null;
    _targets = {};
    notifyListeners();
  }

  void undo() {
    if (_history.isEmpty) return;
    _state = _history.removeLast();
    _selected = null;
    _targets = {};
    notifyListeners();
  }

  void newGame({int? seed}) {
    _state = GameEngine.setupGame(radius: _radius, seed: seed ?? _seed);
    _selected = null;
    _targets = {};
    _history.clear();
    notifyListeners();
  }

  void _pushHistory() {
    _history.add(_state);
  }
}
