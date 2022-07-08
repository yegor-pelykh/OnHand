import 'dart:html';

class LocalStorageManager {
  static final _localStorage = window.localStorage;

  static String? get(String key) {
    return _localStorage[key];
  }

  static void set(String key, String value) {
    _localStorage[key] = value;
  }

  static void remove(String key) {
    _localStorage.remove(key);
  }
}
