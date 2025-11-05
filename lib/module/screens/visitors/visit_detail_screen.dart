import 'package:flutter/material.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/response_model/visit_response_model.dart';

import '../../../config/constant/const_assets.dart';
import '../../global/widgets/common_app_bar.dart';

class VisitDetailScreen extends StatelessWidget {
  final Visit visit;

  const VisitDetailScreen({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
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
                    _buildDetailRow(
                      icon: Icons.info,
                      label: "Status",
                      value: visit.status,
                    ),
                    const SizedBox(height: 16),
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