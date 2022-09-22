/// The abstract superclass of Chrome enums.
abstract class ChromeEnum {
  final String value;

  const ChromeEnum(this.value);

  @override
  String toString() => value;
}
