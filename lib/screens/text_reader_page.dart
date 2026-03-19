import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera-based OCR reader that also speaks detected text aloud.
class TextReaderPage extends StatefulWidget {
  const TextReaderPage({super.key});

  @override
  State<TextReaderPage> createState() => _TextReaderPageState();
}

class _TextReaderPageState extends State<TextReaderPage> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts();

  String _recognizedText = "Point at the whiteboard and tap Scan";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _setupTts();
  }

  /// Configures text-to-speech defaults for clear classroom-style playback.
  ///
  /// Returns when the TTS engine has accepted language and voice settings.
  Future<void> _setupTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  /// Requests camera permission and initializes the first available camera.
  ///
  /// On failure, updates [_recognizedText] so users get immediate, visible
  /// feedback instead of a silent blank preview.
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

  /// Captures a frame, runs OCR, and optionally speaks detected text.
  ///
  /// Guard clauses prevent overlapping scans, which avoids race conditions and
  /// repeated TTS playback when users tap quickly.
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
          _speak(_recognizedText);
        }
      });
    } catch (e) {
      setState(() => _recognizedText = "Error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Speaks the provided text if it is not empty.
  ///
  /// Parameter:
  /// - [text]: OCR output to read aloud.
  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    // Prevent lingering audio when users navigate away mid-playback.
    _flutterTts.stop();
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
