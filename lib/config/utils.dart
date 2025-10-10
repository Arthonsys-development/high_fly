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
    date = date.split('+')[0];
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    String formattedDate = dateFormat.format(dateTime);
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