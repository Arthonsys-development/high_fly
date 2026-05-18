import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/response_model/project_response_model.dart';
import '../../global/widgets/common_app_bar.dart';
import '../bookings/webview_screen.dart';
import '../../utils/responsive.dart';
import 'project_gallery_screen.dart';
// Conditional import for web image widget
import '../visitors/web_image_widget.dart' if (dart.library.io) '../visitors/web_image_widget_stub.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Use Responsive.isMobile to detect mobile web browsers
    final isMobile = Responsive.isMobile(context);
    
    if (!isMobile && kIsWeb) {
      // Desktop web layout
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: commonAppBar(
            context,
            "Project Detail",
            onBack: () => context.pop(),
          ),
        ),
        body: Container(
          color: AppColors.textFieldBGColor,
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

    // Mobile layout (for both native mobile and mobile web)
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: commonAppBar(
          context,
          "Project Detail",
          onBack: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildMobileContent(context),
      ),
    );
  }

  Widget _buildWebContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Image and Quick Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Image - Left Side (40% width)
            Expanded(
              flex: 4,
              child: _buildProjectHeaderWeb(context),
            ),
            const SizedBox(width: 24),
            // Quick Info Cards - Right Side (60% width)
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  _buildQuickInfoCards(context),
                  const SizedBox(height: 24),
                  _buildLocationSection(context),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Project Details Section
        _buildProjectDetails(context),
        const SizedBox(height: 24),
        // Map Charts Section
        if (project.mapCharts != null && project.mapCharts!.files.isNotEmpty) ...[
          _buildMapChartsSectionWeb(context),
          const SizedBox(height: 24),
        ],
        // Gallery Button
        if (project.galleryFiles.isNotEmpty)
          _buildGalleryButton(context),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProjectHeader(context),
        const SizedBox(height: 24),
        _buildProjectDetails(context),
        const SizedBox(height: 24),
        _buildLocationSection(context),
        const SizedBox(height: 24),
        if (project.mapCharts != null && project.mapCharts!.files.isNotEmpty) ...[
          _buildMapChartsSection(context),
          const SizedBox(height: 24),
        ],
        if (project.galleryFiles.isNotEmpty)
          _buildGalleryButton(context),
      ],
    );
  }

  Widget _buildProjectHeaderWeb(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
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
            // Project Image
            if (project.projectImage.isNotEmpty)
              WebImageWidget(
                imageUrl: project.projectImage,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 16,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
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
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Project Name and Status
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 32,
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
                  const SizedBox(height: 12),
                  _buildStatusChip(project.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
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
            // Project Image - Use WebImageWidget on web to avoid CORS issues
            if (project.projectImage.isNotEmpty)
              kIsWeb
                  ? WebImageWidget(
                      imageUrl: project.projectImage,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 16,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      project.projectImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, size: 80, color: Colors.grey),
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
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
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
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Project Name and Status
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.name,
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
                  _buildStatusChip(project.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColor = status.toLowerCase() == 'active'
        ? Colors.green
        : status.toLowerCase() == 'inactive'
            ? Colors.red
            : status.toLowerCase() == 'on_hold'
                ? Colors.orange
                : status.toLowerCase() == 'completed'
                    ? Colors.blue
                    : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProjectDetails(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Details',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          if (!isMobile)
            // Web: Two-column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project.description.isNotEmpty) ...[
                        _buildDetailRow(context, 'Description', project.description),
                        const SizedBox(height: 20),
                      ],
                      if (project.startDate != null) ...[
                        _buildDetailRow(context, 'Start Date', _formatDate(project.startDate!)),
                        const SizedBox(height: 16),
                      ],
                      if (project.endDate != null) ...[
                        _buildDetailRow(context, 'End Date', _formatDate(project.endDate!)),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project.totalPlotCount != null) ...[
                        _buildDetailRow(context, 'Total Plots', project.totalPlotCount.toString()),
                        const SizedBox(height: 16),
                      ],
                      if (project.availablePlotCount != null) ...[
                        _buildDetailRow(context, 'Available Plots', project.availablePlotCount.toString()),
                        const SizedBox(height: 16),
                      ],
                      if (project.createdAt != null) ...[
                        _buildDetailRow(context, 'Created At', _formatDate(project.createdAt!)),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ],
            )
          else
            // Mobile: Single column layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(context, 'Description', project.description.isNotEmpty ? project.description : 'No description available'),
                if (project.subAddress.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Sub Address', project.subAddress),
                ],
                if (project.totalPlotCount != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Total Plots', project.totalPlotCount.toString()),
                ],
                if (project.availablePlotCount != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Available Plots', project.availablePlotCount.toString()),
                ],
                if (project.startDate != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Start Date', _formatDate(project.startDate!)),
                ],
                if (project.endDate != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'End Date', _formatDate(project.endDate!)),
                ],
                if (project.createdAt != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Created At', _formatDate(project.createdAt!)),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.location_on,
            title: 'Location',
            value: project.subAddress.isNotEmpty 
                ? project.subAddress 
                : (project.location.isNotEmpty ? project.location : 'N/A'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.layers,
            title: 'Total Plots',
            value: project.totalPlotCount?.toString() ?? '0',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.check_circle,
            title: 'Available',
            value: project.availablePlotCount?.toString() ?? '0',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isMobile = Responsive.isMobile(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? 140 : 180,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: AppColors.primaryTextColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primaryColor,
                size: isMobile ? 24 : 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (project.address.isNotEmpty) ...[
            Text(
              project.address,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: AppColors.primaryTextColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (project.location.isNotEmpty && !project.location.contains(',')) ...[
            Text(
              project.location,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (project.latitude != null && project.longitude != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(context),
                icon: const Icon(Icons.map, size: 20),
                label: const Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 24,
                    vertical: isMobile ? 12 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Location coordinates not available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapChartsSection(BuildContext context) {
    if (project.mapCharts == null || project.mapCharts!.files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map Charts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ...project.mapCharts!.files.map((file) => _buildMapChartFileCard(context, file)),
        ],
      ),
    );
  }

  Widget _buildMapChartsSectionWeb(BuildContext context) {
    if (project.mapCharts == null || project.mapCharts!.files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map,
                color: AppColors.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Map Charts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grid layout for web
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemCount: project.mapCharts!.files.length,
                itemBuilder: (context, index) {
                  return _buildMapChartFileCardWeb(
                    context,
                    project.mapCharts!.files[index],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapChartFileCardWeb(BuildContext context, MapChartFile file) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail or Image Preview
          if (file.thumbnailUrl.isNotEmpty || file.fileUrl.isNotEmpty)
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, file.fileUrl.isNotEmpty ? file.fileUrl : file.thumbnailUrl),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: kIsWeb
                      ? WebImageWidget(
                          imageUrl: file.thumbnailUrl.isNotEmpty ? file.thumbnailUrl : file.fileUrl,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 12,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          file.thumbnailUrl.isNotEmpty ? file.thumbnailUrl : file.fileUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image, size: 60, color: Colors.grey),
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
                        ),
                ),
              ),
            ),
          // File Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName.isNotEmpty ? file.fileName : 'Unnamed File',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (file.fileType.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          file.fileType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (file.fileSizeDisplay.isNotEmpty)
                      Expanded(
                        child: Text(
                          file.fileSizeDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final isPdf = file.fileType.toLowerCase() == 'pdf' ||
                          file.fileUrl.toLowerCase().endsWith('.pdf') ||
                          file.fileName.toLowerCase().endsWith('.pdf');
                      
                      if (isPdf) {
                        _openImageInWebView(context, file.fileUrl);
                      } else {
                        _showFullScreenImage(context, file.fileUrl.isNotEmpty ? file.fileUrl : file.thumbnailUrl);
                      }
                    },
                    icon: Icon(
                      file.fileType.toLowerCase() == 'pdf' ||
                              file.fileUrl.toLowerCase().endsWith('.pdf') ||
                              file.fileName.toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      size: 16,
                    ),
                    label: Text(
                      file.fileType.toLowerCase() == 'pdf' ||
                              file.fileUrl.toLowerCase().endsWith('.pdf') ||
                              file.fileName.toLowerCase().endsWith('.pdf')
                          ? 'View PDF'
                          : 'View',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildMapChartFileCard(BuildContext context, MapChartFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail or Image Preview
          if (file.thumbnailUrl.isNotEmpty || file.fileUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                _showFullScreenImage(context, file.thumbnailUrl.isNotEmpty ? file.thumbnailUrl : file.fileUrl);
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: kIsWeb
                    ? WebImageWidget(
                        imageUrl: file.thumbnailUrl.isNotEmpty ? file.thumbnailUrl : file.fileUrl,
                        width: double.infinity,
                        height: 200,
                        borderRadius: 12,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        file.thumbnailUrl.isNotEmpty ? file.thumbnailUrl : file.fileUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image, size: 60, color: Colors.grey),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          // File Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName.isNotEmpty ? file.fileName : 'Unnamed File',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (file.fileType.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          file.fileType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (file.fileSizeDisplay.isNotEmpty)
                      Text(
                        file.fileSizeDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Check if file is PDF or image
                          final isPdf = file.fileType.toLowerCase() == 'pdf' ||
                              file.fileUrl.toLowerCase().endsWith('.pdf') ||
                              file.fileName.toLowerCase().endsWith('.pdf');
                          
                          if (isPdf) {
                            // Use WebView for PDFs
                            _openImageInWebView(context, file.fileUrl);
                          } else {
                            // Use full-screen image viewer for images
                            _showFullScreenImage(context, file.fileUrl.isNotEmpty ? file.fileUrl : file.thumbnailUrl);
                          }
                        },
                        icon: Icon(
                          file.fileType.toLowerCase() == 'pdf' ||
                                  file.fileUrl.toLowerCase().endsWith('.pdf') ||
                                  file.fileName.toLowerCase().endsWith('.pdf')
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          size: 18,
                        ),
                        label: Text(
                          file.fileType.toLowerCase() == 'pdf' ||
                                  file.fileUrl.toLowerCase().endsWith('.pdf') ||
                                  file.fileName.toLowerCase().endsWith('.pdf')
                              ? 'View PDF'
                              : 'View Full Image',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
    );
  }

  Widget _buildGalleryButton(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final fileCount = project.galleryFiles.length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: AppColors.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                Text(
                  '$fileCount ${fileCount == 1 ? 'file' : 'files'} available',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectGalleryScreen(
                    projectName: project.name,
                    galleryFiles: project.galleryFiles,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('View Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    if (project.latitude == null || project.longitude == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location coordinates not available for this project'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${project.latitude},${project.longitude}';

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: googleMapsUrl,
            title: '${project.name} - Location',
          ),
        ),
      );
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImagePage(imageUrl: imageUrl),
        fullscreenDialog: true,
      ),
    );
  }

  void _openImageInWebView(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: imageUrl,
          title: 'Map Chart',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Full screen image viewer page
class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen image viewer with no constraints
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            panEnabled: true,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: kIsWeb
                  ? WebImageWidget(
                      imageUrl: imageUrl,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 60, color: Colors.white70),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          if (loadingProgress.expectedTotalBytes != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${(loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

