import 'dart:typed_data';
import 'package:camera/camera.dart';

class ImageUtils {

  static Float32List processCameraImage(CameraImage image) {

    int width = image.width;
    int height = image.height;

    Float32List converted = Float32List(224 * 224 * 3);

    int pixelIndex = 0;

    for (int i = 0; i < 224; i++) {
      for (int j = 0; j < 224; j++) {

        int x = (j * width ~/ 224);
        int y = (i * height ~/ 224);

        int index = y * width + x;

        int pixel = image.planes[0].bytes[index];

        converted[pixelIndex++] = pixel / 255.0;
        converted[pixelIndex++] = pixel / 255.0;
        converted[pixelIndex++] = pixel / 255.0;
      }
    }

    return converted;
  }
}