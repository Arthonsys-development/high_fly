import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';

class CustomFormField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool isRequired;
  final bool showDropdownIcon;
  final Widget? suffixIcon;

  const CustomFormField({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.isRequired = false,
    this.showDropdownIcon = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.headingTextColor,
            ),
            children: isRequired
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.lightGreyBorderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select $label',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null 
                          ? AppColors.headingTextColor 
                          : AppColors.lightGreyColor,
                    ),
                  ),
                ),
                if (showDropdownIcon && suffixIcon == null)
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.lightGreyColor,
                    size: 20,
                  )
                else if (suffixIcon != null)
                  suffixIcon!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
