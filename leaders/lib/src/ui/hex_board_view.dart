import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import 'hex_board_painter.dart';
import 'hex_layout.dart';

/// Interactive hex board: renders the state and forwards taps to the controller.
class HexBoardView extends StatelessWidget {
  final GameController controller;

  const HexBoardView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = HexLayout.fit(state.board, size);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final hex = layout.pixelToHex(details.localPosition);
            if (state.board.contains(hex)) {
              controller.tapHex(hex);
            } else {
              controller.clearSelection();
            }
          },
          child: CustomPaint(
            size: size,
            painter: HexBoardPainter(
              state: state,
              layout: layout,
              selectedId: controller.selected?.id,
              targetCells: controller.targetCells,
              selectableIds: controller.selectablePieceIds,
            ),
          ),
        );
      },
    );
  }
}
