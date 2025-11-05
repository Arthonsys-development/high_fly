import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Utils {

  static bool isEmail(email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  static bool validatePassword(String value){
    String  pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{12,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
  }

  static String formatDateTime(date) {
    if (date == null) return '';

    // Normalize to String
    String raw = date is DateTime ? date.toIso8601String() : date.toString();
    raw = raw.trim();

    // Remove timezone suffix if present (e.g., "+05:30") to allow fallback ISO parsing
    if (raw.contains('+')) {
      raw = raw.split('+')[0];
    }

    DateTime? parsed;

    // 1) Try native ISO parser first
    try {
      parsed = DateTime.parse(raw);
    } catch (_) {
      parsed = null;
    }

    // 2) Try common non-ISO formats when native parse fails
    if (parsed == null) {
      final candidates = <String>[
        'dd/MM/yy',
        'dd/MM/yyyy',
        'MM/dd/yy',
        'MM/dd/yyyy',
        'dd-MM-yy',
        'dd-MM-yyyy',
      ];
      for (final pattern in candidates) {
        try {
          parsed = DateFormat(pattern).parseStrict(raw);
          break;
        } catch (_) {
          // try next
        }
      }
    }

    // If still not parsable, return original string to avoid crashing UI
    if (parsed == null) {
      debugPrint('Utils.formatDateTime: Unparsable date "$raw"');
      return raw;
    }

    final DateFormat dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final String formattedDate = dateFormat.format(parsed);
    debugPrint(formattedDate);
    return formattedDate;
  }


  static String formatDate(DateTime date) {
    String formatted = DateFormat('yyyy-MM-dd').format(date);
    return formatted;
  }

  

}

// Custom formatter that converts input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}