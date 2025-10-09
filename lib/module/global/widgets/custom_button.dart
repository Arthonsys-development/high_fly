import 'package:flutter/material.dart';

import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isShowShimmer;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final TextStyle? textStyle;
  final List<BoxShadow>? shadow;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final Widget? leadingWidget;
  final Widget? trailingWidget;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isShowShimmer = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.textStyle,
    this.shadow,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = 5,
    this.leadingWidget,
    this.trailingWidget
  });

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadow,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  if(leadingWidget!= null)
                    SizedBox(
                        width: 18,
                        child: leadingWidget!),

                  SizedBox(
                    width: 5,
                  ),

                  Text(text, style: textStyle ?? AppFonts.getFont(
                  weight: fontWeight,
                  fontSize: fontSize,
                  color: textColor ?? Colors.white,
                            ),
                          ),

                  if(trailingWidget!= null)
                    trailingWidget!,
                ],
              ),
            ),
      ),
    );

    return button;
  }
}
