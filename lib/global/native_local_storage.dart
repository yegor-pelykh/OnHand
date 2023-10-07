import 'dart:html';

abstract class NativeLocalStorage {
  static final Storage _localStorage = window.localStorage;

  static String? get(String key) {
    return _localStorage[key];
  }

  static void set(String key, String value) {
    _localStorage[key] = value;
  }

  static String? remove(String key) {
    return _localStorage.remove(key);
  }
}
