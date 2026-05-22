import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/hold_list_model.dart';
import 'package:highfly/data/models/hold_document_model.dart' as hold_document_model;
import '../../widgets/booking/plot_details_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/holds_provider.dart';
import '../../utils/responsive.dart';
import 'hold_booking_screen.dart';
import 'hold_edit_screen.dart';
import 'hold_document_management_screen.dart';
import '../bookings/webview_screen.dart';
// Conditional import for web image widget
import '../visitors/web_image_widget.dart' if (dart.library.io) '../visitors/web_image_widget_stub.dart';

String _formatStatusDisplay(String statusDisplay) {
  if (statusDisplay.isEmpty) return statusDisplay;
  
  // If it contains "/", capitalize each part separately
  if (statusDisplay.contains('/')) {
    return statusDisplay.split('/').map((part) {
      return part.trim().isEmpty 
          ? part 
          : part.trim()[0].toUpperCase() + part.trim().substring(1).toLowerCase();
    }).join('/');
  }
  
  // Capitalize first letter, rest lowercase
  return statusDisplay[0].toUpperCase() + statusDisplay.substring(1).toLowerCase();
}

class HoldDetailScreen extends ConsumerStatefulWidget {
  final HoldListModel hold;

  const HoldDetailScreen({super.key, required this.hold});

  @override
  ConsumerState<HoldDetailScreen> createState() => _HoldDetailScreenState();
}

class _HoldDetailScreenState extends ConsumerState<HoldDetailScreen> {
  late HoldListModel _currentHold;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentHold = widget.hold;
  }

  Future<void> _refreshHoldData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh holds list from provider
      await ref.read(holdsControllerProvider.notifier).loadHolds();
      
      // Find the updated hold in the list
      final holds = ref.read(holdsControllerProvider).holds;
      final updatedHold = holds.firstWhere(
        (h) => h.id == _currentHold.id,
        orElse: () => _currentHold,
      );

      if (mounted) {
        setState(() {
          _currentHold = updatedHold;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HoldEditScreen(hold: _currentHold),
      ),
    );

    // If update was successful, refresh the data
    if (result == true && mounted) {
      await _refreshHoldData();
    }
  }

  // Returns true for desktop web UI, false for mobile UI (mobile browser or native app)
  bool _isDesktopWeb(BuildContext context) {
    return !Responsive.isMobile(context) && kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    final hold = _currentHold;
    final isDesktopWeb = _isDesktopWeb(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: const Text("Hold Details"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: AppColors.primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: AppColors.primaryTextColor),
          centerTitle: true,
          elevation: 1,
          actions: [
            if (hold.status.toLowerCase() == 'active' && !hold.isExpired)
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primaryColor),
                onPressed: _isLoading ? null : _navigateToEdit,
                tooltip: 'Edit Hold',
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isDesktopWeb ? 32.0 : 16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktopWeb ? 1200 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Status Card
                  Builder(
                    builder: (context) {
                      Color statusColor;
                      IconData statusIcon;
                      
                      final status = hold.status.toLowerCase();
                      final statusDisplay = hold.statusDisplay.toLowerCase();
                      
                      // Check for "Converted to Booking" status first
                      if (statusDisplay == 'converted to booking') {
                        statusColor = Colors.blue;
                        statusIcon = Icons.check_circle;
                      } else if (status == 'active') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle_outline;
                      } else if (status == 'expired' || status == 'inactive' || hold.isExpired) {
                        statusColor = Colors.red;
                        statusIcon = Icons.error_outline;
                      } else {
                        statusColor = Colors.orange;
                        statusIcon = Icons.pending_outlined;
                      }
                      
                      return Container(
                        padding: EdgeInsets.all(isDesktopWeb ? 20 : 16),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isDesktopWeb ? 16 : 12),
                          border: Border.all(
                            color: statusColor,
                            width: isDesktopWeb ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: isDesktopWeb ? 15 : 14,
                                    color: AppColors.lightGreyColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: isDesktopWeb ? 6 : 4),
                                Text(
                                  _formatStatusDisplay(hold.statusDisplay),
                                  style: TextStyle(
                                    fontSize: isDesktopWeb ? 20 : 18,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                    letterSpacing: isDesktopWeb ? 0.3 : 0,
                                  ),
                                ),
                              ],
                            ),
                            Icon(statusIcon, color: statusColor, size: isDesktopWeb ? 36 : 32),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isDesktopWeb ? 32 : 24),

                  // Plot Information Section
                  _buildSectionTitle('Plot Information'),
                  if (hold.plotDetails.isNotEmpty) ...[
                    PlotDetailsCard(
                      selectedPlots: hold.plotDetails
                          .map(
                            (p) => p.toPlot(
                              projectId: hold.project?.id.toString(),
                            ),
                          )
                          .toList(),
                      selectedProjectName: hold.project?.name ??
                          hold.plotDetails.first.projectName,
                    ),
                    SizedBox(height: isDesktopWeb ? 16 : 12),
                    _buildDetailCard([
                      _buildDetailRow('Hold Until', hold.holdUntil),
                      _buildDetailRow('Created At', hold.createdAt),
                      _buildDetailRow('Updated At', hold.updatedAt),
                      // if (hold.plc || hold.plcApplied) ...[
                      //   _buildDetailRow('PLC', hold.plc ? 'Yes' : 'No'),
                      //   _buildDetailRow(
                      //       'PLC Applied', hold.plcApplied ? 'Yes' : 'No'),
                      //   if (hold.plcApplied &&
                      //       hold.plcPercentage != null &&
                      //       hold.plcPercentage! > 0)
                      //     _buildDetailRow('PLC %', '${hold.plcPercentage}'),
                      // ],
                    ]),
                  ] else
                    _buildDetailCard([
                      _buildDetailRow('Plot No.', hold.plotCode),
                      if (hold.project != null)
                        _buildDetailRow('Project', hold.project!.name),
                      if (hold.plotSize != null && hold.plotSize!.isNotEmpty)
                        _buildDetailRow('Plot Size', hold.plotSize!),
                      if (hold.saleableSize != null &&
                          hold.saleableSize!.isNotEmpty)
                        _buildDetailRow(
                            'Saleable Size', '${hold.saleableSize} sq yd'),
                      if (hold.plotArea != null && hold.plotArea!.isNotEmpty)
                        _buildDetailRow(
                            'Plot Area', '${hold.plotArea} sq mtr'),
                      if (hold.plc || hold.plcApplied)
                        _buildDetailRow('PLC', hold.plc ? 'Yes' : 'No'),
                      if (hold.plc || hold.plcApplied)
                        _buildDetailRow(
                            'PLC Applied', hold.plcApplied ? 'Yes' : 'No'),
                      if (hold.plcApplied &&
                          hold.plcPercentage != null &&
                          hold.plcPercentage! > 0)
                        _buildDetailRow('PLC %', '${hold.plcPercentage}'),
                      if (hold.plotFacing != null &&
                          hold.plotFacing!.isNotEmpty)
                        _buildDetailRow('Plot Facing', hold.plotFacing!),
                      _buildDetailRow('Hold Until', hold.holdUntil),
                      _buildDetailRow('Created At', hold.createdAt),
                      _buildDetailRow('Updated At', hold.updatedAt),
                    ]),
                  SizedBox(height: isDesktopWeb ? 32 : 24),

                  // Customer Information and Hold Details in a row for desktop web
                  if (isDesktopWeb)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Customer Information'),
                              _buildDetailCard([
                                _buildDetailRow('Customer Name', hold.customerName),
                                _buildDetailRow('Phone', hold.customerPhone),
                                if (hold.customerEmail.isNotEmpty)
                                  _buildDetailRow('Email', hold.customerEmail),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Hold Details'),
                              _buildDetailCard([
                                _buildDetailRow('RERA Number', hold.reraNumber),
                                if (hold.teamLeaderName.isNotEmpty)
                                  _buildDetailRow('Team Leader', hold.teamLeaderName),
                                _buildDetailRow('Client Aadhar', hold.clientAadhar),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Customer Information Section
                    _buildSectionTitle('Customer Information'),
                    _buildDetailCard([
                      _buildDetailRow('Customer Name', hold.customerName),
                      _buildDetailRow('Phone', hold.customerPhone),
                      if (hold.customerEmail.isNotEmpty)
                        _buildDetailRow('Email', hold.customerEmail),
                    ]),
                    const SizedBox(height: 24),

                    // Hold Details Section
                    _buildSectionTitle('Hold Details'),
                    _buildDetailCard([
                      _buildDetailRow('RERA Number', hold.reraNumber),
                      if (hold.teamLeaderName.isNotEmpty)
                        _buildDetailRow('Team Leader', hold.teamLeaderName),
                      _buildDetailRow('Client Aadhar', hold.clientAadhar),
                    ]),
                  ],
                  SizedBox(height: isDesktopWeb ? 32 : 24),

                  // Payment Information Section
                  /*_buildSectionTitle('Payment Information'),
                  _buildDetailCard([
                    _buildDetailRow('Payment Mode', PaymentMethod.getValue(hold.paymentMode).isNotEmpty 
                        ? PaymentMethod.getValue(hold.paymentMode) 
                        : hold.paymentMode),
                    _buildDetailRow('Payment Reference', hold.paymentReference),
                  ]),
                  SizedBox(height: isDesktopWeb ? 32 : 24),*/

                  // // Bank Details Section
                  // _buildSectionTitle('Bank Details'),
                  // _buildDetailCard([
                  //   _buildDetailRow('Account Holder Name', hold.accountHolderName),
                  //   _buildDetailRow('Branch Name', hold.branchName),
                  //   _buildDetailRow('Account Number', hold.accountNumber),
                  //   _buildDetailRow('IFSC Code', hold.ifscCode),
                  //   _buildDetailRow('Account Type', hold.accountType),
                  //   _buildDetailRow('Bank Contact', hold.bankContactNumber),
                  // ]),
                  // SizedBox(height: isDesktopWeb ? 32 : 24),

                  // Remarks Section
                  if (hold.remarks.isNotEmpty) ...[
                    _buildSectionTitle('Remarks'),
                    _buildDetailCard([
                      _buildDetailRow('Notes', hold.remarks),
                    ]),
                    SizedBox(height: isDesktopWeb ? 32 : 24),
                  ],

                  // Documents Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildSectionTitle('Documents (${hold.documentCount})'),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primaryColor),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HoldDocumentManagementScreen(hold: hold),
                            ),
                          );
                          if (result == true && mounted) {
                            await _refreshHoldData();
                          }
                        },
                        tooltip: 'Manage Documents',
                      ),
                    ],
                  ),
                  if (hold.documents.isNotEmpty)
                    _buildDocumentsGrid(hold.documents)
                  else
                    _buildNoDocumentsMessage(),
                  SizedBox(height: isDesktopWeb ? 32 : 24),

                  // Additional Information
                  // _buildSectionTitle('Additional Information'),
                  // _buildDetailCard([
                  //   _buildDetailRow('Agent Name', hold.agentName),
                  //   _buildDetailRow('Created By', hold.createdBy),
                  //   _buildDetailRow('Updated By', hold.updatedBy),
                  // ]),
                  // const SizedBox(height: 24),

                  // Book Now Button (only show if hold is active)
                  if (hold.status.toLowerCase() == 'active' && !hold.isExpired)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: isDesktopWeb ? 24.0 : 16.0),
                      child: SizedBox(
                        width: isDesktopWeb ? 300 : double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HoldBookingScreen(hold: hold),
                              ),
                            );

                            // If booking was successful, refresh the hold data
                            if (result == true && mounted) {
                              await _refreshHoldData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: isDesktopWeb ? 18 : 16,
                              horizontal: isDesktopWeb ? 32 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isDesktopWeb ? 12 : 8),
                            ),
                            elevation: isDesktopWeb ? 2 : 1,
                          ),
                          child: Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: isDesktopWeb ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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

  Widget _buildSectionTitle(String title) {
    final isDesktopWeb = _isDesktopWeb(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktopWeb ? 16.0 : 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isDesktopWeb ? 22 : 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTextColor,
          letterSpacing: isDesktopWeb ? 0.5 : 0,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    final isDesktopWeb = _isDesktopWeb(context);
    return Container(
      padding: EdgeInsets.all(isDesktopWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktopWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: isDesktopWeb ? 0.08 : 0.1),
            spreadRadius: isDesktopWeb ? 0 : 1,
            blurRadius: isDesktopWeb ? 8 : 4,
            offset: Offset(0, isDesktopWeb ? 4 : 2),
          ),
        ],
        border: isDesktopWeb ? Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDesktopWeb = _isDesktopWeb(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktopWeb ? 16.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isDesktopWeb ? 180 : 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isDesktopWeb ? 15 : 14,
                color: AppColors.lightGreyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: isDesktopWeb ? 15 : 14,
                color: AppColors.primaryTextColor,
                fontWeight: FontWeight.w400,
                height: isDesktopWeb ? 1.5 : 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(List<hold_document_model.HoldDocument> documents) {
    final isDesktopWeb = _isDesktopWeb(context);
    return Container(
      padding: EdgeInsets.all(isDesktopWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktopWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: isDesktopWeb ? 0.08 : 0.1),
            spreadRadius: isDesktopWeb ? 0 : 1,
            blurRadius: isDesktopWeb ? 8 : 4,
            offset: Offset(0, isDesktopWeb ? 4 : 2),
          ),
        ],
        border: isDesktopWeb ? Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ) : null,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktopWeb ? 4 : 2,
          crossAxisSpacing: isDesktopWeb ? 16 : 12,
          mainAxisSpacing: isDesktopWeb ? 16 : 12,
          childAspectRatio: isDesktopWeb ? 0.85 : 0.9,
        ),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return _buildDocumentThumbnail(documents[index]);
        },
      ),
    );
  }

  Widget _buildNoDocumentsMessage() {
    final isDesktopWeb = _isDesktopWeb(context);
    return Container(
      padding: EdgeInsets.all(isDesktopWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktopWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: isDesktopWeb ? 0.08 : 0.1),
            spreadRadius: isDesktopWeb ? 0 : 1,
            blurRadius: isDesktopWeb ? 8 : 4,
            offset: Offset(0, isDesktopWeb ? 4 : 2),
          ),
        ],
        border: isDesktopWeb ? Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ) : null,
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isDesktopWeb ? 32 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: isDesktopWeb ? 48 : 40,
                color: Colors.grey[400],
              ),
              SizedBox(height: isDesktopWeb ? 12 : 8),
              Text(
                'No documents uploaded',
                style: TextStyle(
                  fontSize: isDesktopWeb ? 16 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentThumbnail(hold_document_model.HoldDocument document) {
    final isDesktopWeb = _isDesktopWeb(context);
    final isPdf = document.documentUrl.toLowerCase().endsWith('.pdf') ||
        document.filetype.toLowerCase() == 'pdf';
    final isImage = document.documentUrl.toLowerCase().endsWith('.jpg') ||
        document.documentUrl.toLowerCase().endsWith('.jpeg') ||
        document.documentUrl.toLowerCase().endsWith('.png') ||
        document.documentUrl.toLowerCase().endsWith('.gif') ||
        document.filetype.toLowerCase() == 'image';
    
    return GestureDetector(
      onTap: () => _openDocument(document.documentUrl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isDesktopWeb ? 12 : 8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isDesktopWeb ? 12 : 8),
                ),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: isImage
                          ? kIsWeb
                              ? WebImageWidget(
                                  imageUrl: document.documentUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  borderRadius: 1,
                                )
                              : Image.network(
                                  document.documentUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 32,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryColor,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : isPdf
                              ? Container(
                                  color: Colors.red[50],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          size: isDesktopWeb ? 40 : 36,
                                          color: Colors.red[400],
                                        ),
                                        SizedBox(height: isDesktopWeb ? 6 : 4),
                                        Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: isDesktopWeb ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file,
                                          size: isDesktopWeb ? 40 : 36,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(height: isDesktopWeb ? 6 : 4),
                                        Text(
                                          'File',
                                          style: TextStyle(
                                            fontSize: isDesktopWeb ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
                    // Transparent overlay to capture taps on web images
                    if (isImage && kIsWeb)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => _openDocument(document.documentUrl),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Document Info
            Padding(
              padding: EdgeInsets.all(isDesktopWeb ? 10 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPdf
                            ? Icons.picture_as_pdf
                            : isImage
                                ? Icons.image
                                : Icons.insert_drive_file,
                        size: isDesktopWeb ? 14 : 12,
                        color: isPdf
                            ? Colors.red
                            : isImage
                                ? AppColors.primaryColor
                                : AppColors.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          document.filetypeDisplay.isNotEmpty
                              ? document.filetypeDisplay
                              : (isPdf ? 'PDF' : isImage ? 'Image' : 'Document'),
                          style: TextStyle(
                            fontSize: isDesktopWeb ? 11 : 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (document.description.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      document.description,
                      style: TextStyle(
                        fontSize: isDesktopWeb ? 10 : 9,
                        color: AppColors.lightGreyColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL is not available'),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      
      // Check if it's a PDF or image
      final isPdf = url.toLowerCase().endsWith('.pdf');
      final isImage = url.toLowerCase().endsWith('.jpg') ||
          url.toLowerCase().endsWith('.jpeg') ||
          url.toLowerCase().endsWith('.png') ||
          url.toLowerCase().endsWith('.gif');
      
      // Check if it's a mobile browser (web but mobile screen size)
      final isMobileBrowser = kIsWeb && Responsive.isMobile(context);
      
      if (kIsWeb && !isMobileBrowser) {
        // On desktop web, open in new tab
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open document'),
            ),
          );
        }
      } else {
        // On mobile browser or native mobile app
        if (isImage) {
          // Show full-screen image viewer for images
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _FullScreenImagePage(imageUrl: url),
            ),
          );
        } else if (isPdf) {
          // Use WebView for PDFs
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: url,
                title: 'Document',
              ),
            ),
          );
        } else {
          // Open other files in browser
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to open document'),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
        ),
      );
    }
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Image Preview',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Full screen image viewer with zoom and pan
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
                      borderRadius: 1,
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
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading image...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

