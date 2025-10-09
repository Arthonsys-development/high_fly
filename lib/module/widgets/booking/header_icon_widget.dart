import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';

class HeaderIconWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const HeaderIconWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(0, 240, 89, 34),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 35,
            color: AppColors.primaryColor,
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
