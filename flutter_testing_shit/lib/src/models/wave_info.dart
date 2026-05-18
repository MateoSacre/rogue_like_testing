import 'enums.dart';
import 'team.dart';

class WaveInfo {
  WaveInfo({
    required this.team,
    required this.category,
    required this.finalWaveInTheme,
  });

  final Team team;
  final MobCategory category;
  final bool finalWaveInTheme;
}
