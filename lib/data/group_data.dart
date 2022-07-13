import 'dart:convert';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/helpers/local_storage_manager.dart';

const prefKeyData = 'data';
const keyGroups = 'g';

class GroupData {
  List<GroupInfo> groups;

  GroupData({List<GroupInfo>? groups}) : groups = groups ?? [];

  GroupData.clone(GroupData other) : groups = other.groups.map((g) => g.clone()).toList();

  GroupData.fromJsonString(String? jsonString) : groups = [] {
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      groups = List<dynamic>.from(json[keyGroups]).map((j) => GroupInfo.fromJson(this, j)).toList();
    }
  }

  GroupData.fromStorage() : groups = [] {
    final jsonString = LocalStorageManager.getString(prefKeyData);
    GroupData.fromJsonString(jsonString);
  }

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

  String toJsonString() {
    final json = groupsToJson(groups);
    return jsonEncode(json);
  }

  void saveToStorage() {
    final jsonString = toJsonString();
    LocalStorageManager.setString(prefKeyData, jsonString);
  }

  static Map<String, dynamic> groupsToJson(List<GroupInfo> groups) {
    return {
      keyGroups: groups.map((b) => b.toJson()).toList(),
    };
  }
}
