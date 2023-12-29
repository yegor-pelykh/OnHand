import 'dart:async';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/data/bookmark.dart';
import 'package:on_hand/data/group.dart';
import 'package:on_hand/data/group_storage.dart';
import 'package:on_hand/chrome_bridge/chrome_storage.dart';
import 'package:on_hand/global/native_local_storage.dart';

const keyData = 'data';

abstract class GlobalData {
  static final GroupStorage groupStorage = GroupStorage();
  static StreamSubscription<StorageOnChangedEvent>? _storageChangeSubscription;

  static void _storageChangeListener(StorageOnChangedEvent event) {
    if (event.areaName == 'local') {
      final dataChanges = event.changes[keyData];
      if (dataChanges != null && dataChanges.newValue is String) {
        final jsonString = dataChanges.newValue;
        groupStorage.replaceFromJson(jsonString);
      }
    }
  }

  static subscribeToStorageChange() {
    if (ChromeCommon.isWebExtension) {
      _storageChangeSubscription =
          ChromeStorage.onChanged.listen(_storageChangeListener);
    }
  }

  static unsubscribeFromStorageChange() {
    if (_storageChangeSubscription != null) {
      _storageChangeSubscription!.cancel();
    }
  }

  static Future<void> loadFromStorage() async {
    if (ChromeCommon.isWebExtension) {
      final results = await ChromeStorage.local.get(keyData);
      if (results.containsKey(keyData)) {
        groupStorage.replaceFromJson(results[keyData]);
      } else {
        groupStorage.replaceByDefault();
      }
    } else {
      final data = NativeLocalStorage.get(keyData);
      if (data != null) {
        groupStorage.replaceFromJson(data);
      } else {
        groupStorage.replaceByDefault();
      }
    }
  }

  static Future<void> saveToStorage() async {
    if (ChromeCommon.isWebExtension) {
      await ChromeStorage.local.set({
        keyData: groupStorage.json,
      });
    } else {
      NativeLocalStorage.set(keyData, groupStorage.json);
    }
  }

  static int moveBookmarkToGroup(Bookmark bookmark, Group toGroup) {
    // remove from old group
    final oldGroup = bookmark.group;
    oldGroup.removeBookmark(bookmark);
    // add to new group
    toGroup.addBookmark(bookmark.url, bookmark.title, bookmark.icon);
    return groupStorage.indexOf(toGroup);
  }
}
