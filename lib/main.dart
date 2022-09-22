import 'dart:convert';
import 'dart:html';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_theme/json_theme.dart';
import 'package:on_hand/global/global_chrome.dart';
import 'package:on_hand/widgets/onhand_app.dart';
import 'package:on_hand/data/localization_loader.dart';
import 'package:on_hand/helpers/device_info.dart';

Future<ThemeData?> _loadJsonTheme(String path) async {
  final themeStr = await rootBundle.loadString(path);
  final themeJson = jsonDecode(themeStr);
  return ThemeDecoder.decodeThemeData(themeJson);
}

Future<void> beforeRun() async {
  window.onBeforeUnload.listen((event) => beforeUnload());
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  GlobalChrome.connect();
}

void beforeUnload() {
  GlobalChrome.disconnect();
}

Future<void> main() async {
  await beforeRun();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('uk'),
      ],
      fallbackLocale: const Locale('en'),
      startLocale: await DeviceInfo.getBrowserLocale(),
      path: 'translations',
      assetLoader: LocalizationLoader(),
      child: OnHandApp(
        lightTheme: await _loadJsonTheme('themes/theme_light.json'),
        darkTheme: await _loadJsonTheme('themes/theme_dark.json'),
      ),
    ),
  );
}
