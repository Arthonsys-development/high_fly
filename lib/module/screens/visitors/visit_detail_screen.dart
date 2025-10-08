import 'package:flutter/material.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/response_model/visit_response_model.dart';
import 'package:highfly/module/utils/utils.dart';

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
            // Visitor Photo
            if (visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty)
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryButtonColor, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: Image.network(
                      visit.visitorPhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to default image if network image fails
                        return Image.asset(ImageAssets.highFlyLogo);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        // Show loading indicator while image is loading
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryButtonColor,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryButtonColor, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: Image.asset(ImageAssets.highFlyLogo),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Visitor Name
            Center(
              child: Text(
                visit.visitorName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Project Name
            Center(
              child: Text(
                visit.projectName,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

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
                      icon: Icons.calendar_today,
                      label: "Visit Date & Time",
                      value: Utils.formatDateTime(visit.visitDateTime),
                    ),
                    /*const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.phone,
                      label: "Phone Number",
                      value: visit.phoneNumber,
                    ),
                    if (visit.email != null && visit.email!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.email,
                        label: "Email",
                        value: visit.email!,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.person,
                      label: "Agent",
                      value: visit.agent,
                    ),*/
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.info,
                      label: "Status",
                      value: visit.status,
                    ),
                    if (visit.comments != null && visit.comments!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.comment,
                        label: "Comments",
                        value: visit.comments!,
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
        Icon(icon, size: 20, color: AppColors.primaryButtonColor),
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
}