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

  void moveBookmark(BookmarkInfo bookmark, String groupTitle) {
    final oldGroupIndex = groups.indexWhere(
      (g) => g.title == bookmark.group.title,
    );
    if (oldGroupIndex >= 0) {
      groups[oldGroupIndex].bookmarks.remove(bookmark);
    }
    final newGroupIndex = groups.indexWhere(
      (g) => g.title == groupTitle,
    );
    if (newGroupIndex >= 0) {
      final newGroup = groups[newGroupIndex];
      bookmark.group = newGroup;
      newGroup.bookmarks.add(bookmark);
    }
  }

  void loadFromStorage() {
    final jsonString = LocalStorageManager.getString(prefKeyData);
    groups = groupsFromJsonString(jsonString, this);
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
}
