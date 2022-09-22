import 'dart:math';

abstract class Utils {
  static final Random _randomGenerator = Random();

  static String generateUUID() {
    String o2() => ((1 + _randomGenerator.nextDouble()) * 0x10000)
        .floor()
        .toRadixString(16)
        .substring(1);
    return '${o2()}${o2()}-${o2()}-${o2()}-${o2()}-${o2()}${o2()}${o2()}';
  }
}
