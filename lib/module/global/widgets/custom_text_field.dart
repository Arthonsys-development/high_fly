import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highfly/config/constant/const_assets.dart';

import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final String? titleText;
  final TextStyle? labelStyle;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool isMandatory;
  final double? height;
  final bool showTitle;
  final List<TextInputFormatter>? inputFormatters;
  final double borderRadius;
  final double? contentSpace;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    this.hintText,
    this.titleText,
    this.labelStyle,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.isMandatory = false,
    this.height = 40,
    this.showTitle = true,
    this.inputFormatters,
    this.borderRadius = 0,
    this.contentSpace,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration buildDecoration() {
      // Adjust vertical padding dynamically
      final verticalPadding = height != null ? (height! / 2.8) - 4 : 15.0;

      return InputDecoration(
        hintText: hintText,
        counterText: '',
        prefixIcon: prefixIcon,
        counter: null,
        hintStyle: const TextStyle(
          color: AppColors.secondaryTextColor,
          fontSize: 14,
        ),
        suffixIcon: suffixIcon,
        fillColor: AppColors.textFieldBGColor,
        filled: true,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 5,
          vertical: verticalPadding,
        ),
        // Default border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryTextColor,
            width: 0.5, // Thickness of the border
          ),
        ),
        // Border when enabled but not focused
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: Colors.black26,
            width: 1,
          ),
        ),
        // Border when focused
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryTextColor,
            width: 1,
          ),
        ),
        // Border when error occurs
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            // color: AppColors.error,
            width: 1.2,
          ),
        ),
        // Border when focused and error occurs
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            // color: AppColors.error,
            width: 1.5,
          ),
        ),
      );
    }

    Widget textField = TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      cursorColor: AppColors.primaryTextColor,
      inputFormatters: inputFormatters,
      onChanged: onChanged, // ✅ Pass the callback
      decoration: buildDecoration(),
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle && titleText != null && titleText!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText!,
                style: labelStyle ?? AppFonts.getFont(
                  weight: AppFonts.medium,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),

              SizedBox(
                width: 4,
              ),

              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: SizedBox(
                    width: 5,
                    height: 5,
                    child: Image.asset(IconsAssets.star, color: Colors.red,)),
              )
            ],
          ),
          SizedBox(height: contentSpace ?? 4),
        ],
        textField,
      ],
    );
  }
}
