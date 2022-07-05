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
}
