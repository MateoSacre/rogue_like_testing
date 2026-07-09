import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/game_phase.dart';
import '../state/game_controller.dart';
import 'hex_board_painter.dart';

/// The draft river: 3 face-up character cards. Tappable during the recruitment
/// phase of the current player.
class RiverPanel extends StatelessWidget {
  final GameController controller;

  const RiverPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final recruiting = state.phase == GamePhase.recruitment;
    final accent = kPlayerColors[state.currentPlayer]!;

    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1B1F28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Rivière de recrutement',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              if (recruiting)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.currentPlayer.label} recrute (${state.pendingRecruits})',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final type in state.river)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Card(
                      title: type.displayName,
                      token: type.token,
                      enabled: recruiting,
                      accent: accent,
                      stub: type.isStub,
                      onTap: recruiting
                          ? () => controller.chooseRecruit(type)
                          : null,
                    ),
                  ),
                ),
              if (state.river.isEmpty)
                const Expanded(
                  child: Text('Pioche épuisée',
                      style: TextStyle(color: Colors.white38)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String token;
  final bool enabled;
  final bool stub;
  final Color accent;
  final VoidCallback? onTap;

  const _Card({
    required this.title,
    required this.token,
    required this.enabled,
    required this.stub,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF262B36),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? accent : const Color(0xFF394150),
              width: enabled ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(token,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                stub ? '$title (TODO)' : title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
