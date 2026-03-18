package RogueLite.waves;

import RogueLite.characters.mobs.MobCategory;
import RogueLite.teams.Team;

public record ThemedWave(Team team, MobCategory category, boolean finalWaveInTheme) {}
