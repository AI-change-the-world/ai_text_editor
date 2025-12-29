import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/asset.dart';
import '../../../services/asset_service.dart';

/// 资产查看器组件
/// 显示资产预览、提取的元数据和文本内容
/// Requirements: 3.4
class AssetViewer extends ConsumerStatefulWidget {
  final Asset asset;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  const AssetViewer({
    super.key,
    required this.asset,
    this.onClose,
    this.onDelete,
  });

  @override
  ConsumerState<AssetViewer> createState() => _AssetViewerState();
}

class _AssetViewerState extends ConsumerState<AssetViewer> {
  bool _isLoadingOCR = false;
  String? _ocrError;
  String? _extractedText;
  bool _isLoadingPreview = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoadingPreview = true;
    });

    try {
      final preview =
          await AssetService.instance.getAssetPreview(widget.asset.uuid);
      if (mounted) {
        setState(() {
          _extractedText = preview.extractedText;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          _buildAssetTypeIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.asset.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(widget.asset.fileSize),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
              tooltip: '关闭',
            ),
        ],
      ),
    );
  }

  Widget _buildAssetTypeIcon() {
    IconData icon;
    Color color;

    switch (widget.asset.type) {
      case AssetType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case AssetType.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case AssetType.audio:
        icon = Icons.audiotrack;
        color = Colors.purple;
        break;
      case AssetType.video:
        icon = Icons.videocam;
        color = Colors.orange;
        break;
      case AssetType.other:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildContent() {
    if (_isLoadingPreview) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 预览区域
          _buildPreviewSection(),
          const SizedBox(height: 16),
          // 元数据区域
          _buildMetadataSection(),
          const SizedBox(height: 16),
          // 提取的文本区域
          if (widget.asset.type == AssetType.image ||
              widget.asset.type == AssetType.pdf)
            _buildExtractedTextSection(),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    switch (widget.asset.type) {
      case AssetType.image:
        return _buildImagePreview();
      case AssetType.pdf:
        return _buildPdfPreview();
      case AssetType.audio:
        return _buildAudioPreview();
      case AssetType.video:
        return _buildVideoPreview();
      case AssetType.other:
        return _buildGenericPreview();
    }
  }

  Widget _buildImagePreview() {
    final file = File(widget.asset.filePath);

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPlaceholder('无法加载图片');
                },
              )
            : _buildErrorPlaceholder('文件不存在'),
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'PDF 文档',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.asset.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack,
              size: 48,
              color: Colors.purple.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              '音频文件',
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam,
              size: 64,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              '视频文件',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              widget.asset.mimeType,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      height: 200,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(widget.asset.createdAt);
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.asset.updatedAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '文件信息',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetadataRow('类型', widget.asset.mimeType),
          _buildMetadataRow('大小', _formatFileSize(widget.asset.fileSize)),
          _buildMetadataRow('创建时间', _formatDateTime(createdAt)),
          _buildMetadataRow('更新时间', _formatDateTime(updatedAt)),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedTextSection() {
    // Use _extractedText if available (from preview), otherwise fall back to asset
    final extractedText = _extractedText ?? widget.asset.extractedText;
    final hasExtractedText = extractedText != null && extractedText.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '提取的文本',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.asset.type == AssetType.image && !hasExtractedText)
                TextButton.icon(
                  onPressed: _isLoadingOCR ? null : _performOCR,
                  icon: _isLoadingOCR
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner, size: 18),
                  label: Text(_isLoadingOCR ? '识别中...' : 'OCR 识别'),
                ),
              if (hasExtractedText)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(extractedText),
                  tooltip: '复制文本',
                ),
            ],
          ),
          if (_ocrError != null) ...[
            const SizedBox(height: 8),
            Text(
              _ocrError!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
          ],
          if (hasExtractedText) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  extractedText,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ] else if (!_isLoadingOCR && _ocrError == null) ...[
            const SizedBox(height: 8),
            Text(
              '暂无提取的文本内容',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.onDelete != null)
            TextButton.icon(
              onPressed: () => _confirmDelete(),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('删除'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _openInExternalApp,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('打开'),
          ),
        ],
      ),
    );
  }

  Future<void> _performOCR() async {
    setState(() {
      _isLoadingOCR = true;
      _ocrError = null;
    });

    try {
      await AssetService.instance.ocrImage(widget.asset.uuid);
      // 重新加载预览以获取更新的提取文本
      await _loadPreview();
    } catch (e) {
      if (mounted) {
        setState(() {
          _ocrError = 'OCR 识别失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOCR = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openInExternalApp() async {
    // 使用系统默认应用打开文件
    // 这里可以使用 open_file 或 url_launcher 包
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在打开文件...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${widget.asset.name}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 显示资产查看器对话框
/// Requirements: 3.4
Future<void> showAssetViewerDialog(
  BuildContext context,
  Asset asset, {
  VoidCallback? onDelete,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 600,
        height: 700,
        child: AssetViewer(
          asset: asset,
          onClose: () => Navigator.of(context).pop(),
          onDelete: onDelete != null
              ? () {
                  Navigator.of(context).pop();
                  onDelete();
                }
              : null,
        ),
      ),
    ),
  );
}
