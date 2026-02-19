package RogueLite;

import RogueLite.battle.test.BattleTest;
import RogueLite.characters.skills.test.SkillTest;
import RogueLite.characters.test.CharacterTest;
import RogueLite.teams.test.TeamTest;
import RogueLite.waves.test.WavesGeneratorTest;

public class GlobalTests {
  public static void main(String[] args) {
    CharacterTest.run();
    TeamTest.run();
    BattleTest.run();
    WavesGeneratorTest.run();
    SkillTest.run();
  }
}
