import 'dart:html';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/data/localization_loader.dart';
import 'package:on_hand/global/global_chrome.dart';
import 'package:on_hand/widgets/onhand_app.dart';
import 'package:on_hand/helpers/device_info.dart';

Future<void> beforeRun() async {
  window.onBeforeUnload.listen((event) => beforeUnload());
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (ChromeCommon.isWebExtension) {
    GlobalChrome.connect();
  }
}

void beforeUnload() {
  if (ChromeCommon.isWebExtension) {
    GlobalChrome.disconnect();
  }
}

Future<void> main() async {
  await beforeRun();
  final defaultLocale = await DeviceInfo.getBrowserLocale();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('uk'),
      ],
      fallbackLocale: const Locale('en'),
      startLocale: defaultLocale,
      path: 'translations',
      assetLoader: LocalizationLoader(),
      child: OnHandApp(),
    ),
  );
}
