import 'package:flutter/material.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 116,
          height: 40,
          child: _buildPreviousButton(),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 116,
          height: 40,
          child: _buildNextButton(),
        ),
      ],
    );
  }

  Widget _buildPreviousButton() {
    return ElevatedButton(
      onPressed: isPreviousEnabled ? onPrevious : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.lightGreyColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8), // Adjusted padding for new height
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isPreviousEnabled 
                ? AppColors.lightGreyBorderColor 
                : AppColors.lightGreyBorderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_sharp,
            size: 16,
            color: isPreviousEnabled 
                ? AppColors.lightGreyColor 
                : AppColors.lightGreyColor.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            'Previous',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPreviousEnabled 
                  ? AppColors.lightGreyColor 
                  : AppColors.lightGreyColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: isNextEnabled ? onNext : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isNextEnabled 
            ? AppColors.primaryColor 
            : AppColors.primaryColor.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8), // Adjusted padding for new height
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            nextButtonText ?? 'Next',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_sharp,
            size: 16,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}