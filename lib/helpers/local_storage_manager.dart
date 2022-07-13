import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

class LocalStorageManager {
  static final _localStorage = window.localStorage;

  static String? getString(String key) {
    return _localStorage[key];
  }

  static void setString(String key, String value) {
    _localStorage[key] = value;
  }

  static Uint8List? getBytes(String key) {
    final str = _localStorage[key];
    return str != null ? base64Decode(str) : null;
  }

  static void setBytes(String key, Uint8List value) {
    _localStorage[key] = base64Encode(value);
  }

  static void remove(String key) {
    _localStorage.remove(key);
  }
}
