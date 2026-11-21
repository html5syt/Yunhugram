import 'dart:convert';
import 'dart:typed_data';

/// 服务器图像的实际尺寸与滑块位移，和界面缩放分开。
class Challenge {
  Challenge(Map<String, dynamic> data, this.image)
    : id = data['id'] as String,
      background = _decode(
        (image ? data['b64s'] : data['master_image']) as String,
      ),
      tile = image ? null : _decode(data['tile_image'] as String),
      width = image ? 300 : (data['master_size']['width'] as num).toDouble(),
      height = image ? 100 : (data['master_size']['height'] as num).toDouble(),
      tileWidth = image ? 0 : (data['tile_size']['width'] as num).toDouble(),
      tileHeight = image ? 0 : (data['tile_size']['height'] as num).toDouble(),
      tileY = image ? 0 : (data['tile_y'] as num).toDouble();
  final String id;
  final bool image;
  final Uint8List background;
  final Uint8List? tile;
  final double width, height, tileWidth, tileHeight, tileY;
  double rawX(double displayX, double displayWidth) =>
      (displayX * width / displayWidth).clamp(0, width - tileWidth);
  static Uint8List _decode(String value) => base64Decode(
    value.contains(',')
        ? value.substring(value.indexOf(',') + 1).trim()
        : value,
  );
}
