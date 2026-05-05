import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/asl_service.dart';
import '../widgets/asl_result_card.dart';

enum AslState { idle, recording, processing, result }

class AslTranslatorScreen extends StatefulWidget {
  const AslTranslatorScreen({Key? key}) : super(key: key);

  @override
  _AslTranslatorScreenState createState() => _AslTranslatorScreenState();
}

class _AslTranslatorScreenState extends State<AslTranslatorScreen> {
  CameraController? _cameraController;
  final AslService _aslService = AslService();
  final FlutterTts _flutterTts = FlutterTts();

  AslState _state = AslState.idle;
  AslResult? _result;

  Timer? _recordingTimer;
  int _secondsLeft = 4;
  bool _isRecording = false;
  bool _isInitializingCamera = true;
  String? _cameraInitError;

  @override
  void initState() {
    super.initState();
    // Lock to portrait mode BEFORE camera init for consistent video recording
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]).then((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializingCamera = true;
      _cameraInitError = null;
    });

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _isInitializingCamera = false;
          _cameraInitError = 'Camera permission denied.';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isInitializingCamera = false;
          _cameraInitError = 'No camera found on this device.';
        });
        return;
      }
      
      // Prefer back camera for capture consistency.
      CameraDescription? backCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
          break;
        }
      }
      
      _cameraController = CameraController(
        backCamera ?? cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      
      // Lock camera capture orientation to portrait
      await _cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
          _cameraInitError = null;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
          _cameraInitError = 'Camera init error: $e';
        });
      }
    }
  }

  Future<void> _startRecording() async {
    if (_state != AslState.idle || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Re-lock orientation to portrait before recording
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    setState(() {
      _state = AslState.recording;
      _secondsLeft = 4;
      _isRecording = true;
    });

    try {
      await _cameraController!.startVideoRecording();
      
      // Start countdown timer for UI updates
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _secondsLeft > 0) {
          setState(() {
            _secondsLeft--;
          });
        }
      });
      
      // Auto-stop after 4 seconds
      Future.delayed(const Duration(seconds: 4), () async {
        if (_isRecording && mounted) {
          await _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
      setState(() {
        _state = AslState.idle;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _cameraController == null) return;

    _isRecording = false;
    _recordingTimer?.cancel();
    
    if (!mounted) return;
    
    setState(() {
      _state = AslState.processing;
    });

    try {
      if (_cameraController!.value.isRecordingVideo) {
        final file = await _cameraController!.stopVideoRecording();
        _processVideo(File(file.path));
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        setState(() {
          _state = AslState.idle;
        });
      }
    }
  }

  Future<void> _processVideo(File videoFile) async {
    try {
      final result = await _aslService.transcribeVideo(videoFile);
      setState(() {
        _result = result;
        _state = AslState.result;
      });
      await _speakResult(result.bestLabel);
    } catch (e) {
      debugPrint('Processing error: $e');
      setState(() {
        _state = AslState.idle;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error translating video: $e')),
        );
      }
    }
  }

  Future<void> _speakResult(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(text);
  }

  void _reset() {
    setState(() {
      _state = AslState.idle;
      _result = null;
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _isRecording = false;
    _cameraController?.dispose();
    _flutterTts.stop();
    // Restore orientation when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializingCamera) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cameraInitError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  _cameraInitError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _initializeCamera,
                  child: const Text('Retry Camera'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: Text('Camera unavailable.')),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          _buildCameraPreview(),

          // UI Overlays based on state
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return const SizedBox.expand(child: ColoredBox(color: Colors.black));
        }

        // Camera reports dimensions in sensor/native orientation.
        // For portrait UI we flip to get a visual aspect ratio and center-crop.
        final previewAspectRatio = previewSize.height / previewSize.width;
        final screenAspectRatio =
            constraints.maxWidth / constraints.maxHeight;

        final fittedWidth = screenAspectRatio > previewAspectRatio
            ? constraints.maxWidth
            : constraints.maxHeight * previewAspectRatio;
        final fittedHeight = screenAspectRatio > previewAspectRatio
            ? constraints.maxWidth / previewAspectRatio
            : constraints.maxHeight;

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: 0,
            minHeight: 0,
            maxWidth: fittedWidth,
            maxHeight: fittedHeight,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }

  Widget _buildOverlay() {
    switch (_state) {
      case AslState.idle:
        return _buildIdleState();
      case AslState.recording:
        return _buildRecordingState();
      case AslState.processing:
        return _buildProcessingState();
      case AslState.result:
        return _buildResultState();
    }
  }

  Widget _buildIdleState() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: const Text(
                'Hold RECORD to sign a word',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Center(
                child: Text(
                  'RECORD',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingState() {
    return Stack(
      children: [
        // Red pulsing border
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.8), width: 8),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Recording... ${_secondsLeft}s',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onLongPressEnd: (_) => _stopRecording(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 90,
                      width: 90,
                      child: CircularProgressIndicator(
                        value: (4 - _secondsLeft) / 4,
                        color: Colors.redAccent,
                        strokeWidth: 6,
                      ),
                    ),
                    Container(
                      height: 70,
                      width: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Translating...',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_result != null) AslResultCard(result: _result!),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _reset,
                  child: const Text('Try Again'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save to Firestore logic could go here
                    _reset();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved!')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
