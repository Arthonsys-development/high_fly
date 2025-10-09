import 'package:flutter/material.dart';

import '../../../config/constant/app_colors.dart';

Widget commonAppBar(context, title, {VoidCallback? onBack}) {
  return AppBar(
    title: Text(title),
    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: AppColors.primaryTextColor),
      onPressed: onBack ?? () => Navigator.of(context).pop(),
    ),
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(color: AppColors.primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: AppColors.primaryTextColor), // Ensures back button and other icons are of this color
    centerTitle: true, // Centers the title
    elevation: 1, // Adds a subtle shadow below the AppBar
  );
}