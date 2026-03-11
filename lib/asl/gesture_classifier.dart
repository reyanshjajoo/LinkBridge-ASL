import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'image_utils.dart';
import 'package:flutter/services.dart' show rootBundle;

class GestureClassifier {

  Interpreter? interpreter;
  List<String> labels = [];

  Future loadModel() async {

    interpreter = await Interpreter.fromAsset('model.tflite');

    final labelData = await rootBundle.loadString('assets/labels.txt');
    labels = labelData.split('\n');

  }

  Future<String> predict(CameraImage image) async {

    if (interpreter == null) return "";

    Float32List input = ImageUtils.processCameraImage(image);

    var output = List.filled(labels.length, 0.0).reshape([1, labels.length]);

    interpreter!.run(input.reshape([1, 224, 224, 3]), output);

    int maxIndex = 0;
    double maxScore = 0;

    for (int i = 0; i < labels.length; i++) {
      if (output[0][i] > maxScore) {
        maxScore = output[0][i];
        maxIndex = i;
      }
    }

    return labels[maxIndex];
  }

  void close() {
    interpreter?.close();
  }
}