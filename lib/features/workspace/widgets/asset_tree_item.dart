import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/datasources/objectbox/entities/asset.dart';

/// 资产树项组件
/// 在文档树中显示资产项
/// Requirements: 1.5
class AssetTreeItem extends StatelessWidget {
  final Asset asset;
  final int depth;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const AssetTreeItem({
    super.key,
    required this.asset,
    this.depth = 0,
    this.isSelected = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 12.0 + (depth * 16.0),
          right: 8,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatFileSize(asset.fileSize),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (asset.type == AssetType.image) _buildThumbnail(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (asset.type) {
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }

  Widget _buildThumbnail() {
    final file = File(asset.filePath);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: Icon(
                Icons.broken_image,
                size: 16,
                color: Colors.grey.shade400,
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 资产分组头部组件
class AssetGroupHeader extends StatelessWidget {
  final AssetType type;
  final int count;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const AssetGroupHeader({
    super.key,
    required this.type,
    required this.count,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            _buildTypeIcon(),
            const SizedBox(width: 8),
            Text(
              _getTypeName(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (type) {
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

    return Icon(icon, size: 16, color: color);
  }

  String _getTypeName() {
    switch (type) {
      case AssetType.image:
        return '图片';
      case AssetType.pdf:
        return 'PDF';
      case AssetType.audio:
        return '音频';
      case AssetType.video:
        return '视频';
      case AssetType.other:
        return '其他';
    }
  }
}
