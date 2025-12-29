import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/asset.dart';
import '../notifiers/asset_notifier.dart';
import '../notifiers/workspace_notifier.dart';
import 'asset_tree_item.dart';
import 'asset_upload_dialog.dart';
import 'asset_viewer.dart';

/// 资产区域组件
/// 在文档树下方显示工作空间的资产
/// Requirements: 1.5
class AssetSection extends ConsumerStatefulWidget {
  final Function(Asset asset)? onAssetSelected;
  final Function(Asset asset)? onAssetOpen;

  const AssetSection({
    super.key,
    this.onAssetSelected,
    this.onAssetOpen,
  });

  @override
  ConsumerState<AssetSection> createState() => _AssetSectionState();
}

class _AssetSectionState extends ConsumerState<AssetSection> {
  final Set<AssetType> _expandedTypes = {
    AssetType.image,
    AssetType.pdf,
    AssetType.audio,
    AssetType.video,
    AssetType.other,
  };
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final assetState = ref.watch(assetProvider);
    final workspaceState = ref.watch(workspaceProvider);

    if (workspaceState.currentWorkspace == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, assetState),
          if (_isExpanded) ...[
            if (assetState.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (assetState.assets.isEmpty)
              _buildEmptyState(context)
            else
              _buildAssetList(context, assetState),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AssetState assetState) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
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
              _isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.attach_file,
              size: 16,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '资产',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (assetState.assets.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${assetState.assets.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                Icons.add,
                size: 18,
                color: Colors.grey.shade600,
              ),
              onPressed: () => _showUploadDialog(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: '上传资产',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_upload,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '暂无资产',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _showUploadDialog(context),
            child: const Text('上传资产'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetList(BuildContext context, AssetState assetState) {
    final assetsByType = _groupAssetsByType(assetState.assets);
    final sortedTypes = assetsByType.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedTypes.map((type) {
        final assets = assetsByType[type]!;
        final isTypeExpanded = _expandedTypes.contains(type);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AssetGroupHeader(
              type: type,
              count: assets.length,
              isExpanded: isTypeExpanded,
              onToggle: () {
                setState(() {
                  if (isTypeExpanded) {
                    _expandedTypes.remove(type);
                  } else {
                    _expandedTypes.add(type);
                  }
                });
              },
            ),
            if (isTypeExpanded)
              ...assets
                  .map((asset) => _buildAssetItem(context, asset, assetState)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAssetItem(
    BuildContext context,
    Asset asset,
    AssetState assetState,
  ) {
    final isSelected = assetState.selectedAssetId == asset.uuid;

    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition, asset);
      },
      child: AssetTreeItem(
        asset: asset,
        isSelected: isSelected,
        onTap: () {
          ref.read(assetProvider.notifier).selectAsset(asset.uuid);
          widget.onAssetSelected?.call(asset);
        },
        onDoubleTap: () {
          _showAssetViewer(context, asset);
          widget.onAssetOpen?.call(asset);
        },
      ),
    );
  }

  Map<AssetType, List<Asset>> _groupAssetsByType(List<Asset> assets) {
    final grouped = <AssetType, List<Asset>>{};
    for (final asset in assets) {
      grouped.putIfAbsent(asset.type, () => []).add(asset);
    }
    return grouped;
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Asset asset,
  ) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          height: 36,
          onTap: () => _showAssetViewer(context, asset),
          child: const Row(
            children: [
              Icon(Icons.visibility, size: 16),
              SizedBox(width: 8),
              Text('查看', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        if (asset.type == AssetType.image)
          PopupMenuItem<void>(
            height: 36,
            onTap: () => _performOCR(context, asset),
            child: const Row(
              children: [
                Icon(Icons.document_scanner, size: 16),
                SizedBox(width: 8),
                Text('OCR 识别', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<void>(
          height: 36,
          onTap: () => _confirmDelete(context, asset),
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                '删除',
                style: TextStyle(fontSize: 13, color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showUploadDialog(BuildContext context) async {
    final workspaceState = ref.read(workspaceProvider);
    final currentWorkspace = workspaceState.currentWorkspace;

    if (currentWorkspace == null) return;

    final uploadedAssets = await showAssetUploadDialog(
      context,
      currentWorkspace.uuid,
    );

    if (uploadedAssets != null && uploadedAssets.isNotEmpty) {
      // 刷新资产列表
      ref.read(assetProvider.notifier).loadAssets();
    }
  }

  void _showAssetViewer(BuildContext context, Asset asset) {
    showAssetViewerDialog(
      context,
      asset,
      onDelete: () {
        ref.read(assetProvider.notifier).deleteAsset(asset.uuid);
      },
    );
  }

  Future<void> _performOCR(BuildContext context, Asset asset) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在进行 OCR 识别...'),
        duration: Duration(seconds: 2),
      ),
    );

    // OCR 操作会在 AssetViewer 中进行
    _showAssetViewer(context, asset);
  }

  Future<void> _confirmDelete(BuildContext context, Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${asset.name}" 吗？此操作无法撤销。'),
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

    if (confirmed == true) {
      ref.read(assetProvider.notifier).deleteAsset(asset.uuid);
    }
  }
}
