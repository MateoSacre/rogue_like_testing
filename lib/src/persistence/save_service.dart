import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/battle_controller.dart';
import '../progression/player_progress.dart';
import '../settings/game_settings.dart';

class SaveService {
  const SaveService._();

  static const fileName = 'roguelite_save.json';

  // Web has no filesystem access; the save is stored under this key in
  // browser local storage via shared_preferences instead.
  static const _webPrefsKey = 'roguelite_save';

  /// Test hook: when set, the save file lives in this directory instead of
  /// the platform application-support directory. Tests MUST set this so they
  /// never read or overwrite the real player save.
  static Directory? directoryOverride;

  // All writes are chained onto this future, guaranteeing sequential execution.
  static Future<void> _queue = Future.value();

  // Cached once resolved; the platform directory never changes at runtime.
  static File? _platformFile;

  static Future<File> _file() async {
    final override = directoryOverride;
    if (override != null) {
      return File('${override.path}${Platform.pathSeparator}$fileName');
    }
    if (_platformFile != null) return _platformFile!;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await _migrateLegacySave(file);
    _platformFile = file;
    return file;
  }

  /// Older builds wrote the save in the current working directory, which is
  /// unreliable (depends on how the app is launched, unwritable on mobile).
  /// Move such a save to the stable per-user location, once.
  static Future<void> _migrateLegacySave(File target) async {
    try {
      final legacy = File(fileName);
      if (await legacy.exists() && !await target.exists()) {
        await target.writeAsString(await legacy.readAsString());
        await legacy.delete();
      }
    } catch (_) {
      // Best effort: if migration fails, the game starts on a fresh save.
    }
  }

  static Future<Map<String, dynamic>?> load() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_webPrefsKey);
        if (raw == null) return null;
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
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
    // Chain onto the queue: the next write only starts when the previous one
    // finishes. The caller still observes a failure on the returned future,
    // but a failed write must not poison the queue for later saves.
    final write = _queue.then((_) async {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_webPrefsKey, encoded);
        return;
      }
      final file = await _file();
      await file.writeAsString(encoded);
    });
    _queue = write.then((_) {}, onError: (_) {});
    return write;
  }

  /// Waits for any in-progress write to complete.
  /// Call this on app lifecycle pause/detach to avoid truncated saves.
  static Future<void> flush() => _queue;
}
