import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../data/datasources/objectbox/entities/asset.dart';
import '../../../services/asset_service.dart';

/// 支持的文件类型配置
class _SupportedFileTypes {
  static const Map<String, List<String>> typeGroups = {
    '图片': ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
    'PDF': ['pdf'],
    '音频': ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
    '视频': ['mp4', 'mov', 'avi', 'mkv', 'webm'],
  };

  static List<XTypeGroup> get xTypeGroups {
    return typeGroups.entries.map((entry) {
      return XTypeGroup(
        label: entry.key,
        extensions: entry.value,
      );
    }).toList();
  }

  static String getMimeType(String extension) {
    final ext = extension.toLowerCase().replaceFirst('.', '');
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'pdf':
        return 'application/pdf';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}

/// 待上传的文件信息
class _PendingFile {
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final Uint8List? data;
  bool isUploading;
  bool isUploaded;
  String? error;

  _PendingFile({
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.data,
    this.isUploading = false,
    this.isUploaded = false,
    this.error,
  });
}

/// 资产上传对话框
/// 支持拖拽上传和文件选择
/// Requirements: 1.5
class AssetUploadDialog extends ConsumerStatefulWidget {
  final String workspaceId;
  final void Function(List<Asset> assets)? onUploaded;

  const AssetUploadDialog({
    super.key,
    required this.workspaceId,
    this.onUploaded,
  });

  @override
  ConsumerState<AssetUploadDialog> createState() => _AssetUploadDialogState();
}

class _AssetUploadDialogState extends ConsumerState<AssetUploadDialog> {
  final List<_PendingFile> _pendingFiles = [];
  bool _isUploading = false;
  bool _isDragging = false;
  final List<Asset> _uploadedAssets = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child:
                  _pendingFiles.isEmpty ? _buildDropZone() : _buildFileList(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_upload, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          const Text(
            '上传资产',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return DragTarget<List<String>>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragging = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragging = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragging = false);
        _handleDroppedFiles(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isDragging ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDragging ? Colors.blue.shade400 : Colors.grey.shade300,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: InkWell(
            onTap: _selectFiles,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDragging ? Icons.file_download : Icons.cloud_upload,
                    size: 64,
                    color: _isDragging
                        ? Colors.blue.shade400
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isDragging ? '释放以上传文件' : '拖拽文件到此处',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _isDragging
                          ? Colors.blue.shade600
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '或点击选择文件',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSupportedFormats(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportedFormats() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _SupportedFileTypes.typeGroups.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            entry.key,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileList() {
    return Column(
      children: [
        // 添加更多文件按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                '${_pendingFiles.length} 个文件',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _isUploading ? null : _selectFiles,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加更多'),
              ),
            ],
          ),
        ),
        // 文件列表
        Flexible(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            itemCount: _pendingFiles.length,
            itemBuilder: (context, index) {
              return _buildFileItem(_pendingFiles[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(_PendingFile file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: file.error != null
            ? Colors.red.shade50
            : file.isUploaded
                ? Colors.green.shade50
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: file.error != null
              ? Colors.red.shade200
              : file.isUploaded
                  ? Colors.green.shade200
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          _buildFileTypeIcon(file.mimeType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  file.error ?? _formatFileSize(file.size),
                  style: TextStyle(
                    fontSize: 12,
                    color: file.error != null
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (file.isUploading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (file.isUploaded)
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
          else if (file.error != null)
            Icon(Icons.error, color: Colors.red.shade600, size: 20)
          else
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _removeFile(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildFileTypeIcon(String mimeType) {
    IconData icon;
    Color color;

    if (mimeType.startsWith('image/')) {
      icon = Icons.image;
      color = Colors.blue;
    } else if (mimeType == 'application/pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (mimeType.startsWith('audio/')) {
      icon = Icons.audiotrack;
      color = Colors.purple;
    } else if (mimeType.startsWith('video/')) {
      icon = Icons.videocam;
      color = Colors.orange;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildFooter() {
    final hasFiles = _pendingFiles.isNotEmpty;
    final allUploaded = _pendingFiles.every((f) => f.isUploaded);

    return Container(
      padding: const EdgeInsets.all(20),
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
          if (hasFiles && !allUploaded)
            TextButton(
              onPressed: _isUploading ? null : _clearFiles,
              child: const Text('清空'),
            ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(allUploaded ? '关闭' : '取消'),
          ),
          const SizedBox(width: 12),
          if (!allUploaded)
            ElevatedButton(
              onPressed: hasFiles && !_isUploading ? _uploadFiles : null,
              child: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('上传'),
            ),
          if (allUploaded && _uploadedAssets.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                widget.onUploaded?.call(_uploadedAssets);
                Navigator.of(context).pop();
              },
              child: const Text('完成'),
            ),
        ],
      ),
    );
  }

  Future<void> _selectFiles() async {
    try {
      final files = await openFiles(
        acceptedTypeGroups: _SupportedFileTypes.xTypeGroups,
      );

      if (files.isNotEmpty) {
        await _addFiles(files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addFiles(List<XFile> files) async {
    for (final file in files) {
      final extension = p.extension(file.path);
      final mimeType = _SupportedFileTypes.getMimeType(extension);
      final data = await file.readAsBytes();

      setState(() {
        _pendingFiles.add(_PendingFile(
          name: file.name,
          path: file.path,
          size: data.length,
          mimeType: mimeType,
          data: data,
        ));
      });
    }
  }

  void _handleDroppedFiles(List<String> paths) async {
    final xFiles = <XFile>[];
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        xFiles.add(XFile(path));
      }
    }
    if (xFiles.isNotEmpty) {
      await _addFiles(xFiles);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  void _clearFiles() {
    setState(() {
      _pendingFiles.clear();
    });
  }

  Future<void> _uploadFiles() async {
    setState(() {
      _isUploading = true;
    });

    final assetService = AssetService.instance;

    for (var i = 0; i < _pendingFiles.length; i++) {
      final file = _pendingFiles[i];
      if (file.isUploaded || file.data == null) continue;

      setState(() {
        _pendingFiles[i].isUploading = true;
      });

      try {
        final asset = await assetService.uploadAsset(
          UploadAssetRequest(
            workspaceId: widget.workspaceId,
            name: file.name,
            data: file.data!,
            mimeType: file.mimeType,
          ),
        );

        _uploadedAssets.add(asset);

        if (mounted) {
          setState(() {
            _pendingFiles[i].isUploading = false;
            _pendingFiles[i].isUploaded = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _pendingFiles[i].isUploading = false;
            _pendingFiles[i].error = '上传失败: $e';
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
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
}

/// 显示资产上传对话框
/// Requirements: 1.5
Future<List<Asset>?> showAssetUploadDialog(
  BuildContext context,
  String workspaceId,
) async {
  final uploadedAssets = <Asset>[];

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AssetUploadDialog(
      workspaceId: workspaceId,
      onUploaded: (assets) {
        uploadedAssets.addAll(assets);
      },
    ),
  );

  return uploadedAssets.isNotEmpty ? uploadedAssets : null;
}
