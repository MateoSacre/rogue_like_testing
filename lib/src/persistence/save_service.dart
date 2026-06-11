import 'dart:convert';
import 'dart:io';

import '../game/battle_controller.dart';
import '../progression/player_progress.dart';
import '../settings/game_settings.dart';

class SaveService {
  const SaveService._();

  static const fileName = 'roguelite_save.json';

  static File get _file => File(fileName);

  // All writes are chained onto this future, guaranteeing sequential execution.
  static Future<void> _queue = Future.value();

  static Future<Map<String, dynamic>?> load() async {
    try {
      if (!await _file.exists()) return null;
      final raw = await _file.readAsString();
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required GameSettings settings,
    required PlayerProgress progress,
    BattleController? battle,
    Map<String, dynamic>? battleJson,
  }) {
    final payload = <String, dynamic>{
      'settings': settings.toJson(),
      'progression': progress.toJson(),
    };
    final savedBattle = battle?.toJson() ?? battleJson;
    if (savedBattle != null) {
      payload['battle'] = savedBattle;
    }
    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    // Chain onto the queue: the next write only starts when the previous one finishes.
    return _queue = _queue.then((_) => _file.writeAsString(encoded));
  }

  /// Waits for any in-progress write to complete.
  /// Call this on app lifecycle pause/detach to avoid truncated saves.
  static Future<void> flush() => _queue;
}
