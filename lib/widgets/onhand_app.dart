import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_hand/global/app_color_scheme.dart';
import 'package:on_hand/widgets/home_page.dart';
import 'dart:html' as p_html;

class OnHandApp extends StatelessWidget {
  OnHandApp({super.key}) {
    p_html.document.body!.addEventListener('contextmenu', (event) {
      event.preventDefault();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'OnHand',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColorScheme.light,
        dialogBackgroundColor: AppColorScheme.light.surface,
        scaffoldBackgroundColor: AppColorScheme.light.surface,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColorScheme.light.surface,
          modalBackgroundColor: AppColorScheme.light.surface,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColorScheme.dark,
        dialogBackgroundColor: AppColorScheme.dark.surface,
        scaffoldBackgroundColor: AppColorScheme.dark.surface,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColorScheme.dark.surface,
          modalBackgroundColor: AppColorScheme.dark.surface,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
