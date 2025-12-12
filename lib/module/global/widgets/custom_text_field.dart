import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:highfly/config/constant/const_assets.dart';

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
      
      // Web-specific enhancements
      final webPadding = kIsWeb ? 16.0 : 20.0;
      final webVerticalPadding = kIsWeb ? (height != null ? (height! / 2.5) - 4 : 18.0) : verticalPadding;
      final webBorderWidth = kIsWeb ? 1.5 : 1.0;
      final webFocusedBorderWidth = kIsWeb ? 2.0 : 1.0;
      final webBorderRadius = kIsWeb ? borderRadius + 2 : borderRadius;

      return InputDecoration(
        hintText: hintText,
        counterText: '',
        prefixIcon: prefixIcon,
        counter: null,
        hintStyle: TextStyle(
          color: const Color.fromARGB(255, 178, 178, 178), // Placeholder color
          fontSize: kIsWeb ? 15 : 14,
        ),
        suffixIcon: suffixIcon,
        fillColor: kIsWeb ? Colors.white : const Color(0xFFF9FBFF), // TextField background color
        filled: true,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: webPadding, // Web has slightly less horizontal padding
          vertical: webVerticalPadding,
        ),
        // Default border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(webBorderRadius),
          borderSide: BorderSide(
            color: kIsWeb ? const Color(0xFFE5E7EB) : const Color(0xFFDDDDDD), // TextField border color
            width: webBorderWidth,
          ),
        ),
        // Border when enabled but not focused
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(webBorderRadius),
          borderSide: BorderSide(
            color: kIsWeb ? const Color(0xFFE5E7EB) : const Color(0xFFDDDDDD), // TextField border color
            width: webBorderWidth,
          ),
        ),
        // Border when focused
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(webBorderRadius),
          borderSide: BorderSide(
            color: kIsWeb ? const Color(0xFF3B82F6) : const Color(0xFFDDDDDD), // Blue focus color for web
            width: webFocusedBorderWidth,
          ),
        ),
        // Border when error occurs
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(webBorderRadius),
          borderSide: BorderSide(
            color: kIsWeb ? const Color(0xFFEF4444) : const Color(0xFFDDDDDD),
            width: kIsWeb ? 1.5 : 1.2,
          ),
        ),
        // Border when focused and error occurs
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(webBorderRadius),
          borderSide: BorderSide(
            color: kIsWeb ? const Color(0xFFEF4444) : const Color(0xFFDDDDDD),
            width: kIsWeb ? 2.0 : 1.5,
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
      cursorColor: kIsWeb ? const Color(0xFF3B82F6) : const Color(0xFF475569), // Blue cursor for web
      inputFormatters: inputFormatters,
      onChanged: onChanged, // ✅ Pass the callback
      decoration: buildDecoration(),
      style: TextStyle(
        fontSize: kIsWeb ? 15 : 14,
        color: const Color(0xFF475569), // Entered text color
        fontWeight: kIsWeb ? FontWeight.w400 : FontWeight.normal,
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
                  fontSize: kIsWeb ? 15 : 14,
                  color: Colors.black,
                ),
              ),

              SizedBox(
                width: 4,
              ),
              if(isMandatory)...[
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: SizedBox(
                    width: 5,
                    height: 5,
                    child: Image.asset(IconsAssets.star, color: Colors.red,)),
              )
              ]
            ],
          ),
          SizedBox(height: contentSpace ?? (kIsWeb ? 14 : 12)),
        ],
        textField,
      ],
    );
  }
}
