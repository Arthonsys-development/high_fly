import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';

class ProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onEditPressed;
  final double size;
  final bool showEditButton;

  const ProfilePicture({
    super.key,
    this.imageUrl,
    this.onEditPressed,
    this.size = 120,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff475569), // Dark grey background
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: FileImage(File(imageUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
        if (showEditButton) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onEditPressed,
            child: Text(
              'Edit',
              style: AppFonts.getFont(
                weight: AppFonts.medium,
                fontSize: 14,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

