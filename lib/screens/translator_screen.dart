import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  CameraController? cameraController;
  bool isCameraReady = false;
  String recognizedSign = "No sign detected";

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('How to use Camera Translator'),
          content: const Text(
            '1. Make sure your camera is connected and allowed.\n'
            '2. Position your hand so your ASL sign is clearly visible in the preview.\n'
            '3. Hold one sign steady at a time; the recognized sign text will appear on the right.\n'
            '4. Use the “Clear” button to reset the recognized text.\n\n'
            'If you see a camera error, check permissions or try a different camera device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      // Get all available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          recognizedSign = "No camera found";
        });
        return;
      }

      // Use the back camera (preferred)
      final camera = cameras.first;

      cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();

      setState(() {
        isCameraReady = true;
      });

      // Start frame stream for ASL detection
      cameraController!.startImageStream(processCameraImage);
    } catch (e) {
      setState(() {
        recognizedSign = "Camera error: $e";
      });
    }
  }

  // TODO: Actual ML goes here.
  // For now: simulate detection text
  Future<void> processCameraImage(CameraImage image) async {
    // Fake detection for demo:
    setState(() {
      recognizedSign = "Detecting... (ML model not added yet)";
    });
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
        title: const Text("ASL Camera Translator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How this screen works',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // LEFT PANEL — CAMERA
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: isCameraReady
                      ? CameraPreview(cameraController!)
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // RIGHT PANEL — RECOGNIZED TEXT
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recognized Sign:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3C3C3C),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          recognizedSign,
                          style: const TextStyle(fontSize: 24, color: Color(0xFFC67C4E)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          recognizedSign = "Cleared";
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text("Clear"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
