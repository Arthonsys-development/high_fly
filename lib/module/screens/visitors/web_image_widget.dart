import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui_web' if (dart.library.io) 'web_ui_stub.dart';
import 'package:universal_html/html.dart' as html;

/// Web-specific image widget using HtmlElementView with native img element for better CORS handling
class WebImageWidget extends StatefulWidget {
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
  State<WebImageWidget> createState() => WebImageWidgetState();
}

class WebImageWidgetState extends State<WebImageWidget> {
  String? _viewId;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId = 'img-${DateTime.now().millisecondsSinceEpoch}-${widget.imageUrl.hashCode}';
      _createImageElement();
    }
  }

  void _createImageElement() {
    if (!kIsWeb || _viewId == null) return;

    try {
      // Create a platform view factory
      // ignore: undefined_identifier
      platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) {
          final img = html.ImageElement()
            ..src = widget.imageUrl
            ..style.width = '${widget.width}px'
            ..style.height = '${widget.height}px'
            ..style.objectFit = 'cover'
            ..style.borderRadius = '50%'
            ..crossOrigin = 'anonymous' // Try to handle CORS
            ..onError.listen((_) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
              debugPrint('❌ Image failed to load: ${widget.imageUrl}');
            })
            ..onLoad.listen((_) {
              if (mounted) {
                setState(() {
                  _hasError = false;
                });
              }
            });

          return img;
        },
      );
    } catch (e) {
      debugPrint('Error creating image element: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _viewId == null || _hasError) {
      return Center(
        child: Icon(
          Icons.person,
          size: widget.height * 0.6,
          color: Colors.grey[400],
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewId!),
    );
  }
}

