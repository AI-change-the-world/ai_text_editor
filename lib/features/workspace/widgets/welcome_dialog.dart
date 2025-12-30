import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:daynightbanner/daynightbanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../init.dart';
import '../../../notifiers/app_body_notifier.dart';
import '../../../notifiers/editor_notifier.dart';
import '../../../objectbox/recent_files.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/toast_utils.dart';

/// 新闻项模型
class NewsItem {
  final String title;
  final String url;

  NewsItem({required this.title, required this.url});

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

/// 新闻数据 Provider
final newsProvider = FutureProvider.autoDispose<List<NewsItem>>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('https://newsnow.busiyi.world/api/s?id=weibo&latest'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Charset': 'utf-8',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      // 确保使用 UTF-8 解码
      final bodyString = utf8.decode(response.bodyBytes);
      final data = json.decode(bodyString);
      if (data['status'] == 'success' || data['status'] == 'cache') {
        final items = (data['items'] as List?)
                ?.take(10)
                .map((item) => NewsItem.fromJson(item))
                .where((item) => item.title.isNotEmpty)
                .toList() ??
            [];
        return items;
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// 启动欢迎弹窗
class WelcomeDialog extends ConsumerStatefulWidget {
  const WelcomeDialog({super.key});

  @override
  ConsumerState<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends ConsumerState<WelcomeDialog> {
  final List<Color> hourlyColors = _generateHourlyColors();
  final List<Color> hourlyTextColors = _generateHourlyTextColors();

  static List<Color> _generateHourlyColors() {
    List<Color> colors = [];
    for (int hour = 0; hour < 24; hour++) {
      if (hour >= 6 && hour < 18) {
        colors.add(
            Color.lerp(Colors.blueGrey.shade900, Colors.black, hour / 24)!);
      } else {
        colors.add(
            Color.lerp(Colors.yellow.shade200, Colors.white, (hour - 6) / 24)!);
      }
    }
    return colors;
  }

  static List<Color> _generateHourlyTextColors() {
    List<Color> colors = [];
    for (int hour = 0; hour < 24; hour++) {
      if (hour >= 6 && hour < 18) {
        colors.add(
            Color.lerp(Colors.yellow.shade200, Colors.white, (hour - 6) / 24)!);
      } else {
        colors.add(
            Color.lerp(Colors.blueGrey.shade900, Colors.black, hour / 24)!);
      }
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final appBodyState = ref.watch(appBodyProvider);
    final recentFiles = ref.watch(recentFilesProvider);
    final newsAsync = ref.watch(newsProvider);
    // final size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 720,
          height: 500,
          decoration: BoxDecoration(
            color: colors.dialogBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // 左侧面板
                SizedBox(
                  width: 280,
                  child: _buildLeftPanel(appBodyState, recentFiles, colors),
                ),
                // 右侧：今日热点
                Expanded(
                  child: _buildNewsPanel(newsAsync, colors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(AppBodyState appBodyState,
      List<RecentFiles> recentFiles, AppColors colors) {
    final recentTwo = recentFiles.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text.rich(
            TextSpan(
              text: "${APPConfig.appName}\n",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary),
              children: [
                TextSpan(
                  text: "Enjoy writing with AI",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: colors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // DayNightBanner
          _buildDayNightBanner(appBodyState),
          const SizedBox(height: 12),
          // 名言
          Expanded(child: _buildQuote(appBodyState, colors)),
          // 近期文件
          if (recentTwo.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...recentTwo.map((file) => _buildRecentFileLink(file, colors)),
          ],
          const SizedBox(height: 12),
          // 进入按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.dialogBackground,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('进入工作空间'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNightBanner(AppBodyState state) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DayNightBanner(
              widthOfSunMoon: 36,
              bannerHeight: 140,
              backgroundImageHeight: 140,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
              hour: state.current.hour,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: hourlyColors[state.current.hour],
              ),
              child: Text(
                "${_formatTime(state.current.hour)} : ${_formatTime(state.current.minute)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: hourlyTextColors[state.current.hour],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote(AppBodyState state, AppColors colors) {
    if (state.word.isEmpty) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: state.isLoading ? 0 : 1,
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoSizeText(
            state.word,
            minFontSize: 12,
            maxFontSize: 14,
            maxLines: 3,
            style: TextStyle(
              fontFamily: state.region == "中国" ? "song" : null,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          if (state.from.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "—— ${state.from}",
                style: TextStyle(fontSize: 11, color: colors.textHint),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewsPanel(
      AsyncValue<List<NewsItem>> newsAsync, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  color: colors.warning, size: 22),
              const SizedBox(width: 8),
              Text("今日热点",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          // 新闻列表
          Expanded(
            child: newsAsync.when(
              data: (news) => news.isEmpty
                  ? Center(
                      child: Text('暂无热点',
                          style: TextStyle(color: colors.textHint)))
                  : ListView.builder(
                      itemCount: news.length,
                      itemBuilder: (context, index) =>
                          _buildNewsItem(index + 1, news[index], colors),
                    ),
              loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => Center(
                  child:
                      Text('加载失败', style: TextStyle(color: colors.textHint))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(int rank, NewsItem news, AppColors colors) {
    final isTop3 = rank <= 3;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openUrl(news.url),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isTop3
                ? colors.warning.withValues(alpha: 0.1)
                : colors.surfaceVariant,
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isTop3 ? colors.warning : colors.textHint,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                        color: colors.dialogBackground,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  news.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isTop3 ? FontWeight.w500 : FontWeight.normal,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int value) => value < 10 ? "0$value" : "$value";

  Widget _buildRecentFileLink(RecentFiles file, AppColors colors) {
    final fileName = file.path.split(Platform.pathSeparator).last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openFile(file),
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colors.primary,
              decoration: TextDecoration.underline,
              decorationColor: colors.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _openFile(RecentFiles recentFile) {
    final file = File(recentFile.path);
    if (file.existsSync()) {
      ref.read(editorNotifierProvider.notifier).loadFromFile(file).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
          context.go('/editor');
        }
      });
    } else {
      if (mounted) {
        ToastUtils.error(context, title: '文件不存在');
      }
    }
  }

  void _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 显示欢迎弹窗
Future<void> showWelcomeDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'welcome-dialog',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: const WelcomeDialog(),
      );
    },
  );
}
