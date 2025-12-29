import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/deep_search_service.dart';

/// Deep Search 状态
class DeepSearchState {
  /// 当前搜索查询
  final String query;

  /// 搜索引擎
  final SearchEngine engine;

  /// 搜索结果
  final DeepSearchResult? result;

  /// 是否正在搜索
  final bool isSearching;

  /// 是否正在提取内容
  final bool isExtracting;

  /// 当前提取的 URL
  final String? extractingUrl;

  /// 提取的内容
  final ExtractedContent? extractedContent;

  /// 错误信息
  final String? error;

  /// 当前加载的 URL (用于 WebView)
  final String? currentUrl;

  /// 是否显示 WebView
  final bool showWebView;

  const DeepSearchState({
    this.query = '',
    this.engine = SearchEngine.duckDuckGo,
    this.result,
    this.isSearching = false,
    this.isExtracting = false,
    this.extractingUrl,
    this.extractedContent,
    this.error,
    this.currentUrl,
    this.showWebView = false,
  });

  DeepSearchState copyWith({
    String? query,
    SearchEngine? engine,
    DeepSearchResult? result,
    bool? isSearching,
    bool? isExtracting,
    String? extractingUrl,
    ExtractedContent? extractedContent,
    String? error,
    String? currentUrl,
    bool? showWebView,
    bool clearResult = false,
    bool clearExtractedContent = false,
    bool clearError = false,
  }) {
    return DeepSearchState(
      query: query ?? this.query,
      engine: engine ?? this.engine,
      result: clearResult ? null : (result ?? this.result),
      isSearching: isSearching ?? this.isSearching,
      isExtracting: isExtracting ?? this.isExtracting,
      extractingUrl: extractingUrl ?? this.extractingUrl,
      extractedContent: clearExtractedContent
          ? null
          : (extractedContent ?? this.extractedContent),
      error: clearError ? null : (error ?? this.error),
      currentUrl: currentUrl ?? this.currentUrl,
      showWebView: showWebView ?? this.showWebView,
    );
  }
}

/// Deep Search Notifier
class DeepSearchNotifier extends StateNotifier<DeepSearchState> {
  final IDeepSearchService _deepSearchService;

  DeepSearchNotifier(this._deepSearchService) : super(const DeepSearchState());

  /// 设置搜索引擎
  void setEngine(SearchEngine engine) {
    state = state.copyWith(engine: engine);
  }

  /// 执行搜索
  Future<void> search(String query, {int maxResults = 10}) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(
      query: query,
      isSearching: true,
      clearError: true,
      clearResult: true,
    );

    try {
      final result = await _deepSearchService.search(
        query,
        engine: state.engine,
        maxResults: maxResults,
      );

      state = state.copyWith(
        result: result,
        isSearching: false,
      );

      if (!result.success) {
        state = state.copyWith(error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
      );
    }
  }

  /// 提取网页内容
  Future<void> extractContent(String url) async {
    state = state.copyWith(
      isExtracting: true,
      extractingUrl: url,
      clearExtractedContent: true,
      clearError: true,
    );

    try {
      final content = await _deepSearchService.extractContent(url);
      state = state.copyWith(
        isExtracting: false,
        extractedContent: content,
      );
    } catch (e) {
      state = state.copyWith(
        isExtracting: false,
        error: e.toString(),
      );
    }
  }

  /// 保存到知识库
  Future<bool> saveToKnowledgeBase(
    String workspaceId, {
    List<String>? tags,
  }) async {
    if (state.extractedContent == null) return false;

    try {
      await _deepSearchService.saveToKnowledgeBase(
        workspaceId,
        state.extractedContent!,
        tags: tags,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// 打开 URL 在 WebView 中
  void openInWebView(String url) {
    state = state.copyWith(
      currentUrl: url,
      showWebView: true,
    );
  }

  /// 关闭 WebView
  void closeWebView() {
    state = state.copyWith(
      showWebView: false,
    );
  }

  /// 清除状态
  void clear() {
    state = const DeepSearchState();
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Deep Search Provider
final deepSearchServiceProvider = Provider<IDeepSearchService>((ref) {
  return DeepSearchService.instance;
});

final deepSearchNotifierProvider =
    StateNotifierProvider<DeepSearchNotifier, DeepSearchState>((ref) {
  final service = ref.watch(deepSearchServiceProvider);
  return DeepSearchNotifier(service);
});
