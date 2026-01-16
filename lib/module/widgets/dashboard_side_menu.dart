import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:highfly/config/constant/app_colors.dart';
import '../../config/constant/app_strings.dart';
import '../providers/organization_provider.dart';
import '../utils/responsive.dart';
import 'organization_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes.dart';
import '../../data/repository/auth_api_repository.dart';
// Conditional import for web image widget
import '../screens/visitors/web_image_widget.dart' if (dart.library.io) '../screens/visitors/web_image_widget_stub.dart';

class DashboardSideMenu extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onMenuItemSelected;
  final bool isVisible;

  const DashboardSideMenu({
    super.key,
    required this.selectedIndex,
    required this.onMenuItemSelected,
    this.isVisible = true,
  });

  @override
  State<DashboardSideMenu> createState() => _DashboardSideMenuState();
}

class _DashboardSideMenuState extends State<DashboardSideMenu> {
  final List<MenuItem> menuItems = [
    MenuItem(
      icon: Icons.business,
      title: 'Project',
      index: 0,
    ),
    MenuItem(
      icon: Icons.people,
      title: 'Visits',
      index: 1,
    ),
    MenuItem(
      icon: Icons.calendar_today_outlined,
      title: 'Booking Processor',
      index: 2,
    ),
    MenuItem(
      icon: Icons.lock_clock,
      title: 'Holds',
      index: 3,
    ),
    MenuItem(
      icon: Icons.book_online,
      title: 'Bookings',
      index: 4,
    ),
    MenuItem(
      icon: Icons.person,
      title: 'Profile',
      index: 5,
    ),
    // MenuItem(
    //   icon: Icons.settings,
    //   title: 'Setting',
    //   index: 2,
    // ),
  ];

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    if (isMobile) {
      return Container(); // On mobile, we'll use a drawer
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isVisible ? (isTablet ? 200 : 250) : 0,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: widget.isVisible
          ? Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                  ),
                  child: _OrganizationHeader(
                    showName: false,
                    logoHeight: kIsWeb 
                        ? (isTablet ? 80 : 130) 
                        : (isTablet ? 56 : 72),
                    // textStyle: TextStyle(
                    //   fontSize: isTablet ? 15 : 17,
                    //   fontWeight: FontWeight.w600,
                    //   color: AppColors.primaryTextColor,
                    // ),
                  ),
                ),

                // Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = widget.selectedIndex == item.index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: InkWell(
                          onTap: () => widget.onMenuItemSelected(item.index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ?  AppColors.primaryColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color:  AppColors.primaryColor, width: 1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected
                                      ?  AppColors.primaryColor
                                      : AppColors.primaryTextColor,
                                  size: isTablet ? 20 : 24,
                                ),
                                SizedBox(width: isTablet ? 8 : 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: isSelected
                                          ?  AppColors.primaryColor
                                          : AppColors.primaryTextColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: isTablet ? 12 : 16,
                                    ),
                                    overflow: isTablet ? TextOverflow.ellipsis : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer with user profile
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          FutureBuilder<Map<String, String?>>(
                            future: _getUserData(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircleAvatar(
                                  radius: 16,
                                  backgroundColor:  AppColors.primaryColor,
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.hasError || !snapshot.hasData) {
                                return const CircleAvatar(
                                  radius: 16,
                                  backgroundColor:  AppColors.primaryColor,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                );
                              }

                              final userData = snapshot.data!;
                              final profilePhoto = userData['photo'];

                              return _buildProfileAvatar(
                                photoUrl: profilePhoto,
                                radius: 16,
                                iconSize: 18,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          FutureBuilder<Map<String, String?>>(
                            future: _getUserData(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Expanded(
                                  child: Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: AppColors.primaryTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }

                              if (snapshot.hasError || !snapshot.hasData) {
                                return const Expanded(
                                  child: Text(
                                    'Guest User',
                                    style: TextStyle(
                                      color: AppColors.primaryTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }

                              final userData = snapshot.data!;
                              final userName = userData['name'] ?? 'Guest User';

                              return Expanded(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: AppColors.primaryTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Logout button
                      InkWell(
                        onTap: () => _showLogoutConfirmationDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.red[700],
                                size: isTablet ? 18 : 20,
                              ),
                              SizedBox(width: isTablet ? 8 : 12),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: isTablet ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )

                // Footer with user profile
                /*Container(
                  padding: const EdgeInsets.all(20),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final userState = ref.watch(userControllerProvider);

                      if (userState.isLoading) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (userState.error != null) {
                        return const Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:  AppColors.primaryColor,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Guest User',
                                style: TextStyle(
                                  color: AppColors.primaryTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }

                      final user = userState.user;
                      if (user == null) {
                        return const Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:  AppColors.primaryColor,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Guest User',
                                style: TextStyle(
                                  color: AppColors.primaryTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          // User profile image or initials
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:  AppColors.primaryColor.withOpacity(0.2),
                            backgroundImage: user.profilePhoto.isNotEmpty
                                ? NetworkImage(
                                    user.profilePhoto,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to initials if network image fails
                                      return null;
                                    },
                                  )
                                : null,
                            child: user.profilePhoto.isEmpty || user.profilePhoto.isEmpty
                                ? Text(
                                    user.initials,
                                    style: const TextStyle(
                                      color:  AppColors.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.firstName.isNotEmpty ? user.firstName : 'Guest User',
                              style: const TextStyle(
                                color: AppColors.primaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),*/

              ],
            )
          : null,
    );
  }

  Widget _buildProfileAvatar({
    required String? photoUrl,
    required double radius,
    required double iconSize,
  }) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
        child: Icon(
          Icons.person,
          color: AppColors.primaryColor,
          size: iconSize,
        ),
      );
    }

    if (kIsWeb) {
      // Use WebImageWidget for web to avoid CORS issues
      return ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          child: WebImageWidget(
            imageUrl: photoUrl,
            width: radius * 2,
            height: radius * 2,
            borderRadius: radius,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Use CircleAvatar with NetworkImage for mobile
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(photoUrl),
        child: null,
      );
    }
  }

  Future<Map<String, String?>> _getUserData() async {
    final storage = const FlutterSecureStorage();
    final firstName = await storage.read(key: SharedPreferenceStrings.firstName);
    final profilePhoto = await storage.read(key: SharedPreferenceStrings.profilePhoto);
    
    return {
      'name': firstName,
      'photo': profilePhoto,
    };
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  // Call logout API
                  final authRepository = AuthApiRepository();
                  final result = await authRepository.logout();
                  
                  if (result['success'] == true) {
                    debugPrint('Logout API call successful');
                  } else {
                    debugPrint('Logout API call failed: ${result['message']}');
                    // Continue with logout even if API call fails
                  }
                } catch (e) {
                  debugPrint('Error calling logout API: $e');
                  // Continue with logout even if API call fails
                }
                
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();
                // Clear access token from secure storage
                const secureStorage = FlutterSecureStorage();
                await secureStorage.deleteAll();
                // Navigate back to sign in screen
                if (context.mounted) {
                  context.go(Routes.signIn);
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrganizationHeader extends ConsumerWidget {
  const _OrganizationHeader({
    this.showName = true,
    this.logoHeight = 64,
    this.textStyle,
  });

  final bool showName;
  final double logoHeight;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationState = ref.watch(organizationProvider);
    final organizationName =
        organizationState.asData?.value?.name ?? GlobalStrings.appName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: logoHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OrganizationLogo(
                  height: logoHeight - 8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 8),
            Text(
              organizationName,
              style: textStyle ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// Mobile Drawer Menu
class MobileSideMenuDrawer extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onMenuItemSelected;

  const MobileSideMenuDrawer({
    super.key,
    required this.selectedIndex,
    required this.onMenuItemSelected,
  });

  final List<MenuItem> menuItems = const [
    MenuItem(
      icon: Icons.business,
      title: 'Project',
      index: 0,
    ),
    MenuItem(
      icon: Icons.people,
      title: 'Visits',
      index: 1,
    ),
    MenuItem(
      icon: Icons.calendar_today_outlined,
      title: 'Booking Processor',
      index: 2,
    ),
    MenuItem(
      icon: Icons.lock_clock,
      title: 'Holds',
      index: 3,
    ),
    MenuItem(
      icon: Icons.book_online,
      title: 'Bookings',
      index: 4,
    ),
    // MenuItem(
    //   icon: Icons.person,
    //   title: 'Profile',
    //   index: 3,
    // ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: const SafeArea(
              child: _OrganizationHeader(
                showName: false,
                logoHeight: 150,
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == item.index;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: InkWell(
                    onTap: () {
                      onMenuItemSelected(item.index);
                      Navigator.of(context).pop(); // Close drawer
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ?  AppColors.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color:  AppColors.primaryColor, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected
                                ?  AppColors.primaryColor
                                : AppColors.primaryTextColor,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected
                                  ?  AppColors.primaryColor
                                  : AppColors.primaryTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer with user profile and logout
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildUserProfile(context),
                const SizedBox(height: 12),
                // Logout button
                InkWell(
                  onTap: () => _showLogoutConfirmationDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.red[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onMenuItemSelected(5);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:  AppColors.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:  AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: FutureBuilder<Map<String, String?>>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildDefaultUserProfile(context);
            }

            final userData = snapshot.data!;
            final userName = userData['name'] ?? 'Guest User';
            final profilePhoto = userData['photo'];

            return Row(
              children: [
                // User profile image or default icon
                _buildProfileAvatar(
                  photoUrl: profilePhoto,
                  radius: 24,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppColors.primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View Profile',
                        style: TextStyle(
                          color:  AppColors.primaryColor.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color:  AppColors.primaryColor.withValues(alpha: 0.6),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileAvatar({
    required String? photoUrl,
    required double radius,
    required double iconSize,
  }) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
        child: Icon(
          Icons.person,
          color: AppColors.primaryColor,
          size: iconSize,
        ),
      );
    }

    if (kIsWeb) {
      // Use WebImageWidget for web to avoid CORS issues
      return ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          child: WebImageWidget(
            imageUrl: photoUrl,
            width: radius * 2,
            height: radius * 2,
            borderRadius: radius,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Use CircleAvatar with NetworkImage for mobile
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(photoUrl),
        child: null,
      );
    }
  }

  Future<Map<String, String?>> _getUserData() async {
    final storage = const FlutterSecureStorage();
    final fullName = await storage.read(key: SharedPreferenceStrings.fullName);
    final profilePhoto = await storage.read(key: SharedPreferenceStrings.profilePhoto);
    
    return {
      'name': fullName,
      'photo': profilePhoto,
    };
  }

  Widget _buildDefaultUserProfile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigator.of(context).pop(); // Close drawer first
        // context.go(Routes.profileScreen);
        onMenuItemSelected(5);
        Navigator.of(context).pop(); // Close drawer
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:  AppColors.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:  AppColors.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:  AppColors.primaryColor.withValues(alpha: 0.2),
              child: const Icon(
                Icons.person,
                color:  AppColors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Guest User',
                    style: TextStyle(
                      color: AppColors.primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View Profile',
                    style: TextStyle(
                      color:  AppColors.primaryColor.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:  AppColors.primaryColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  // Call logout API
                  final authRepository = AuthApiRepository();
                  final result = await authRepository.logout();
                  
                  if (result['success'] == true) {
                    debugPrint('Logout API call successful');
                  } else {
                    debugPrint('Logout API call failed: ${result['message']}');
                    // Continue with logout even if API call fails
                  }
                } catch (e) {
                  debugPrint('Error calling logout API: $e');
                  // Continue with logout even if API call fails
                }
                
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();
                // Clear access token from secure storage
                const secureStorage = FlutterSecureStorage();
                await secureStorage.deleteAll();
                // Navigate back to sign in screen
                if (context.mounted) {
                  context.go(Routes.signIn);
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final int index;

  const MenuItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}