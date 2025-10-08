import 'package:flutter/material.dart';

import 'constant/app_colors.dart';
import 'constant/app_strings.dart';

final ThemeData lightTheme =  ThemeData(
  brightness: Brightness.dark,
  primarySwatch: AppColors.colorAccentSwatch,
  scaffoldBackgroundColor: Colors.white,
  fontFamily: AppFontFamily.fontRaleWay,
  // hintColor: AppColors.secondaryBackgroundColor,
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    // color: AppColors.primaryButtonColor
  ),
  appBarTheme: AppBarTheme(
      // backgroundColor: AppColors.scaffoldBackgroundColor,
      shadowColor: Colors.transparent,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontFamily: AppFontFamily.fontRaleWay,
      )
  ),
  textTheme: const TextTheme(bodySmall: TextStyle(color: Colors.white, fontSize: 12), bodyMedium: TextStyle(color: Colors.white, fontSize: 16), bodyLarge: TextStyle(color: Colors.white, fontSize: 20)),
);

// Define the Dark Theme
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.green,
  scaffoldBackgroundColor: Colors.black,
  progressIndicatorTheme: const ProgressIndicatorThemeData(
      // color: AppColors.primaryButtonColor
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
);
