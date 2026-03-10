import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class GestureClassifier {
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('model.tflite');

    String labelsData = await rootBundle.loadString('assets/label.txt');
    _labels = labelsData.split('\n');
  }

  Future<String> predict(CameraImage image) async {
    try {
      // Convert camera image to bytes
      Uint8List bytes = image.planes[0].bytes;

      // Fake input tensor (simplified for now)
      var input = List.generate(1, (i) => List.filled(224 * 224 * 3, 0));

      var output = List.generate(1, (i) => List.filled(_labels.length, 0.0));

      _interpreter.run(input, output);

      int maxIndex = 0;
      double maxScore = 0;

      for (int i = 0; i < output[0].length; i++) {
        if (output[0][i] > maxScore) {
          maxScore = output[0][i];
          maxIndex = i;
        }
      }

      return _labels[maxIndex].split(" ").last;
    } catch (e) {
      return "";
    }
  }
}