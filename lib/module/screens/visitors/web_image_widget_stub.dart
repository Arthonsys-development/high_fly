import 'package:flutter/material.dart';

/// Stub implementation of WebImageWidget for mobile platforms
/// Uses standard Image.network instead of HtmlElementView
class WebImageWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double? borderRadius;
  final BoxFit fit;

  const WebImageWidget({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(Icons.person, size: height * 0.6, color: Colors.grey[400]),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            height: height * 0.4,
            width: width * 0.4,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              value: null,
            ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: image,
      );
    }

    return image;
  }
}

