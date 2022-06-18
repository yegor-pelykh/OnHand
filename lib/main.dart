import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_theme/json_theme.dart';
import 'package:on_hand/app.dart';

Future<ThemeData?> _loadJsonTheme(String path) async {
  final themeStr = await rootBundle.loadString(path);
  final themeJson = jsonDecode(themeStr);
  return ThemeDecoder.decodeThemeData(themeJson);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(OnHandApp(
    lightTheme: await _loadJsonTheme('assets/theme_light.json'),
    darkTheme: await _loadJsonTheme('assets/theme_dark.json'),
  ));
}
