import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/response_model/visit_response_model.dart';

import '../../../config/constant/const_assets.dart';
import '../../global/widgets/common_app_bar.dart';

class VisitDetailScreen extends StatelessWidget {
  final Visit visit;

  const VisitDetailScreen({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: commonAppBar(context, "Visit Detail"),
        ),
        body: Container(
          color: AppColors.primaryBackgroundColor,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildWebContent(context),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), child: commonAppBar(context, "Visit Detail")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visitor Photo Card with Name and Location
            GestureDetector(
              onTap: visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty
                  ? () => _showFullScreenImage(context, visit.visitorPhoto!)
                  : null,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Visitor Image
                      if (visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty)
                        Image.network(
                          visit.visitorPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Image.asset(
                                ImageAssets.highFlyLogo,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          color: Colors.grey[200],
                          child: Image.asset(
                            ImageAssets.highFlyLogo,
                            fit: BoxFit.contain,
                          ),
                        ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Visitor Name and Location
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              visit.visitorName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black54,
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    visit.projectName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4.0,
                                          color: Colors.black54,
                                          offset: Offset(1.0, 1.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Client Photo (if available)
            if (visit.clientPhoto != null && visit.clientPhoto!.isNotEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      "Client Photo",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, visit.clientPhoto!),
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryColor, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(75),
                          child: Image.network(
                            visit.clientPhoto!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(ImageAssets.highFlyLogo);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Details Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      icon: Icons.tag,
                      label: "Visit ID",
                      value: visit.id.toString(),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: "Visit Date & Time",
                      value: visit.visitDateTime,
                    ),
                    // if (visit.agent.isNotEmpty) ...[
                    //   const SizedBox(height: 16),
                    //   _buildDetailRow(
                    //     icon: Icons.person,
                    //     label: "Agent",
                    //     value: visit.agent,
                    //   ),
                    // ],
                    if (visit.purpose.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.category,
                        label: "Visit Type",
                        value: _formatVisitType(visit.purpose),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // _buildDetailRow(
                    //   icon: Icons.info,
                    //   label: "Status",
                    //   value: visit.status,
                    // ),
                    // const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.location_on,
                      label: "At Project Location",
                      value: visit.isAtProjectLocation ? "Yes" : "No",
                    ),
                    if (visit.clientName != null && visit.clientName!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.person_outline,
                        label: "Client Name",
                        value: visit.clientName!,
                      ),
                    ],
                    if (visit.clientPhone != null && visit.clientPhone!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.phone,
                        label: "Client Phone",
                        value: visit.clientPhone!,
                      ),
                    ],
                    if (visit.clientInterestLevel != null && visit.clientInterestLevel!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.star,
                        label: "Interest Level",
                        value: visit.clientInterestLevel!,
                      ),
                    ],
                    if (visit.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.phone_android,
                        label: "Visitor Phone",
                        value: visit.phoneNumber,
                      ),
                    ],
                    if (visit.email != null && visit.email!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.email,
                        label: "Email",
                        value: visit.email!,
                      ),
                    ],
                    if (visit.comments != null && visit.comments!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.comment,
                        label: "Comments",
                        value: visit.comments!,
                      ),
                    ],
                    if (visit.createdAt != null && visit.createdAt!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: "Created At",
                        value: visit.createdAt!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader(BuildContext context) {
    return GestureDetector(
      onTap: visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty
          ? () => _showFullScreenImage(context, visit.visitorPhoto!)
          : null,
      child: MouseRegion(
        cursor: visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
            // Visitor Image
            if (visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty)
              Image.network(
                visit.visitorPhoto!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: Center(
                      child: Image.asset(
                        ImageAssets.highFlyLogo,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: Center(
                  child: Image.asset(
                    ImageAssets.highFlyLogo,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            // Visitor Info
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      visit.visitorName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  visit.projectName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildWebContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          // Single column layout for smaller screens
          return Column(
            children: [
              _buildWebHeader(context),
              const SizedBox(height: 24),
              _buildWebDetailsCard(),
              if (visit.clientPhoto != null && visit.clientPhoto!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildWebClientPhotoCard(context),
              ],
              const SizedBox(height: 24),
              _buildWebAdditionalInfoCard(),
            ],
          );
        }
        // Two column layout for larger screens
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - Main Details
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildWebDetailsCard(),
                  if (visit.clientPhoto != null && visit.clientPhoto!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildWebClientPhotoCard(context),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column - Visitor Photo Header and Contact Details
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildWebHeader(context),
                  const SizedBox(height: 24),
                  _buildWebAdditionalInfoCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Visit Information",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildWebDetailRow(
              icon: Icons.tag,
              label: "Visit ID",
              value: visit.id.toString(),
            ),
            const Divider(height: 32),
            _buildWebDetailRow(
              icon: Icons.calendar_today,
              label: "Visit Date & Time",
              value: visit.visitDateTime,
            ),
            if (visit.purpose.isNotEmpty) ...[
              const Divider(height: 32),
              _buildWebDetailRow(
                icon: Icons.category,
                label: "Visit Type",
                value: _formatVisitType(visit.purpose),
              ),
            ],
            const Divider(height: 32),
            _buildWebDetailRow(
              icon: Icons.location_on,
              label: "At Project Location",
              value: visit.isAtProjectLocation ? "Yes" : "No",
              valueColor: visit.isAtProjectLocation
                  ? AppColors.successColor
                  : AppColors.secondaryTextColor,
            ),
            if (visit.comments != null && visit.comments!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildWebDetailRow(
                icon: Icons.comment,
                label: "Comments",
                value: visit.comments!,
                isMultiline: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWebClientPhotoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Text(
              "Client Photo",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _showFullScreenImage(context, visit.clientPhoto!),
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      spreadRadius: 4,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.network(
                    visit.clientPhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(ImageAssets.highFlyLogo);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAdditionalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.contact_phone,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Contact Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (visit.clientName != null && visit.clientName!.isNotEmpty) ...[
              _buildWebDetailRow(
                icon: Icons.person_outline,
                label: "Client Name",
                value: visit.clientName!,
              ),
              const SizedBox(height: 20),
            ],
            if (visit.clientPhone != null && visit.clientPhone!.isNotEmpty) ...[
              _buildWebDetailRow(
                icon: Icons.phone,
                label: "Client Phone",
                value: visit.clientPhone!,
              ),
              const SizedBox(height: 20),
            ],
            if (visit.clientInterestLevel != null &&
                visit.clientInterestLevel!.isNotEmpty) ...[
              _buildWebDetailRow(
                icon: Icons.star,
                label: "Interest Level",
                value: visit.clientInterestLevel!,
                valueColor: AppColors.primaryColor,
              ),
              const SizedBox(height: 20),
            ],
            if (visit.phoneNumber.isNotEmpty) ...[
              _buildWebDetailRow(
                icon: Icons.phone_android,
                label: "Visitor Phone",
                value: visit.phoneNumber,
              ),
              const SizedBox(height: 20),
            ],
            if (visit.email != null && visit.email!.isNotEmpty) ...[
              _buildWebDetailRow(
                icon: Icons.email,
                label: "Email",
                value: visit.email!,
              ),
              const SizedBox(height: 20),
            ],
            if (visit.createdAt != null && visit.createdAt!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildWebDetailRow(
                icon: Icons.access_time,
                label: "Created At",
                value: visit.createdAt!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWebDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? AppColors.primaryTextColor,
                  fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
                  height: isMultiline ? 1.5 : 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatVisitType(String type) {
    // Convert snake_case to Title Case
    return type
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }
}