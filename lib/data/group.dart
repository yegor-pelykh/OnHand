import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:on_hand/data/bookmark.dart';
import 'package:on_hand/data/group_storage.dart';

const keyTitle = 't';
const keyBookmarks = 'b';

class Group extends ChangeNotifier {
  GroupStorage _storage;
  GroupStorage get storage => _storage;
  set storage(GroupStorage v) {
    if (_storage != v) {
      _storage = v;
      notifyListeners();
    }
  }

  String _title;
  String get title => _title;
  set title(String v) {
    if (_title != v) {
      _title = v;
      notifyListeners();
    }
  }

  List<Bookmark> _bookmarks;
  List<Bookmark> get bookmarks => _bookmarks;

  Map<String, dynamic> get json => {
        keyTitle: title,
        keyBookmarks: bookmarks.map((b) => b.json).toList(),
      };

  void _handleBookmarkChange() {
    notifyListeners();
  }

  Group(
    this._storage,
    this._title, {
    List<Bookmark>? bookmarks,
  }) : _bookmarks = bookmarks ?? [] {
    for (final b in _bookmarks) {
      b.addListener(_handleBookmarkChange);
    }
  }

  Group.fromJson(GroupStorage storage, Map<String, dynamic> json)
      : _storage = storage,
        _title = '',
        _bookmarks = [] {
    title = json[keyTitle];
    replaceAllBookmarks(List<dynamic>.from(json[keyBookmarks])
        .map((j) => Bookmark.fromJson(this, j))
        .toList());
  }

  Bookmark addBookmark(
    Uri url,
    String title,
    Uint8List? icon,
  ) {
    final bookmark = Bookmark(this, url, title, icon);
    _bookmarks.add(bookmark);
    bookmark.addListener(_handleBookmarkChange);
    notifyListeners();
    return bookmark;
  }

  void moveBookmark(int oldIndex, int newIndex) {
    final Bookmark bookmark = _bookmarks.removeAt(oldIndex);
    _bookmarks.insert(newIndex, bookmark);
    notifyListeners();
  }

  void removeBookmark(Bookmark bookmark) {
    bookmark.removeListener(_handleBookmarkChange);
    _bookmarks.remove(bookmark);
    notifyListeners();
  }

  void replaceAllBookmarks(List<Bookmark> b) {
    if (!_bookmarksEqual(_bookmarks, b)) {
      for (var b in _bookmarks) {
        b.removeListener(_handleBookmarkChange);
      }
      _bookmarks = b;
      for (var b in _bookmarks) {
        b.addListener(_handleBookmarkChange);
      }
      notifyListeners();
    }
  }

  Group clone(GroupStorage storage) {
    final group = Group(storage, title);
    group.replaceAllBookmarks(_bookmarks.map((b) => b.clone(group)).toList());
    return group;
  }

  static bool _bookmarksEqual(List<Bookmark> b1, List<Bookmark> b2) {
    if (b1.length != b2.length) {
      return false;
    }
    for (var i = 0; i < b1.length; i++) {
      if (!Bookmark.equals(b1[i], b2[i])) {
        return false;
      }
    }
    return true;
  }

  static bool equals(Group g1, Group g2) {
    if (g1.title != g2.title) {
      return false;
    }
    return _bookmarksEqual(g1.bookmarks, g2.bookmarks);
  }
}
