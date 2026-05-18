import 'dart:convert';
import 'dart:io';

import '../game/battle_controller.dart';
import '../progression/player_progress.dart';
import '../settings/game_settings.dart';

class SaveService {
  const SaveService._();

  static const fileName = 'roguelite_save.json';

  static File get _file => File(fileName);

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
  }) async {
    final payload = <String, dynamic>{
      'settings': settings.toJson(),
      'progression': progress.toJson(),
    };
    final savedBattle = battle?.toJson() ?? battleJson;
    if (savedBattle != null) {
      payload['battle'] = savedBattle;
    }
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }
}
