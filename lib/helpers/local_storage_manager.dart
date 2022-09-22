import 'dart:html';

abstract class LocalStorageManager {
  static final _localStorage = window.localStorage;

  static String? getString(String key) {
    return _localStorage[key];
  }

  static void setString(String key, String value) {
    _localStorage[key] = value;
  }

  static void remove(String key) {
    _localStorage.remove(key);
  }
}
