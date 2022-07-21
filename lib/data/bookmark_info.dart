import 'dart:convert';
import 'dart:typed_data';
import 'package:on_hand/data/group_info.dart';

const keyUrl = 'u';
const keyTitle = 't';
const keyIcon = 'i';

class BookmarkInfo {
  GroupInfo group;
  Uri url;
  String title;
  Uint8List? icon;

  BookmarkInfo(this.group, this.url, this.title, this.icon);

  BookmarkInfo.fromJson(this.group, Map<String, dynamic> json)
      : url = Uri.parse(json[keyUrl]),
        title = json[keyTitle],
        icon = json[keyIcon] != null ? base64.decode(json[keyIcon]) : null;

  BookmarkInfo clone() {
    return BookmarkInfo(group, url, title, icon);
  }

  Map<String, dynamic> toJson() => {
        keyUrl: url.toString(),
        keyTitle: title,
        keyIcon: icon != null ? base64.encode(icon!) : null,
      };

  static bool equals(BookmarkInfo b1, BookmarkInfo b2) {
    if (b1.title != b2.title) {
      return false;
    }
    if (b1.url != b2.url) {
      return false;
    }
    if ((b1.icon != null && b2.icon == null) ||
        (b1.icon == null && b2.icon != null)) {
      return false;
    }
    if (b1.icon != null &&
        b2.icon != null &&
        !byteListsEqual(b1.icon!, b2.icon!)) {
      return false;
    }
    return true;
  }

  static bool byteListsEqual(Uint8List ul1, Uint8List ul2) {
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
}
