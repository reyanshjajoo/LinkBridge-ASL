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

  String prediction = "Show a sign";

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    classifier.loadModel();
  }

  Future<void> processFrame(CameraImage image) async {

    if (isProcessing) return;

    isProcessing = true;

    String result = await classifier.predict(image);

    setState(() {
      prediction = result;
    });

    isProcessing = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("ASL Translator"),
        centerTitle: true,
      ),

      body: Stack(
        children: [

          CameraView(onFrame: processFrame),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(
                  prediction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}