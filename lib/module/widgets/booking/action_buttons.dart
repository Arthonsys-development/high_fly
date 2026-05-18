import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../config/constant/app_colors.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isPreviousEnabled;
  final bool isNextEnabled;
  final String? nextButtonText;

  const ActionButtons({
    super.key,
    this.onPrevious,
    this.onNext,
    this.isPreviousEnabled = false,
    this.isNextEnabled = true,
    this.nextButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = kIsWeb ? 140.0 : 116.0;
    final buttonHeight = kIsWeb ? 48.0 : 40.0;
    final buttonSpacing = kIsWeb ? 20.0 : 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        (onPrevious != null) ? SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: _buildPreviousButton(),
        ) : Container(),
        SizedBox(width: buttonSpacing),
        SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: _buildNextButton(),
        ),
      ],
    );
  }

  Widget _buildPreviousButton() {
    final iconSize = kIsWeb ? 18.0 : 16.0;
    final fontSize = kIsWeb ? 14.0 : 12.0;
    final borderRadius = kIsWeb ? 8.0 : 4.0;
    final borderWidth = kIsWeb ? 1.5 : 1.0;

    return Semantics(
      label: 'Previous',
      button: true,
      child: ElevatedButton(
        onPressed: isPreviousEnabled ? onPrevious : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.lightGreyColor,
          elevation: kIsWeb ? 1 : 0,
          padding: EdgeInsets.symmetric(
            vertical: kIsWeb ? 12 : 8,
            horizontal: kIsWeb ? 16 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: isPreviousEnabled 
                  ? AppColors.lightGreyBorderColor 
                  : AppColors.lightGreyBorderColor.withValues(alpha: 0.5),
              width: borderWidth,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_sharp,
              size: iconSize,
              color: isPreviousEnabled 
                  ? AppColors.lightGreyColor 
                  : AppColors.lightGreyColor.withValues(alpha: 0.5),
            ),
            SizedBox(width: kIsWeb ? 10 : 8),
            Text(
              'Previous',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: isPreviousEnabled 
                    ? AppColors.lightGreyColor 
                    : AppColors.lightGreyColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final iconSize = kIsWeb ? 18.0 : 16.0;
    final fontSize = kIsWeb ? 16.0 : 16.0;
    final borderRadius = kIsWeb ? 8.0 : 4.0;

    return Semantics(
      label: nextButtonText ?? 'Next',
      button: true,
      child: ElevatedButton(
        onPressed: isNextEnabled ? onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isNextEnabled 
              ? AppColors.primaryColor 
              : AppColors.primaryColor.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: kIsWeb ? 2 : 0,
          padding: EdgeInsets.symmetric(
            vertical: kIsWeb ? 12 : 8,
            horizontal: kIsWeb ? 20 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nextButtonText ?? 'Next',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            SizedBox(width: kIsWeb ? 10 : 8),
            if(nextButtonText == "Next")
              Icon(
                Icons.arrow_forward_sharp,
                size: iconSize,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}