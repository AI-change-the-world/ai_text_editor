import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_text_editor/models/markdown_model.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/styles.dart';

/// Document Outline Widget
/// Requirements: 2.7 - WHEN a user views document outline THEN the System SHALL
/// display a navigable table of contents based on headings
class DocumentOutline extends ConsumerStatefulWidget {
  final List<MarkdownModel> models;

  const DocumentOutline({
    super.key,
    required this.models,
  });

  @override
  ConsumerState<DocumentOutline> createState() => _DocumentOutlineState();
}

class _DocumentOutlineState extends ConsumerState<DocumentOutline> {
  String? _hoveredItem;
  String? _activeItem;

  List<MarkdownModel> get _headings {
    return widget.models
        .where((m) => m.tag.startsWith('h') && m.tag.length == 2)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final showOutline =
        ref.watch(editorNotifierProvider.select((s) => s.showDocumentOutline));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: showOutline ? Styles.structureWidth : 0,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          left: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: showOutline ? _buildOutlineContent() : const SizedBox.shrink(),
    );
  }

  Widget _buildOutlineContent() {
    if (_headings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '暂无标题',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _headings.length,
            itemBuilder: (context, index) {
              return _buildOutlineItem(_headings[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.list_alt,
            size: 18,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          const Text(
            '文档大纲',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                ref
                    .read(editorNotifierProvider.notifier)
                    .toggleDocumentOutline();
              },
              child: const Icon(
                Icons.close,
                size: 18,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineItem(MarkdownModel model, int index) {
    final isHovered = _hoveredItem == '${model.tag}_${model.text}_$index';
    final isActive = _activeItem == '${model.tag}_${model.text}_$index';
    final indent = _getIndentLevel(model.tag);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hoveredItem = '${model.tag}_${model.text}_$index';
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredItem = null;
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeItem = '${model.tag}_${model.text}_$index';
          });
          ref.read(editorNotifierProvider.notifier).scrollToText(model.text);
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 12.0 + (indent * 12.0),
            right: 12.0,
            top: 6.0,
            bottom: 6.0,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blue.withValues(alpha: 0.1)
                : isHovered
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildHeadingIcon(model.tag),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  model.text,
                  style: _getTextStyle(model.tag, isActive),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadingIcon(String tag) {
    final level = int.tryParse(tag.substring(1)) ?? 1;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: _getHeadingColor(level).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'H$level',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _getHeadingColor(level),
          ),
        ),
      ),
    );
  }

  Color _getHeadingColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  int _getIndentLevel(String tag) {
    final level = int.tryParse(tag.substring(1)) ?? 1;
    return level - 1;
  }

  TextStyle _getTextStyle(String tag, bool isActive) {
    final level = int.tryParse(tag.substring(1)) ?? 1;
    final baseColor = isActive ? Colors.blue : Colors.black87;

    switch (level) {
      case 1:
        return TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: baseColor,
        );
      case 2:
        return TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: baseColor,
        );
      case 3:
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: baseColor,
        );
      case 4:
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: baseColor.withValues(alpha: 0.8),
        );
      default:
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: baseColor.withValues(alpha: 0.7),
        );
    }
  }
}
