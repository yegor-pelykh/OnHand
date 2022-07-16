import 'dart:ui';
import 'package:on_hand/data/group_data.dart';

class GlobalData {
  static GroupData _groupData = GroupData();
  static GroupData get groupData => _groupData;
  static set groupData(GroupData v) {
    _groupData = v;
    activeGroupIndex = _groupData.groups.isNotEmpty ? 0 : -1;
  }

  static int activeGroupIndex = -1;

  static const String dataFileExtension = 'onhand';
  static const Color mainColor = Color.fromRGBO(255, 124, 0, 1);
}
