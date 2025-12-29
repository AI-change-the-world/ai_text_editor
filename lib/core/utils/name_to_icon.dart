import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

class Identicon {
  /// 生成 GitHub 风格 identicon
  static Uint8List generate(
    String seed, {
    int size = 256,
    int grid = 5,
    int padding = 20,
    img.Color? background,
  }) {
    final hash = md5.convert(seed.codeUnits).bytes;

    // 颜色（hash 前 3 字节）
    final color = img.ColorUint8.rgb(
      hash[0],
      hash[1],
      hash[2],
    );

    background ??= img.ColorUint8.rgb(240, 240, 240);

    final image = img.Image(
      width: size,
      height: size,
      numChannels: 4,
    );

    img.fill(image, color: background);

    final cell = ((size - padding * 2) / grid).floor();

    int bitIndex = 0;

    for (int y = 0; y < grid; y++) {
      for (int x = 0; x < (grid + 1) ~/ 2; x++) {
        final byte = hash[bitIndex % hash.length];
        final draw = (byte & 1) == 1;
        bitIndex++;

        if (!draw) continue;

        final px = padding + x * cell;
        final py = padding + y * cell;

        // 左侧
        img.fillRect(
          image,
          x1: px,
          y1: py,
          x2: px + cell,
          y2: py + cell,
          color: color,
        );

        // 右侧镜像
        final mx = padding + (grid - x - 1) * cell;
        img.fillRect(
          image,
          x1: mx,
          y1: py,
          x2: mx + cell,
          y2: py + cell,
          color: color,
        );
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }
}
