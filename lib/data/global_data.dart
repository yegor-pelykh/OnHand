import 'package:on_hand/data/group_data.dart';
import 'package:on_hand/data/update_notifier.dart';

class GlobalData {
  static const String dataFileExtension = 'onhand';

  static GroupData groupData = GroupData();
  static UpdateNotifier updateNotifier = UpdateNotifier();
}
