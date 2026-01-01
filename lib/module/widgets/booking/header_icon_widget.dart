import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    final iconSize = kIsWeb ? 90.0 : 70.0;
    final iconPadding = kIsWeb ? 18.0 : 12.0;
    final titleSize = kIsWeb ? 26.0 : 20.0;
    final subtitleSize = kIsWeb ? 16.0 : 14.0;
    final spacing = kIsWeb ? 20.0 : 16.0;
    final subtitleSpacing = kIsWeb ? 10.0 : 8.0;

    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: bgColor ?? AppColors.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: kIsWeb 
                  ? (iconColor ?? AppColors.primaryColor).withValues(alpha: 0.2)
                  : const Color.fromARGB(0, 240, 89, 34),
              width: kIsWeb ? 2.5 : 2,
            ),
            boxShadow: kIsWeb ? [
              BoxShadow(
                color: (iconColor ?? AppColors.primaryColor).withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(iconPadding),
            child: Image.asset(icon, color: iconColor ?? AppColors.primaryColor),
          ),
        ),
        SizedBox(height: spacing),
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: AppColors.headingTextColor,
            letterSpacing: kIsWeb ? -0.5 : 0,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: subtitleSpacing),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: subtitleSize,
            color: AppColors.darkGreyColor,
            fontWeight: kIsWeb ? FontWeight.w400 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
