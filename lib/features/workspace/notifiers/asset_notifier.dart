import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/asset.dart';
import '../../../services/asset_service.dart';
import 'workspace_notifier.dart';

/// 资产状态
class AssetState {
  final List<Asset> assets;
  final String? selectedAssetId;
  final bool isLoading;
  final String? error;

  const AssetState({
    this.assets = const [],
    this.selectedAssetId,
    this.isLoading = false,
    this.error,
  });

  AssetState copyWith({
    List<Asset>? assets,
    String? selectedAssetId,
    bool? isLoading,
    String? error,
    bool clearSelectedAsset = false,
  }) {
    return AssetState(
      assets: assets ?? this.assets,
      selectedAssetId:
          clearSelectedAsset ? null : (selectedAssetId ?? this.selectedAssetId),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 资产状态管理
/// Requirements: 1.5
class AssetNotifier extends Notifier<AssetState> {
  late final AssetService _assetService;

  @override
  AssetState build() {
    _assetService = AssetService.instance;

    // 监听工作空间变化
    ref.listen(workspaceProvider, (previous, next) {
      if (previous?.currentWorkspace?.uuid != next.currentWorkspace?.uuid) {
        loadAssets();
      }
    });

    // 初始加载
    loadAssets();
    return const AssetState(isLoading: true);
  }

  /// 加载当前工作空间的资产
  Future<void> loadAssets() async {
    final workspaceState = ref.read(workspaceProvider);
    final currentWorkspace = workspaceState.currentWorkspace;

    if (currentWorkspace == null) {
      state = const AssetState(assets: [], isLoading: false);
      return;
    }

    try {
      state = state.copyWith(isLoading: true);
      final assets =
          await _assetService.getWorkspaceAssets(currentWorkspace.uuid);
      state = state.copyWith(
        assets: assets,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 选择资产
  void selectAsset(String assetId) {
    state = state.copyWith(selectedAssetId: assetId);
  }

  /// 清除选择
  void clearSelection() {
    state = state.copyWith(clearSelectedAsset: true);
  }

  /// 删除资产
  Future<void> deleteAsset(String assetId) async {
    try {
      await _assetService.deleteAsset(assetId);
      if (state.selectedAssetId == assetId) {
        state = state.copyWith(clearSelectedAsset: true);
      }
      await loadAssets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 添加资产到状态（上传后调用）
  void addAssets(List<Asset> newAssets) {
    final updatedAssets = [...state.assets, ...newAssets];
    state = state.copyWith(assets: updatedAssets);
  }

  /// 获取按类型分组的资产
  Map<AssetType, List<Asset>> get assetsByType {
    final grouped = <AssetType, List<Asset>>{};
    for (final asset in state.assets) {
      grouped.putIfAbsent(asset.type, () => []).add(asset);
    }
    return grouped;
  }
}

/// 资产 Provider
final assetProvider =
    NotifierProvider<AssetNotifier, AssetState>(AssetNotifier.new);
