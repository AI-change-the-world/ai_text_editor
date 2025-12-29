import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView container for displaying web pages
/// Requirements: 6.3
class WebViewContainer extends StatefulWidget {
  /// The URL to load in the WebView
  final String url;

  /// Callback when page starts loading
  final VoidCallback? onPageStarted;

  /// Callback when page finishes loading
  final VoidCallback? onPageFinished;

  /// Callback when navigation is requested
  final void Function(String url)? onNavigationRequest;

  const WebViewContainer({
    super.key,
    required this.url,
    this.onPageStarted,
    this.onPageFinished,
    this.onNavigationRequest,
  });

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(WebViewContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && widget.url.isNotEmpty) {
      _loadUrl(widget.url);
    }
  }

  void _initWebView() {
    // WebView is only supported on mobile and desktop platforms
    if (kIsWeb) {
      setState(() {
        _error = 'WebView is not supported on web platform';
      });
      return;
    }

    // Check platform support
    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isMacOS &&
        !Platform.isWindows) {
      setState(() {
        _error = 'WebView is not supported on this platform';
      });
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0;
            });
            widget.onPageStarted?.call();
          },
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _loadingProgress = 1;
            });
            widget.onPageFinished?.call();
          },
          onWebResourceError: (error) {
            setState(() {
              _error = 'Failed to load page: ${error.description}';
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            widget.onNavigationRequest?.call(request.url);
            return NavigationDecision.navigate;
          },
        ),
      );

    if (widget.url.isNotEmpty) {
      _loadUrl(widget.url);
    }
  }

  void _loadUrl(String url) {
    if (_controller == null) return;

    setState(() {
      _error = null;
      _isLoading = true;
      _loadingProgress = 0;
    });

    _controller!.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorState(context);
    }

    if (_controller == null) {
      return _buildUnsupportedState(context);
    }

    return Stack(
      children: [
        // WebView
        WebViewWidget(controller: _controller!),
        // Loading indicator
        if (_isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (widget.url.isNotEmpty) {
                _loadUrl(widget.url);
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.web_asset_off,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'WebView 不可用',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前平台不支持内嵌网页浏览',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple WebView for displaying a URL with minimal controls
class SimpleWebView extends StatelessWidget {
  final String url;
  final double? height;

  const SimpleWebView({
    super.key,
    required this.url,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 400,
      child: WebViewContainer(url: url),
    );
  }
}
