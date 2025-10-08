import 'package:flutter/material.dart';

/// Simple font utility for Poppins font family
class AppFonts {
  AppFonts._();

  // Font family
  // static const String poppins = 'Poppins';

  // Font weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Get TextStyle with Poppins font and specified weight
  static TextStyle getFont({
    FontWeight weight = regular,
    double? fontSize,
    Color? color,
  }) {
    return TextStyle(
      // fontFamily: poppins,
      fontWeight: weight,
      fontSize: fontSize,
      color: color,
    );
  }
}