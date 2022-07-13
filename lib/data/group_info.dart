import 'dart:typed_data';
import 'package:on_hand/data/bookmark_info.dart';
import 'package:on_hand/data/group_data.dart';

const keyTitle = 't';
const keyBookmarks = 'b';

class GroupInfo {
  GroupData data;
  String title;
  List<BookmarkInfo> bookmarks;

  GroupInfo(
    this.data,
    this.title, {
    List<BookmarkInfo>? bookmarks,
  }) : bookmarks = bookmarks ?? [];

  GroupInfo.fromJson(this.data, Map<String, dynamic> json)
      : title = '',
        bookmarks = [] {
    title = json[keyTitle];
    bookmarks = List<dynamic>.from(json[keyBookmarks])
        .map((j) => BookmarkInfo.fromJson(this, j))
        .toList();
  }

  BookmarkInfo addBookmark(
    Uri url,
    String title,
    Uint8List? icon,
  ) {
    final bookmark = BookmarkInfo(this, url, title, icon);
    bookmarks.add(bookmark);
    return bookmark;
  }

  void moveBookmark(int oldIndex, int newIndex) {
    final BookmarkInfo bookmark = bookmarks.removeAt(oldIndex);
    bookmarks.insert(newIndex, bookmark);
  }

  void removeBookmark(BookmarkInfo bookmark) {
    bookmarks.remove(bookmark);
  }

  GroupInfo clone() {
    return GroupInfo(data, title,
        bookmarks: bookmarks.map((b) => b.clone()).toList());
  }

  Map<String, dynamic> toJson() => {
        keyTitle: title,
        keyBookmarks: bookmarks.map((b) => b.toJson()).toList(),
      };
}
