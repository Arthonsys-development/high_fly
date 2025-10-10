import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';

class HeaderIconWidget extends StatelessWidget {
  final String icon;
  final String title;
  final Color? bgColor;
  final Color? iconColor;
  final String subtitle;

  const HeaderIconWidget({
    super.key,
    required this.icon,
    required this.title,
    this.bgColor,
    this.iconColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: bgColor ?? AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(0, 240, 89, 34),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(icon, color: iconColor ?? AppColors.primaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.headingTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.darkGreyColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
