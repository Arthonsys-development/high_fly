import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../../../config/constant/app_colors.dart';
import '../../global/widgets/common_app_bar.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf') || 
           url.toLowerCase().contains('.pdf?');
  }

  String _getPdfViewerUrl(String pdfUrl) {
    // Use Google Docs Viewer for PDFs
    return 'https://docs.google.com/viewer?url=${Uri.encodeComponent(pdfUrl)}&embedded=true';
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // For web, we'll use universal_html to open in new window
      // This is a workaround since webview_flutter doesn't work on web
    } else {
      String urlToLoad = widget.url;
      
      // If it's a PDF, use Google Docs Viewer
      if (_isPdfUrl(widget.url)) {
        urlToLoad = _getPdfViewerUrl(widget.url);
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.description}');
              debugPrint('Error code: ${error.errorCode}');
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load document: ${error.description}';
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;
              
              // Handle intent:// URLs (Android deep links that WebView can't handle)
              if (url.startsWith('intent://')) {
                debugPrint('Intercepted intent:// URL: $url');
                
                // Try to extract the fallback URL from the intent:// URL
                // Format: intent://...S.browser_fallback_url=https%3A%2F%2F...;end
                // Or: intent://...#Intent;scheme=https;package=...;S.browser_fallback_url=...;end
                try {
                  // Try multiple regex patterns to catch different URL formats
                  final patterns = [
                    r'S\.browser_fallback_url=([^;]+)',
                    r'browser_fallback_url=([^;]+)',
                    r'fallback_url=([^;]+)',
                  ];
                  
                  String? fallbackUrl;
                  for (final pattern in patterns) {
                    final match = RegExp(pattern).firstMatch(url);
                    if (match != null) {
                      final encodedUrl = match.group(1);
                      if (encodedUrl != null) {
                        try {
                          fallbackUrl = Uri.decodeComponent(encodedUrl);
                          debugPrint('Extracted fallback URL using pattern $pattern: $fallbackUrl');
                          break;
                        } catch (e) {
                          debugPrint('Error decoding URL: $e');
                        }
                      }
                    }
                  }
                  
                  if (fallbackUrl != null && fallbackUrl.startsWith('http')) {
                    debugPrint('Loading fallback URL: $fallbackUrl');
                    _controller.loadRequest(Uri.parse(fallbackUrl));
                    return NavigationDecision.prevent;
                  }
                } catch (e) {
                  debugPrint('Error parsing intent URL: $e');
                }
                
                // If we can't extract fallback, prevent navigation
                debugPrint('Intent URL without extractable fallback');
                return NavigationDecision.prevent;
              }
              
              // Block other non-http/https schemes
              if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('data:') && !url.startsWith('about:')) {
                debugPrint('Blocked non-http URL: $url');
                return NavigationDecision.prevent;
              }
              
              // Allow all other navigation
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(urlToLoad));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web platform, open in new window/tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        html.window.open(widget.url, '_blank');
        Navigator.of(context).pop();
      });
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: commonAppBar(context, widget.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: commonAppBar(context, widget.title),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Try to open in external browser as fallback
                        final uri = Uri.parse(widget.url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to open document'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in Browser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

