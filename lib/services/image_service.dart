import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  /// Crops [file] to a rectangle given in *normalized* coordinates (0..1)
  /// relative to the image, e.g. the framing overlay shown in the viewfinder.
  static Future<File> cropNormalized(
    File file, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;
    final oriented = img.bakeOrientation(decoded);
    final x = (left * oriented.width).round().clamp(0, oriented.width - 1);
    final y = (top * oriented.height).round().clamp(0, oriented.height - 1);
    final w = (width * oriented.width).round().clamp(1, oriented.width - x);
    final h = (height * oriented.height).round().clamp(1, oriented.height - y);
    final cropped = img.copyCrop(oriented, x: x, y: y, width: w, height: h);
    final out = File(p.join(
      (await getTemporaryDirectory()).path,
      'crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
    ));
    await out.writeAsBytes(img.encodeJpg(cropped, quality: 92));
    return out;
  }

  /// Saves a ~480px-wide JPEG thumbnail into the app documents directory
  /// and returns its path (persisted alongside the DB row).
  static Future<String> cacheThumbnail(File file) async {
    final decoded = img.decodeImage(await file.readAsBytes());
    final dir = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'thumbnails'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final path =
        p.join(dir.path, 'rcpt_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (decoded == null) {
      await file.copy(path);
      return path;
    }
    final thumb = img.copyResize(img.bakeOrientation(decoded), width: 480);
    await File(path).writeAsBytes(img.encodeJpg(thumb, quality: 80));
    return path;
  }
}
