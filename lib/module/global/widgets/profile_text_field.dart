import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';

class ProfileTextField extends StatelessWidget {
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
  final bool isReadOnly;
  final VoidCallback? onEditPressed;

  const ProfileTextField({
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
    this.height = 48,
    this.showTitle = true,
    this.inputFormatters,
    this.borderRadius = 8,
    this.contentSpace,
    this.onChanged,
    this.isReadOnly = false,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration buildDecoration() {
      return InputDecoration(
        hintText: hintText,
        counterText: '',
        prefixIcon: prefixIcon,
        counter: null,
        hintStyle: const TextStyle(
          color: AppColors.secondaryTextColor,
          fontSize: 14,
        ),
        suffixIcon: !isReadOnly && enabled ? suffixIcon : null,
        fillColor: isReadOnly ? const Color(0xfff5f5f5) : Colors.white,
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isReadOnly ? Colors.grey.shade300 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isReadOnly ? Colors.grey.shade300 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
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
      enabled: enabled && !isReadOnly,
      readOnly: isReadOnly,
      cursorColor: AppColors.primaryColor,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: buildDecoration(),
      style: TextStyle(
        fontSize: 14,
        color: isReadOnly ? Colors.grey.shade600 : Colors.black,
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
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              if (isMandatory) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: AppFonts.getFont(
                    weight: AppFonts.medium,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: contentSpace ?? 8),
        ],
        Stack(
          children: [
            textField,
            if (isReadOnly && onEditPressed != null)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: onEditPressed,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
