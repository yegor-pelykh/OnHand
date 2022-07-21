import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/helpers/local_storage_manager.dart';

const prefKeyData = 'data';
const keyGroups = 'g';

class AppData extends ChangeNotifier {
  List<GroupInfo> groups;

  AppData({List<GroupInfo>? groups}) : groups = groups ?? [];

  AppData.clone(AppData other)
      : groups = other.groups.map((g) => g.clone()).toList();

  GroupInfo addGroup(
    String title, {
    List<BookmarkInfo>? bookmarks,
  }) {
    final groupInfo = GroupInfo(
      this,
      title,
      bookmarks: bookmarks ?? [],
    );
    groups.add(groupInfo);
    return groupInfo;
  }

  int? moveBookmark(BookmarkInfo bookmark, String groupTitle) {
    final oldGroupIndex =
        groups.indexWhere((g) => g.title == bookmark.group.title);
    final newGroupIndex = groups.indexWhere((g) => g.title == groupTitle);
    if (oldGroupIndex >= 0 && newGroupIndex >= 0) {
      // remove from old group
      groups[oldGroupIndex].bookmarks.remove(bookmark);
      // add to new group
      final newGroup = groups[newGroupIndex];
      bookmark.group = newGroup;
      newGroup.bookmarks.add(bookmark);
      return newGroupIndex;
    }
    return null;
  }

  void loadFromStorage() {
    groups = groupsFromStorage(this);
  }

  void saveToStorage() {
    final jsonString = groupsToJsonString(groups);
    LocalStorageManager.setString(prefKeyData, jsonString);
  }

  void notifyChanged() => notifyListeners();

  static List<GroupInfo> groupsFromJsonString(
      String? jsonString, AppData appData) {
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      return List<dynamic>.from(json[keyGroups])
          .map((j) => GroupInfo.fromJson(appData, j))
          .toList();
    } else {
      return [];
    }
  }

  static String groupsToJsonString(List<GroupInfo> groups) {
    final json = {
      keyGroups: groups.map((b) => b.toJson()).toList(),
    };
    return jsonEncode(json);
  }

  static List<GroupInfo> groupsFromStorage(AppData appData) {
    final jsonString = LocalStorageManager.getString(prefKeyData);
    return groupsFromJsonString(jsonString, appData);
  }

  static bool groupsEqual(List<GroupInfo> l1, List<GroupInfo> l2) {
    if (l1.length != l2.length) {
      return false;
    }
    for (var i = 0; i < l1.length; i++) {
      if (!GroupInfo.equals(l1[i], l2[i])) {
        return false;
      }
    }
    return true;
  }
}
