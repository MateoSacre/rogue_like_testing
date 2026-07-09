import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/game_state.dart';
import '../models/hex.dart';
import '../models/piece.dart';
import '../models/player.dart';
import 'hex_layout.dart';

/// Player colours used across the board UI.
const Map<PlayerId, Color> kPlayerColors = {
  PlayerId.one: Color(0xFF2E6FDB), // blue
  PlayerId.two: Color(0xFFD8493B), // red
};

class HexBoardPainter extends CustomPainter {
  final GameState state;
  final HexLayout layout;
  final String? selectedId;
  final Set<Hex> targetCells;
  final Set<String> selectableIds;

  HexBoardPainter({
    required this.state,
    required this.layout,
    required this.selectedId,
    required this.targetCells,
    required this.selectableIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellFill = Paint()..style = PaintingStyle.fill;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF394150);

    final home1 = state.board.recruitCells(PlayerId.one).toSet();
    final home2 = state.board.recruitCells(PlayerId.two).toSet();

    // Cells.
    for (final h in state.board.cells) {
      final path = _hexPath(h);
      if (targetCells.contains(h)) {
        cellFill.color = const Color(0xFF2E7D32); // green target
      } else if (home1.contains(h)) {
        cellFill.color = const Color(0xFF1E2A44);
      } else if (home2.contains(h)) {
        cellFill.color = const Color(0xFF3A1E24);
      } else {
        cellFill.color = const Color(0xFF262B36);
      }
      canvas.drawPath(path, cellFill);
      canvas.drawPath(path, border);
    }

    // Pieces.
    for (final piece in state.allPieces) {
      _drawPiece(canvas, piece);
    }
  }

  Path _hexPath(Hex h) {
    final c = layout.corners(h);
    final path = Path()..moveTo(c[0].dx, c[0].dy);
    for (var i = 1; i < c.length; i++) {
      path.lineTo(c[i].dx, c[i].dy);
    }
    return path..close();
  }

  void _drawPiece(Canvas canvas, Piece piece) {
    final center = layout.hexToPixel(piece.pos);
    final radius = layout.size * 0.62;
    final base = kPlayerColors[piece.owner]!;

    // Selectable glow / selected ring.
    if (piece.id == selectedId) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.amberAccent,
      );
    } else if (selectableIds.contains(piece.id)) {
      canvas.drawCircle(
        center,
        radius + 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white70,
      );
    }

    canvas.drawCircle(center, radius, Paint()..color = base);
    if (piece.isLeader) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.amber,
      );
    }

    final tp = TextPainter(
      text: TextSpan(
        text: piece.type.token,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * (piece.isLeader ? 1.1 : 0.8),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant HexBoardPainter old) =>
      old.state != state ||
      old.selectedId != selectedId ||
      old.targetCells != targetCells ||
      old.selectableIds != selectableIds ||
      old.layout.size != layout.size ||
      old.layout.origin != layout.origin;
}
