import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/response_model/project_response_model.dart';
import '../../global/widgets/common_app_bar.dart';
import '../bookings/webview_screen.dart';
import '../visitors/web_image_widget.dart'
    if (dart.library.io) '../visitors/web_image_widget_stub.dart';

class ProjectGalleryScreen extends StatelessWidget {
  final String projectName;
  final List<GalleryFile> galleryFiles;

  const ProjectGalleryScreen({
    super.key,
    required this.projectName,
    required this.galleryFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: commonAppBar(
          context,
          'Gallery',
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppColors.textFieldBGColor,
      body: galleryFiles.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No gallery files available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${galleryFiles.length} ${galleryFiles.length == 1 ? 'file' : 'files'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: galleryFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _GalleryFileCard(
                          file: galleryFiles[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GalleryFileCard extends StatefulWidget {
  final GalleryFile file;

  const _GalleryFileCard({required this.file});

  @override
  State<_GalleryFileCard> createState() => _GalleryFileCardState();
}

class _GalleryFileCardState extends State<_GalleryFileCard> {
  bool _isSharing = false;
  // null  → not downloading, 0.0–1.0 → download in progress
  double? _downloadProgress;

  GalleryFile get _file => widget.file;

  bool get _isPdf =>
      _file.fileType.toLowerCase() == 'pdf' ||
      _file.fileUrl.toLowerCase().endsWith('.pdf') ||
      _file.fileName.toLowerCase().endsWith('.pdf');

  bool get _isImage =>
      _file.fileType.toLowerCase() == 'image' ||
      _file.fileUrl.toLowerCase().endsWith('.jpg') ||
      _file.fileUrl.toLowerCase().endsWith('.jpeg') ||
      _file.fileUrl.toLowerCase().endsWith('.png') ||
      _file.fileUrl.toLowerCase().endsWith('.gif') ||
      _file.fileUrl.toLowerCase().endsWith('.webp');

  // thumbnail_url takes priority; fall back to thumbnail, then file_url for images
  String get _thumbnailUrl =>
      _file.thumbnailUrl?.isNotEmpty == true
          ? _file.thumbnailUrl!
          : (_file.thumbnail?.isNotEmpty == true ? _file.thumbnail! : '');

  bool get _hasThumbnail => _thumbnailUrl.isNotEmpty;

  String get _openUrl => _file.fileUrl.isNotEmpty ? _file.fileUrl : _file.file;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview area — show thumbnail if available (works for both images and PDFs),
          // fall back to placeholder for PDFs or inline image for plain image files.
          GestureDetector(
            onTap: () => _openFile(context),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: _hasThumbnail
                  ? _buildNetworkImage(_thumbnailUrl)
                  : (_isImage
                      ? _buildNetworkImage(
                          _file.fileUrl.isNotEmpty ? _file.fileUrl : _file.file)
                      : _buildPdfPlaceholder()),
            ),
          ),

          // File info and action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File name
                Text(
                  _file.title?.isNotEmpty == true
                      ? _file.title!
                      : (_file.fileName.isNotEmpty
                          ? _file.fileName
                          : 'Unnamed File'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_file.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    _file.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Type badge + size
                Row(
                  children: [
                    if (_file.fileType.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.image_outlined,
                              size: 12,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _file.fileType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_file.fileSizeDisplay.isNotEmpty)
                      Text(
                        _file.fileSizeDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openFile(context),
                        icon: Icon(
                          _isPdf ? Icons.picture_as_pdf : Icons.open_in_new,
                          size: 16,
                        ),
                        label: Text(_isPdf ? 'Open PDF' : 'Open'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSharing ? null : () => _shareFile(context),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share, size: 16),
                        label: Text(_isSharing ? 'Sharing...' : 'Share'),
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
                // Download progress bar — visible only while downloading
                if (_downloadProgress != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            minHeight: 6,
                            backgroundColor:
                                AppColors.primaryColor.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${((_downloadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    return kIsWeb
        ? WebImageWidget(
            imageUrl: url,
            width: double.infinity,
            height: 200,
            borderRadius: 12,
            fit: BoxFit.cover,
          )
        : Image.network(
            url,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPdfPlaceholder(),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: AppColors.primaryColor,
                  ),
                ),
              );
            },
          );
  }

  Widget _buildPdfPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF3F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 48,
            color: AppColors.primaryColor.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF Document',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(BuildContext context) {
    if (_openUrl.isEmpty) return;

    if (_isPdf || kIsWeb) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: _openUrl,
            title: _file.fileName.isNotEmpty ? _file.fileName : 'File',
          ),
        ),
      );
    } else if (_isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _FullScreenImageViewer(imageUrl: _openUrl),
          fullscreenDialog: true,
        ),
      );
    } else {
      _launchUrl(context, _openUrl);
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this file')),
      );
    }
  }

  /// Returns a stable local cache path for the given URL so we reuse
  /// already-downloaded files instead of re-downloading them.
  String _localPathForUrl(String url, Directory cacheDir) {
    final uri = Uri.tryParse(url);
    String fileName = uri?.pathSegments.lastWhere(
          (s) => s.isNotEmpty,
          orElse: () => '',
        ) ??
        '';
    if (fileName.isEmpty) fileName = 'gallery_file';
    // Sanitise the name to avoid path issues
    fileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    return '${cacheDir.path}/$fileName';
  }

  Future<void> _shareFile(BuildContext context) async {
    final url = _openUrl;
    final messenger = ScaffoldMessenger.of(context);

    if (url.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No file URL to share')),
      );
      return;
    }

    setState(() => _isSharing = true);

    try {
      // On web just share the URL text – no file system access.
      if (kIsWeb) {
        final displayName =
            _file.title?.isNotEmpty == true ? _file.title! : _file.fileName;
        await SharePlus.instance.share(
          ShareParams(
            text: displayName.isNotEmpty ? '$displayName\n$url' : url,
            subject: displayName.isNotEmpty ? displayName : 'Gallery File',
          ),
        );
        return;
      }

      final cacheDir = await getTemporaryDirectory();
      final localPath = _localPathForUrl(url, cacheDir);
      final localFile = File(localPath);

      // Download only if not already cached
      if (!localFile.existsSync()) {
        if (mounted) setState(() => _downloadProgress = 0.0);
        await Dio().download(
          url,
          localPath,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => _downloadProgress = received / total);
            }
          },
        );
        if (mounted) setState(() => _downloadProgress = null);
      }

      if (!mounted) return;

      final displayName =
          _file.title?.isNotEmpty == true ? _file.title! : _file.fileName;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(localPath)],
          subject: displayName.isNotEmpty ? displayName : 'Gallery File',
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to share file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _downloadProgress = null;
        });
      }
    }
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
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
                      errorBuilder: (_, __, ___) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 60, color: Colors.white54),
                            SizedBox(height: 12),
                            Text('Failed to load image',
                                style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
