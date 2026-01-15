import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';
// Conditional import for web image widget
import '../../screens/visitors/web_image_widget.dart' if (dart.library.io) '../../screens/visitors/web_image_widget_stub.dart';

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
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? kIsWeb
                        ? WebImageWidget(
                            imageUrl: imageUrl!,
                            width: size,
                            height: size,
                            borderRadius: size / 2,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to default icon if network image fails
                              return const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              // Show loading indicator while image is loading
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                    : const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
              ),
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

