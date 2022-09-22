import 'dart:ui';
import 'package:on_hand/data/app_data.dart';

abstract class GlobalData {
  static final AppData _appData = AppData();
  static AppData get appData => _appData;

  static const String dataFileExtension = 'onhand';
  static const Color mainColor = Color.fromRGBO(255, 124, 0, 1);
}
