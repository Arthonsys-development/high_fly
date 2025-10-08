//
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/legacy.dart';
//
// final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
//   return ThemeNotifier();
// });
//
// class ThemeNotifier extends StateNotifier<ThemeMode> {
//   ThemeNotifier() : super(ThemeMode.light) {
//     _loadTheme(); // Load theme from local storage on startup
//   }
//
//   void toggleTheme() async {
//     state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool("isDarkMode", state == ThemeMode.dark);
//   }
//
//   Future<void> _loadTheme() async {
//     final prefs = await SharedPreferences.getInstance();
//     final isDarkMode = prefs.getBool("isDarkMode") ?? false;
//     state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
//   }
// }
