import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────
// ImageAnalysisService — 低コスト型・オンデバイス画像解析
//
// サーバーAPI不使用。Dartの image パッケージで全処理。
// 1. リサイズ＆圧縮（撮影直後）
// 2. 色分析（ドミナントカラー抽出）
// 3. 形状推定（明暗コントラスト）
// 4. タグ生成 → テンプレート設問呼び出し
// ─────────────────────────────────────────────────────────

class ImageTag {
  final String dominantColor;     // あか, あお, きいろ, みどり, etc.
  final String colorEmoji;
  final String brightness;        // あかるい, ふつう, くらい
  final String estimatedShape;    // まる, しかく, ながい, ふくざつ
  final int originalSizeKb;
  final int compressedSizeKb;

  const ImageTag({
    required this.dominantColor,
    required this.colorEmoji,
    required this.brightness,
    required this.estimatedShape,
    required this.originalSizeKb,
    required this.compressedSizeKb,
  });
}

class ImageAnalysisService {
  ImageAnalysisService._();

  /// 最大辺サイズ（リサイズ用）
  static const _maxDimension = 512;
  /// JPEG品質
  static const _jpegQuality = 72;

  /// 撮影画像をリサイズ＆圧縮して保存
  static Future<(File, int, int)> compressAndSave(File original) async {
    final bytes = await original.readAsBytes();
    final originalKb = bytes.length ~/ 1024;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return (original, originalKb, originalKb);

    // リサイズ（最大辺を _maxDimension に）
    img.Image resized;
    if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: _maxDimension);
      } else {
        resized = img.copyResize(decoded, height: _maxDimension);
      }
    } else {
      resized = decoded;
    }

    // JPEG圧縮
    final compressed = img.encodeJpg(resized, quality: _jpegQuality);
    final compressedKb = compressed.length ~/ 1024;

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outFile = File('${dir.path}/mandala_img_$ts.jpg');
    await outFile.writeAsBytes(compressed);

    return (outFile, originalKb, compressedKb);
  }

  /// オンデバイス画像解析 → タグ生成
  static Future<ImageTag> analyze(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalKb = bytes.length ~/ 1024;
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return ImageTag(
        dominantColor: 'ふめい', colorEmoji: '❓',
        brightness: 'ふつう', estimatedShape: 'ふくざつ',
        originalSizeKb: originalKb, compressedSizeKb: originalKb,
      );
    }

    // 色分析（中央エリアのサンプリング）
    final colorResult = _analyzeDominantColor(decoded);
    final brightness = _analyzeBrightness(decoded);
    final shape = _estimateShape(decoded);

    return ImageTag(
      dominantColor: colorResult.$1,
      colorEmoji: colorResult.$2,
      brightness: brightness,
      estimatedShape: shape,
      originalSizeKb: originalKb,
      compressedSizeKb: originalKb,
    );
  }

  /// ドミナントカラー抽出（中央25%エリアをサンプリング）
  static (String, String) _analyzeDominantColor(img.Image image) {
    int totalR = 0, totalG = 0, totalB = 0, count = 0;
    final cx = image.width ~/ 4;
    final cy = image.height ~/ 4;
    final w = image.width ~/ 2;
    final h = image.height ~/ 2;

    for (int y = cy; y < cy + h; y += 4) {
      for (int x = cx; x < cx + w; x += 4) {
        final pixel = image.getPixel(x, y);
        totalR += pixel.r.toInt();
        totalG += pixel.g.toInt();
        totalB += pixel.b.toInt();
        count++;
      }
    }

    if (count == 0) return ('ふめい', '❓');
    final r = totalR ~/ count;
    final g = totalG ~/ count;
    final b = totalB ~/ count;

    return _classifyColor(r, g, b);
  }

  static (String, String) _classifyColor(int r, int g, int b) {
    final max = [r, g, b].reduce((a, b2) => a > b2 ? a : b2);
    final min = [r, g, b].reduce((a, b2) => a < b2 ? a : b2);
    final diff = max - min;

    // グレー系
    if (diff < 30) {
      if (max > 200) return ('しろ', '⬜');
      if (max < 60) return ('くろ', '⬛');
      return ('はいいろ', '🩶');
    }
    // 彩度あり
    if (r > g && r > b) {
      if (r > 180 && g < 100) return ('あか', '🔴');
      if (g > 100) return ('オレンジ', '🟠');
      return ('あか', '🔴');
    }
    if (g > r && g > b) {
      if (g > 150 && r > 150) return ('きいろ', '🟡');
      return ('みどり', '🟢');
    }
    if (b > r && b > g) {
      if (r > 100) return ('むらさき', '🟣');
      return ('あお', '🔵');
    }
    if (r > 180 && g > 100 && b < 100) return ('きいろ', '🟡');
    if (r > 150 && g < 100 && b > 150) return ('ピンク', '🩷');
    return ('いろいろ', '🌈');
  }

  /// 明るさ分析
  static String _analyzeBrightness(img.Image image) {
    int total = 0, count = 0;
    for (int y = 0; y < image.height; y += 8) {
      for (int x = 0; x < image.width; x += 8) {
        final p = image.getPixel(x, y);
        total += (p.r.toInt() + p.g.toInt() + p.b.toInt()) ~/ 3;
        count++;
      }
    }
    if (count == 0) return 'ふつう';
    final avg = total ~/ count;
    if (avg > 180) return 'あかるい';
    if (avg < 80) return 'くらい';
    return 'ふつう';
  }

  /// 形状推定（エッジ密度ベース）
  static String _estimateShape(img.Image image) {
    // 簡易エッジ検出: 隣接ピクセルの輝度差を計算
    int edgeCount = 0, total = 0;
    for (int y = 1; y < image.height - 1; y += 6) {
      for (int x = 1; x < image.width - 1; x += 6) {
        final c = _luma(image.getPixel(x, y));
        final r = _luma(image.getPixel(x + 1, y));
        final d = _luma(image.getPixel(x, y + 1));
        if ((c - r).abs() > 30 || (c - d).abs() > 30) edgeCount++;
        total++;
      }
    }
    if (total == 0) return 'ふくざつ';
    final ratio = edgeCount / total;
    if (ratio < 0.1) return 'まる';       // エッジ少ない = 滑らか
    if (ratio < 0.25) return 'しかく';     // 中程度 = 角あり
    if (ratio < 0.4) return 'ながい';      // 多め = 細長い
    return 'ふくざつ';                      // エッジ多い = 複雑
  }

  static int _luma(img.Pixel p) =>
      (p.r.toInt() * 299 + p.g.toInt() * 587 + p.b.toInt() * 114) ~/ 1000;
}
