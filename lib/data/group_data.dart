import 'dart:convert';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/data/group_info.dart';
import 'package:on_hand/helpers/local_storage_manager.dart';

const prefKeyData = 'data';
const keyGroups = 'g';

class GroupData {
  List<GroupInfo> groups;
  int activeGroupIndex;

  GroupData({
    List<GroupInfo>? groups,
    this.activeGroupIndex = -1,
  }) : groups = groups ?? [];

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

  GroupData clone() {
    return GroupData(
      groups: groups.map((g) => g.clone()).toList(),
      activeGroupIndex: activeGroupIndex,
    );
  }

  void loadGroups() {
    final jsonString = LocalStorageManager.get(prefKeyData);
    setGroupsFromJsonString(jsonString);
  }

  void saveGroups() {
    final jsonString = groupsToJsonString();
    LocalStorageManager.set(prefKeyData, jsonString);
  }

  List<GroupInfo> groupsFromJson(Map<String, dynamic> json) {
    return List<dynamic>.from(json[keyGroups])
        .map((j) => GroupInfo.fromJson(this, j))
        .toList();
  }

  void setGroupsFromJsonString(String? jsonString) {
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      groups = groupsFromJson(json);
    } else {
      groups = [];
    }
    activeGroupIndex = -1;
  }

  Map<String, dynamic> groupsToJson(List<GroupInfo> groups) {
    return {
      keyGroups: groups.map((b) => b.toJson()).toList(),
    };
  }

  String groupsToJsonString() {
    final json = groupsToJson(groups);
    return jsonEncode(json);
  }
}
