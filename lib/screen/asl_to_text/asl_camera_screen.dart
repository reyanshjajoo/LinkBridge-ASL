import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../camera_view.dart';
import '../../asl/gesture_classifier.dart';

class ASLCameraScreen extends StatefulWidget {
  const ASLCameraScreen({super.key});

  @override
  State<ASLCameraScreen> createState() => _ASLCameraScreenState();
}

class _ASLCameraScreenState extends State<ASLCameraScreen> {

  final GestureClassifier classifier = GestureClassifier();

  String detectedText = "";

  bool processing = false;
  bool modelLoaded = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future load() async {
    await classifier.loadModel();
    modelLoaded = true;
  }

  Future processFrame(CameraImage image) async {

    if (!modelLoaded) return;
    if (processing) return;

    processing = true;

    String result = await classifier.predict(image);

    setState(() {
      detectedText += result;
    });

    processing = false;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("ASL Translator")),

      body: Stack(
        children: [

          CameraView(onFrame: processFrame),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                detectedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}