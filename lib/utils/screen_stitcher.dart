import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 长滚动内容截图工具
class ScrollableStitcher {
  final GlobalKey repaintBoundaryKey;
  final ScrollController scrollController;

  ScrollableStitcher({
    required this.repaintBoundaryKey,
    required this.scrollController,
  });

  Future<Uint8List?> capture({
    bool fromTop = true,
    double overlap = 50.0,
    int waitForPaint = 300,
    double pixelRatio = 2.0,
    Color background = Colors.white,
  }) async {
    if (!scrollController.hasClients) {
      return null;
    }

    final position = scrollController.position;
    final double viewportHeight = position.viewportDimension;
    final double maxScroll = position.maxScrollExtent;

    debugPrint(
        '[Stitcher] viewportHeight: $viewportHeight, maxScroll: $maxScroll');

    if (maxScroll <= 0) {
      return _captureSingle(pixelRatio: pixelRatio);
    }

    final double originalOffset = position.pixels;
    final double totalHeight = maxScroll + viewportHeight;
    final double step = viewportHeight - overlap;

    final List<double> offsets = [];
    double currentOffset = fromTop ? 0.0 : originalOffset;

    while (currentOffset < maxScroll) {
      offsets.add(currentOffset);
      currentOffset += step;
    }
    offsets.add(maxScroll);

    debugPrint('[Stitcher] totalHeight: $totalHeight, offsets: $offsets');

    final List<_CapturedFrame> frames = [];

    try {
      for (int i = 0; i < offsets.length; i++) {
        final target = offsets[i];
        scrollController.jumpTo(target);
        await Future.delayed(Duration(milliseconds: waitForPaint));

        final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) throw Exception('RepaintBoundary not found');

        final img = await boundary.toImage(pixelRatio: pixelRatio);
        debugPrint(
            '[Stitcher] Frame $i at offset $target, size: ${img.width}x${img.height}');

        frames.add(_CapturedFrame(image: img, scrollOffset: target));
      }

      if (frames.isEmpty) return null;

      final ui.Image merged = await _mergeFrames(
        frames: frames,
        viewportHeight: viewportHeight,
        totalHeight: totalHeight,
        pixelRatio: pixelRatio,
        background: background,
      );

      debugPrint('[Stitcher] Merged: ${merged.width}x${merged.height}');

      final ByteData? pngBytes =
          await merged.toByteData(format: ui.ImageByteFormat.png);
      return pngBytes?.buffer.asUint8List();
    } finally {
      scrollController.jumpTo(originalOffset.clamp(0.0, maxScroll));
    }
  }

  Future<Uint8List?> _captureSingle({double pixelRatio = 2.0}) async {
    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<ui.Image> _mergeFrames({
    required List<_CapturedFrame> frames,
    required double viewportHeight,
    required double totalHeight,
    required double pixelRatio,
    required Color background,
  }) async {
    final int width = frames.first.image.width;
    final int imgHeight = frames.first.image.height;
    final int finalHeight = (totalHeight * pixelRatio).round();

    // 截图高度和视口高度的差值（padding等造成的）
    final double extraHeight = (imgHeight / pixelRatio) - viewportHeight;

    debugPrint(
        '[Stitcher] finalHeight=$finalHeight, viewportHeight=$viewportHeight, extraHeight=$extraHeight');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), finalHeight.toDouble()),
      Paint()..color = background,
    );

    double drawnUntil = 0;

    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final img = frame.image;

      // 这一帧对应的内容范围（使用视口高度，不是截图高度）
      final contentStart = frame.scrollOffset;
      final contentEnd =
          (frame.scrollOffset + viewportHeight).clamp(0.0, totalHeight);

      // 需要从这一帧中绘制的部分
      double srcStartLogical = 0;
      double dstStartLogical = contentStart;

      if (contentStart < drawnUntil) {
        srcStartLogical = drawnUntil - contentStart;
        dstStartLogical = drawnUntil;
      }

      double drawHeightLogical = contentEnd - dstStartLogical;

      if (dstStartLogical + drawHeightLogical > totalHeight) {
        drawHeightLogical = totalHeight - dstStartLogical;
      }

      if (drawHeightLogical <= 0) continue;

      // 转换为像素，考虑额外高度的偏移
      final srcY = (srcStartLogical + extraHeight / 2) * pixelRatio;
      final dstY = dstStartLogical * pixelRatio;
      final drawHeight = drawHeightLogical * pixelRatio;

      // 确保不超出源图片边界
      final maxSrcHeight = img.height - srcY;
      final actualDrawHeight = drawHeight.clamp(0.0, maxSrcHeight);

      if (actualDrawHeight <= 0) continue;

      final srcRect =
          Rect.fromLTWH(0, srcY, img.width.toDouble(), actualDrawHeight);
      final dstRect =
          Rect.fromLTWH(0, dstY, img.width.toDouble(), actualDrawHeight);

      debugPrint(
          '[Stitcher] Frame $i: content=$contentStart~$contentEnd, srcY=$srcY, dstY=$dstY, h=$actualDrawHeight');

      canvas.drawImageRect(img, srcRect, dstRect, Paint());

      drawnUntil = dstStartLogical + (actualDrawHeight / pixelRatio);
    }

    debugPrint('[Stitcher] drawnUntil=$drawnUntil, totalHeight=$totalHeight');

    final picture = recorder.endRecording();
    return picture.toImage(width, finalHeight);
  }
}

class _CapturedFrame {
  final ui.Image image;
  final double scrollOffset;

  _CapturedFrame({required this.image, required this.scrollOffset});
}
