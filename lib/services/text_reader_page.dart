import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextReaderPage extends StatefulWidget {
  const TextReaderPage({super.key});

  @override
  _TextReaderPageState createState() => _TextReaderPageState();
}

class _TextReaderPageState extends State<TextReaderPage> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
    _flutterTts.speak("Camera ready. Tap the screen to scan text.");
  }

  Future<void> _scanAndRead() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isProcessing = true);
    _flutterTts.speak("Scanning...");

    try {
      // 1. Capture the image
      final XFile image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // 2. Recognize text
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 3. Read it out loud
      if (recognizedText.text.trim().isEmpty) {
        _flutterTts.speak("No text found. Please try again.");
      } else {
        _flutterTts.speak(recognizedText.text);
      }
    } catch (e) {
      _flutterTts.speak("Error scanning text.");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Blind Support: Text Reader")),
      body: GestureDetector(
        onTap: _scanAndRead, // Entire screen is a button for accessibility
        child: Stack(
          children: [
            CameraPreview(_controller!),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Text(
                "TAP ANYWHERE TO SCAN",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, backgroundColor: Colors.black54, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}