import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../utils/app_fonts.dart';

class PaymentTextField extends StatelessWidget {
  final String label;
  final String? value;
  final String? hintText;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Widget? suffixIcon;
  final TextEditingController? controller;

  const PaymentTextField({
    super.key,
    required this.label,
    this.value,
    this.hintText,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with required indicator
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.getFont(
                weight: AppFonts.medium,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: SizedBox(
                  width: 5,
                  height: 5,
                  child: Image.asset(IconsAssets.star, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        
        // Text field
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.black26,
                width: 1,
              ),
            ),
            child: onTap != null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value ?? hintText ?? 'Select $label',
                            style: TextStyle(
                              fontSize: 14,
                              color: value != null 
                                  ? Colors.black 
                                  : AppColors.secondaryTextColor,
                            ),
                          ),
                        ),
                        if (suffixIcon != null) suffixIcon!,
                      ],
                    ),
                  )
                : TextField(
                    controller: controller ?? TextEditingController(text: value),
                    onChanged: onChanged,
                    keyboardType: keyboardType,
                    maxLines: maxLines,
                    cursorColor: AppColors.primaryTextColor,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: AppColors.primaryTextColor,
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Colors.black26,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: AppColors.primaryTextColor,
                          width: 1,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.textFieldBGColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: suffixIcon,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
