import 'dart:typed_data';

abstract class ImageHelper {
  static Uint8List pngSignature =
      Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

  static bool isPng(Uint8List imageBytes) {
    for (var i = 0; i < pngSignature.length; i++) {
      if (imageBytes[i] != pngSignature[i]) return false;
    }
    return true;
  }
}
