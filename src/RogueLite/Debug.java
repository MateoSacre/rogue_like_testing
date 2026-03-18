package RogueLite;

public final class Debug {

  public static final boolean TEST_MODE = true;

  private Debug() {}

  public static void log(String area, String message) {
    if (TEST_MODE) {
      System.out.println("[DEBUG][" + area + "] " + message);
    }
  }
}
