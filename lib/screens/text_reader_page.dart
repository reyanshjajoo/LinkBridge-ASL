import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 1. Import TTS
import 'package:permission_handler/permission_handler.dart';

class TextReaderPage extends StatefulWidget {
  const TextReaderPage({super.key});

  @override
  State<TextReaderPage> createState() => _TextReaderPageState();
}

class _TextReaderPageState extends State<TextReaderPage> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts(); // 2. Initialize TTS

  String _recognizedText = "Point at the whiteboard and tap Scan";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _setupTts();
  }

  // Configure the voice settings
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Normal speaking speed
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _recognizedText = "Camera permission denied.");
      return;
    }
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _recognizedText = "Camera init error: $e");
      }
    }
  }

  Future<void> _scanText() async {
    if (_controller == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = "Reading...";
    });

    try {
      final XFile photo = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        if (recognizedText.text.isEmpty) {
          _recognizedText = "No text found.";
        } else {
          _recognizedText = recognizedText.text;
          // 3. Speak the text aloud!
          _speak(_recognizedText);
        }
      });
    } catch (e) {
      setState(() => _recognizedText = "Error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    _flutterTts.stop(); // 4. Stop speaking if user leaves page
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("AI Talking Reader")),
      body: Column(
        children: [
          Expanded(child: CameraPreview(_controller!)),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  _recognizedText,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _scanText,
                  icon: const Icon(Icons.volume_up),
                  label: Text(_isProcessing ? "Processing..." : "SCAN & READ ALOUD"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
