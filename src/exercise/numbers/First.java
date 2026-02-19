package exercise.numbers;

import java.util.List;

public class First {

  static final int MAX_ITERATIONS = 10;
  static final List<Integer> BASE_LIST = List.of(1);

  public static List<Integer> run() {
    return run(MAX_ITERATIONS,BASE_LIST);
  }

  public static List<Integer> run(int iterations) {
    return run(iterations,BASE_LIST);
  }

  public static List<Integer> run(List<Integer> intialSequence) {
    return run(MAX_ITERATIONS,intialSequence);
  }

  public static List<Integer> run(int iterations,List<Integer> intialSequence) {
    List<Integer> sequence = intialSequence;
    System.out.println(intialSequence.getFirst());

    for (int iteration = 0; iteration <= iterations; iteration++) {
      IterationResult result = buildNextSequenceAndString(sequence);
      System.out.println(result.asString());
      sequence = result.sequence();
    }
    return sequence;
  }

  private static IterationResult buildNextSequenceAndString(List<Integer> sequence) {
    var next = new java.util.ArrayList<Integer>(sequence.size() * 2);
    var out = new StringBuilder(sequence.size() * 2);

    int index = 0;
    while (index < sequence.size()) {
      int value = sequence.get(index);
      int runLength = 1;

      int j = index + 1;
      while (j < sequence.size() && sequence.get(j) == value) {
        runLength++;
        j++;
      }

      next.add(runLength);
      next.add(value);

      out.append(runLength).append(value);

      index = j;
    }

    return new IterationResult(next, out.toString());
  }

  private record IterationResult(List<Integer> sequence, String asString) {}
}
