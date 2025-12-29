import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

/// Link Preview Data Model
class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? favicon;

  LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.favicon,
  });

  bool get hasData => title != null || description != null || imageUrl != null;
}

/// Link Preview Service for fetching metadata
class LinkPreviewService {
  static final Map<String, LinkPreviewData> _cache = {};
  static const Duration _timeout = Duration(seconds: 5);

  /// Fetch link preview data from URL
  static Future<LinkPreviewData> fetchPreview(String url) async {
    // Check cache first
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);

        // Extract Open Graph metadata
        String? title = _getMetaContent(document, 'og:title') ??
            _getMetaContent(document, 'twitter:title') ??
            document.querySelector('title')?.text;

        String? description = _getMetaContent(document, 'og:description') ??
            _getMetaContent(document, 'twitter:description') ??
            _getMetaContent(document, 'description');

        String? imageUrl = _getMetaContent(document, 'og:image') ??
            _getMetaContent(document, 'twitter:image');

        String? siteName =
            _getMetaContent(document, 'og:site_name') ?? uri.host;

        // Get favicon
        String? favicon = _getFavicon(document, uri);

        // Make image URL absolute if relative
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
        }

        final data = LinkPreviewData(
          url: url,
          title: title?.trim(),
          description: description?.trim(),
          imageUrl: imageUrl,
          siteName: siteName,
          favicon: favicon,
        );

        _cache[url] = data;
        return data;
      }
    } catch (e) {
      // Return basic data on error
    }

    final basicData = LinkPreviewData(url: url);
    _cache[url] = basicData;
    return basicData;
  }

  static String? _getMetaContent(dynamic document, String property) {
    final element = document.querySelector('meta[property="$property"]') ??
        document.querySelector('meta[name="$property"]');
    return element?.attributes['content'];
  }

  static String? _getFavicon(dynamic document, Uri uri) {
    final iconLink = document.querySelector('link[rel="icon"]') ??
        document.querySelector('link[rel="shortcut icon"]');

    if (iconLink != null) {
      final href = iconLink.attributes['href'];
      if (href != null) {
        if (href.startsWith('http')) {
          return href;
        }
        return '${uri.scheme}://${uri.host}$href';
      }
    }

    return '${uri.scheme}://${uri.host}/favicon.ico';
  }

  /// Clear the cache
  static void clearCache() {
    _cache.clear();
  }
}

/// Link Preview Card Widget
/// Requirements: 2.8 - WHEN a user embeds a link THEN the System SHALL fetch
/// and display a rich preview card with title, description, and thumbnail
class LinkPreviewCard extends StatefulWidget {
  final String url;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool compact;

  const LinkPreviewCard({
    super.key,
    required this.url,
    this.onTap,
    this.onRemove,
    this.compact = false,
  });

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkPreviewData? _previewData;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  @override
  void didUpdateWidget(LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _fetchPreview();
    }
  }

  Future<void> _fetchPreview() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await LinkPreviewService.fetchPreview(widget.url);
      if (mounted) {
        setState(() {
          _previewData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? Colors.blue.withValues(alpha: 0.5)
                  : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError || _previewData == null || !_previewData!.hasData) {
      return _buildFallbackState();
    }

    return widget.compact ? _buildCompactCard() : _buildFullCard();
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.compact ? 60 : 100,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: widget.compact ? 40 : 80,
            height: widget.compact ? 40 : 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackState() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.link,
              size: 20,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.url,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
                decoration: TextDecoration.underline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: widget.onRemove,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactCard() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (_previewData!.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                _previewData!.imageUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFaviconFallback(44),
              ),
            )
          else
            _buildFaviconFallback(44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _previewData!.title ?? widget.url,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _previewData!.siteName ?? Uri.parse(widget.url).host,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: widget.onRemove,
              color: Colors.grey,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_previewData!.imageUrl != null)
            SizedBox(
              width: 120,
              child: Image.network(
                _previewData!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[100],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_previewData!.favicon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Image.network(
                            _previewData!.favicon!,
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.public,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _previewData!.siteName ?? Uri.parse(widget.url).host,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onRemove != null)
                        GestureDetector(
                          onTap: widget.onRemove,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _previewData!.title ?? widget.url,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_previewData!.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _previewData!.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaviconFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: _previewData?.favicon != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                _previewData!.favicon!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.public,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            )
          : const Icon(
              Icons.public,
              size: 20,
              color: Colors.grey,
            ),
    );
  }
}

/// Inline Link Preview (for hover preview)
class InlineLinkPreview extends StatefulWidget {
  final String url;
  final Widget child;

  const InlineLinkPreview({
    super.key,
    required this.url,
    required this.child,
  });

  @override
  State<InlineLinkPreview> createState() => _InlineLinkPreviewState();
}

class _InlineLinkPreviewState extends State<InlineLinkPreview> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovering = false;
  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void dispose() {
    _removeOverlay();
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showOverlay() {
    _hideTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isHovering && mounted) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  void _hideOverlay() {
    _showTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 200), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 24),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: MouseRegion(
              onEnter: (_) {
                _hideTimer?.cancel();
              },
              onExit: (_) {
                _hideOverlay();
              },
              child: LinkPreviewCard(
                url: widget.url,
                compact: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovering = true;
          _showOverlay();
        },
        onExit: (_) {
          _isHovering = false;
          _hideOverlay();
        },
        child: widget.child,
      ),
    );
  }
}
