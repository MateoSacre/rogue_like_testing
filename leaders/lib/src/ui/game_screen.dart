import 'package:flutter/material.dart';

import '../models/game_phase.dart';
import '../state/game_controller.dart';
import 'hex_board_painter.dart';
import 'hex_board_view.dart';
import 'river_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller = GameController();
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }

  void _onChange() {
    if (controller.state.phase == GamePhase.gameOver && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEndDialog());
    }
  }

  Future<void> _showEndDialog() async {
    final winner = controller.state.winner!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Victoire !'),
        content: Text('${winner.label} capture le Leader adverse.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _dialogShown = false;
              controller.newGame();
            },
            child: const Text('Nouvelle partie'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12151C),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final state = controller.state;
            final accent = kPlayerColors[state.currentPlayer]!;
            return Column(
              children: [
                _TopBar(controller: controller, accent: accent),
                Expanded(child: HexBoardView(controller: controller)),
                RiverPanel(controller: controller),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameController controller;
  final Color accent;

  const _TopBar({required this.controller, required this.accent});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF1B1F28),
      child: Row(
        children: [
          CircleAvatar(radius: 8, backgroundColor: accent),
          const SizedBox(width: 8),
          Text(
            state.currentPlayer.label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF262B36),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Phase : ${state.phase.label}  •  Tour ${state.turnNumber}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Annuler',
            onPressed: controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Nouvelle partie',
            onPressed: () => controller.newGame(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
