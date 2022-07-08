import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class LocalizationLoader extends AssetLoader {
  String _getLocalePath(String basePath, Locale locale) {
    return '$basePath/${locale.languageCode}.json';
  }

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final localePath = _getLocalePath(path, locale);
    return jsonDecode(await rootBundle.loadString(localePath));
  }
}
