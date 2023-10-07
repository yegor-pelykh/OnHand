import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:on_hand/data/group.dart';

const keyUrl = 'u';
const keyTitle = 't';
const keyIcon = 'i';

class Bookmark extends ChangeNotifier {
  Group _group;
  Group get group => _group;
  set group(Group v) {
    if (_group != v) {
      _group = v;
      notifyListeners();
    }
  }

  Uri _url;
  Uri get url => _url;
  set url(Uri v) {
    if (_url != v) {
      _url = v;
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

  Uint8List? _icon;
  Uint8List? get icon => _icon;
  set icon(Uint8List? v) {
    if (!_byteListsEqualN(_icon, v)) {
      _icon = v;
      notifyListeners();
    }
  }

  Map<String, dynamic> get json => {
        keyUrl: url.toString(),
        keyTitle: title,
        keyIcon: icon != null ? base64.encode(icon!) : null,
      };

  Bookmark(this._group, this._url, this._title, this._icon);

  Bookmark.fromJson(this._group, Map<String, dynamic> json)
      : _url = Uri.parse(json[keyUrl]),
        _title = json[keyTitle],
        _icon = json[keyIcon] != null ? base64.decode(json[keyIcon]) : null;

  Bookmark clone(Group parentGroup) => Bookmark(parentGroup, url, title, icon);

  static bool _byteListsEqual(Uint8List ul1, Uint8List ul2) {
    if (identical(ul1, ul2)) {
      return true;
    }
    if (ul1.lengthInBytes != ul2.lengthInBytes) {
      return false;
    }
    // Treat the original byte lists as lists of 4-byte words.
    final numWords = ul1.lengthInBytes ~/ 4;
    final words1 = ul1.buffer.asUint32List(0, numWords);
    final words2 = ul2.buffer.asUint32List(0, numWords);
    for (var i = 0; i < words1.length; i += 1) {
      if (words1[i] != words2[i]) {
        return false;
      }
    }
    // Compare any remaining bytes.
    for (var i = words1.lengthInBytes; i < ul1.lengthInBytes; i += 1) {
      if (ul1[i] != ul2[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _byteListsEqualN(Uint8List? ul1, Uint8List? ul2) {
    if ((ul1 != null && ul2 == null) || (ul1 == null && ul2 != null)) {
      return false;
    }
    if (ul1 != null && ul2 != null && !_byteListsEqual(ul1, ul2)) {
      return false;
    }
    return true;
  }

  static bool equals(Bookmark b1, Bookmark b2) {
    if (b1.title != b2.title) {
      return false;
    }
    if (b1.url != b2.url) {
      return false;
    }
    return _byteListsEqualN(b1.icon, b2.icon);
  }
}
