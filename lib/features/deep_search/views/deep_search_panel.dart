import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/deep_search_service.dart';
import '../notifiers/deep_search_notifier.dart';
import '../widgets/deep_search_input.dart';
import '../widgets/search_result_list.dart';
import '../widgets/webview_container.dart';
import '../widgets/content_extraction_dialog.dart';

/// Deep Search Panel - Main panel for web search functionality
/// Requirements: 6.1
class DeepSearchPanel extends ConsumerStatefulWidget {
  const DeepSearchPanel({super.key});

  @override
  ConsumerState<DeepSearchPanel> createState() => _DeepSearchPanelState();
}

class _DeepSearchPanelState extends ConsumerState<DeepSearchPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deepSearchNotifierProvider);

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Backdrop - tap to close
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Panel
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.85,
              constraints: const BoxConstraints(
                maxWidth: 1200,
                maxHeight: 900,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(context),
                  // Divider
                  const Divider(height: 1),
                  // Main content
                  Expanded(
                    child: state.showWebView
                        ? _buildWebViewLayout(context, state)
                        : _buildSearchLayout(context, state),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final state = ref.watch(deepSearchNotifierProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.travel_explore,
            color: Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Deep Search',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 16),
          // Search engine selector
          _buildEngineSelector(context, state),
          const Spacer(),
          // Back button when in WebView
          if (state.showWebView)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              tooltip: '返回搜索结果',
              onPressed: () {
                ref.read(deepSearchNotifierProvider.notifier).closeWebView();
              },
            ),
          // Clear button
          if (state.result != null && !state.showWebView)
            IconButton(
              icon: const Icon(Icons.clear_all, size: 20),
              tooltip: '清除结果',
              onPressed: () {
                ref.read(deepSearchNotifierProvider.notifier).clear();
              },
            ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: '关闭 (Esc)',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSelector(BuildContext context, DeepSearchState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SearchEngine>(
          value: state.engine,
          isDense: true,
          items: const [
            DropdownMenuItem(
              value: SearchEngine.duckDuckGo,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 16),
                  SizedBox(width: 4),
                  Text('DuckDuckGo', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: SearchEngine.google,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 16),
                  SizedBox(width: 4),
                  Text('Google', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: SearchEngine.bing,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 16),
                  SizedBox(width: 4),
                  Text('Bing', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
          onChanged: (engine) {
            if (engine != null) {
              ref.read(deepSearchNotifierProvider.notifier).setEngine(engine);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchLayout(BuildContext context, DeepSearchState state) {
    return Column(
      children: [
        // Search input
        const DeepSearchInput(),
        // Error message
        if (state.error != null) _buildErrorBanner(context, state),
        // Results or empty state
        Expanded(
          child: state.isSearching
              ? _buildLoadingState(context)
              : state.result != null
                  ? SearchResultList(
                      result: state.result!,
                      onItemTap: (item) {
                        ref
                            .read(deepSearchNotifierProvider.notifier)
                            .openInWebView(item.url);
                      },
                      onExtractContent: (item) async {
                        await ref
                            .read(deepSearchNotifierProvider.notifier)
                            .extractContent(item.url);
                        if (mounted) {
                          _showContentExtractionDialog(context);
                        }
                      },
                    )
                  : _buildEmptyState(context),
        ),
      ],
    );
  }

  Widget _buildWebViewLayout(BuildContext context, DeepSearchState state) {
    return Column(
      children: [
        // URL bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.currentUrl ?? '',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Extract content button
              ElevatedButton.icon(
                onPressed: state.isExtracting
                    ? null
                    : () async {
                        if (state.currentUrl != null) {
                          await ref
                              .read(deepSearchNotifierProvider.notifier)
                              .extractContent(state.currentUrl!);
                          if (mounted) {
                            _showContentExtractionDialog(context);
                          }
                        }
                      },
                icon: state.isExtracting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(state.isExtracting ? '提取中...' : '提取内容'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        // WebView
        Expanded(
          child: WebViewContainer(
            url: state.currentUrl ?? '',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '正在搜索...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.travel_explore,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '开始深度搜索',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入关键词搜索互联网，提取网页内容并保存到知识库',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, DeepSearchState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 16),
            onPressed: () {
              ref.read(deepSearchNotifierProvider.notifier).clearError();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showContentExtractionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ContentExtractionDialog(),
    );
  }
}

/// Provider for showing/hiding the Deep Search panel
final deepSearchPanelVisibleProvider = StateProvider<bool>((ref) => false);

/// Show Deep Search panel as an overlay
void showDeepSearchPanel(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const DeepSearchPanel(),
  );
}
