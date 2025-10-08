import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class Utils{

  static formatDateTime(date) {
    date = date.split('+')[0];
    DateTime dateTime = DateTime.parse(date);
    DateFormat dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    String formattedDate = dateFormat.format(dateTime);
    debugPrint(formattedDate);
    return formattedDate;
  }

}