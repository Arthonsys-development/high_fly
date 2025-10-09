import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';

class ProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onLogoutPressed;
  final bool showLogout;

  const ProfileHeader({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.onLogoutPressed,
    this.showLogout = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.menu,
          color: AppColors.primaryColor,
          size: 24,
        ),
        onPressed: onMenuPressed,
      ),
      title: Text(
        title,
        style: AppFonts.getFont(
          weight: AppFonts.semiBold,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        if (showLogout)
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryColor,
              size: 20,
            ),
            onPressed: onLogoutPressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
