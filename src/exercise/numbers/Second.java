package exercise.numbers;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

public class Second {

  private static final int MIN_ITERATIONS_INCLUSIVE = 10;
  private static final int MAX_ITERATIONS_EXCLUSIVE = 21;

  private static final int MIN_BASE_VALUE_INCLUSIVE = 1;
  private static final int MAX_BASE_VALUE_EXCLUSIVE = 10;


  public static void run() {
    int iterationCount = ThreadLocalRandom.current()
        .nextInt(MIN_ITERATIONS_INCLUSIVE, MAX_ITERATIONS_EXCLUSIVE);

    List<Integer> baseList = List.of(ThreadLocalRandom.current().nextInt(MIN_BASE_VALUE_INCLUSIVE, MAX_BASE_VALUE_EXCLUSIVE));

    List<Integer> current = First.run(iterationCount, baseList);

    while (current.size() > 1) {
      List<Integer> expanded = expandPairs(current);
      System.out.println(toConcatenatedDigits(expanded));
      current = expanded;
    }
  }

  private static List<Integer> expandPairs(List<Integer> pairs) {
    int size = pairs.size();
    if ((size & 1) != 0) {
      throw new IllegalArgumentException("La séquence doit contenir des paires [compte, valeur]. Taille=" + size);
    }

    int estimatedSize = 0;
    for (int i = 0; i < size; i += 2) {
      estimatedSize += pairs.get(i);
    }

    List<Integer> expanded = new ArrayList<>(Math.max(estimatedSize, 0));
    for (int i = 0; i < size; i += 2) {
      int repeatCount = pairs.get(i);
      int value = pairs.get(i + 1);
      for (int j = 0; j < repeatCount; j++) {
        expanded.add(value);
      }
    }
    return expanded;
  }

  private static String toConcatenatedDigits(List<Integer> values) {
    StringBuilder out = new StringBuilder(values.size() * 2);
    for (Integer v : values) {
      out.append(v);
    }
    return out.toString();
  }
}