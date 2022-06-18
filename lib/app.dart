import 'package:flutter/material.dart';
import 'package:on_hand/widgets/home_page.dart';
import 'dart:html' as html;

class OnHandApp extends StatelessWidget {
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;

  OnHandApp({
    super.key,
    this.lightTheme,
    this.darkTheme,
  }) {
    html.document.body!.addEventListener('contextmenu', (event) {
      event.preventDefault();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnHand',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
