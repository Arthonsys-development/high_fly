import 'package:flutter/material.dart';

/// Stub implementation of WebImageWidget for mobile platforms
/// Uses standard Image.network instead of HtmlElementView
class WebImageWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const WebImageWidget({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
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
  }
}

