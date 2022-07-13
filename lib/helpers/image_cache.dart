import 'dart:typed_data';
import 'package:on_hand/helpers/local_storage_manager.dart';

const keyPrefix = 'c-';

class ImageCache {
  static String generateUniqueId() => DateTime.now().microsecondsSinceEpoch.toString();

  static String keyFromId(String id) => '$keyPrefix$id';

  static String put(Uint8List data) {
    final id = generateUniqueId();
    LocalStorageManager.setBytes(keyFromId(id), data);
    return id;
  }

  static Uint8List? get(String id) => LocalStorageManager.getBytes(keyFromId(id));

  static void remove(String id) => LocalStorageManager.remove(keyFromId(id));
}
