import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum ReaderMode { single, onTheGo }

/// Camera-based OCR reader that also speaks detected text aloud.
class TextReaderPage extends StatefulWidget {
  final ReaderMode mode;

  const TextReaderPage({super.key, required this.mode});

  @override
  State<TextReaderPage> createState() => _TextReaderPageState();
}

class _TextReaderPageState extends State<TextReaderPage> {
  static const double _topCaptionMaxHeight = 140;
  static const Duration _tiltSampleInterval = Duration(milliseconds: 30);
  static const Duration _inRangeMessageDuration = Duration(seconds: 2);
  static const Duration _hiddenBadgeFadeDelay = Duration(seconds: 2);

  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts();

  String _recognizedText = "";
  bool _isProcessing = false;
  bool _isInitializingCamera = true;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastTiltSampleAt;
  double _tiltAngle = 0;
  bool _isTiltInRange = false;
  bool _showInRangeMessage = true;
  bool _isGyroIndicatorEnabled = true;
  Timer? _inRangeMessageTimer;
  bool _isHiddenBadgeFaded = false;
  Timer? _hiddenBadgeFadeTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _setupTts();
    _configureTiltStream();
  }

  @override
  void didUpdateWidget(covariant TextReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _configureTiltStream();
      _restartCameraForMode();
    }
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
    setState(() => _isInitializingCamera = true);
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() {
        _recognizedText = "Camera permission denied.";
        _isInitializingCamera = false;
      });
      return;
    }
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras[0],
        widget.mode == ReaderMode.single
            ? ResolutionPreset.high
            : ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitializingCamera = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recognizedText = "Camera init error: $e";
          _isInitializingCamera = false;
        });
      }
    }
  }

  Future<void> _restartCameraForMode() async {
    final oldController = _controller;
    _controller = null;
    await oldController?.dispose();
    if (!mounted) return;
    await _initCamera();
  }

  double _previewAspectRatio(BuildContext context) {
    final controllerAspectRatio = _controller!.value.aspectRatio;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    // Camera reports landscape ratio on many devices; invert for portrait use.
    return isPortrait ? (1 / controllerAspectRatio) : controllerAspectRatio;
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

  void _configureTiltStream() {
    _accelerometerSubscription?.cancel();

    if (widget.mode == ReaderMode.single) {
      if (mounted) {
        setState(() {
          _tiltAngle = 0;
          _isTiltInRange = false;
          _showInRangeMessage = true;
        });
      }
      _lastTiltSampleAt = null;
      _inRangeMessageTimer?.cancel();
      return;
    }

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      if (_lastTiltSampleAt != null &&
          now.difference(_lastTiltSampleAt!) < _tiltSampleInterval) {
        return;
      }
      _lastTiltSampleAt = now;

      final normalized = (event.z / 9.81).clamp(-1.0, 1.0);
      final angle = (math.asin(normalized) * 180 / math.pi);
      _applyTiltAngle(angle);
    });
  }

  void _applyTiltAngle(double angle) {
    if (!_isGyroIndicatorEnabled) return;

    final wasInRange = _isTiltInRange;
    final inRange = angle >= -15 && angle <= 15;

    if (!inRange && wasInRange) {
      _inRangeMessageTimer?.cancel();
      _showInRangeMessage = true;
    } else if (inRange && !wasInRange) {
      _inRangeMessageTimer?.cancel();
      _showInRangeMessage = true;
      _inRangeMessageTimer = Timer(_inRangeMessageDuration, () {
        if (!mounted || !_isTiltInRange) return;
        setState(() => _showInRangeMessage = false);
      });
    }

    if (mounted) {
      setState(() {
        _tiltAngle = angle;
        _isTiltInRange = inRange;
      });
    }

    if (inRange && !wasInRange) {
      HapticFeedback.mediumImpact();
    }
  }

  void _toggleGyroIndicator() {
    _hiddenBadgeFadeTimer?.cancel();
    setState(() {
      _isGyroIndicatorEnabled = !_isGyroIndicatorEnabled;
      if (_isGyroIndicatorEnabled) {
        _showInRangeMessage = true;
      } else {
        _isHiddenBadgeFaded = false;
      }
    });

    if (!_isGyroIndicatorEnabled) {
      _hiddenBadgeFadeTimer = Timer(_hiddenBadgeFadeDelay, () {
        if (!mounted || _isGyroIndicatorEnabled) return;
        setState(() => _isHiddenBadgeFaded = true);
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _accelerometerSubscription?.cancel();
    _inRangeMessageTimer?.cancel();
    _hiddenBadgeFadeTimer?.cancel();
    _textRecognizer.close();
    // Prevent lingering audio when users navigate away mid-playback.
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializingCamera ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (widget.mode == ReaderMode.single) {
      final hasSingleText = _recognizedText.trim().isNotEmpty;
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: _previewAspectRatio(context),
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                  if (hasSingleText)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _TopCaptionZone(text: _recognizedText),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
              color: Colors.black,
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanText,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(_isProcessing ? "Processing..." : "SCAN"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final showOnTheGoStatus =
        _recognizedText.trim().isNotEmpty && _recognizedText != "Reading...";

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          if (showOnTheGoStatus)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopCaptionZone(text: _recognizedText),
            ),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: _toggleGyroIndicator,
              onLongPress: _toggleGyroIndicator,
              child: _GyroArcIndicator(
                angle: _tiltAngle * -1,
                inRange: _isTiltInRange,
                showInRangeMessage: _showInRangeMessage,
                isEnabled: _isGyroIndicatorEnabled,
                isHiddenBadgeFaded: _isHiddenBadgeFaded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCaptionZone extends StatelessWidget {
  const _TopCaptionZone({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: _TextReaderPageState._topCaptionMaxHeight,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _GyroArcIndicator extends StatelessWidget {
  const _GyroArcIndicator({
    required this.angle,
    required this.inRange,
    required this.showInRangeMessage,
    required this.isEnabled,
    required this.isHiddenBadgeFaded,
  });

  final double angle;
  final bool inRange;
  final bool showInRangeMessage;
  final bool isEnabled;
  final bool isHiddenBadgeFaded;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        opacity: isHiddenBadgeFaded ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: isHiddenBadgeFaded ? 0.32 : 0.65),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Gyro hidden (double tap or hold)",
            style: TextStyle(
              color: Colors.white.withValues(alpha: isHiddenBadgeFaded ? 0.62 : 0.95),
              fontSize: 13,
              fontWeight: isHiddenBadgeFaded ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final color = inRange ? Colors.greenAccent : Colors.orangeAccent;
    final message = inRange
        ? "Great angle"
        : angle < -15
        ? "Too low"
        : "Too high";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(180, 100),
          painter: _ArcPainter(angle: angle, color: color),
        ),
        const SizedBox(height: 8),
        if (!inRange || showInRangeMessage)
          Text(
            "$message (${angle.toStringAsFixed(0)}°)",
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
            ),
          ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.angle, required this.color});

  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2.5);
    final radius = size.width / 2.5;

    final basePaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, basePaint);

    final safeZonePaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Safe zone is centered around zero tilt (middle of the arc).
    const safeZoneStart = math.pi + (75 / 180) * math.pi;
    const safeZoneSweep = (30 / 180) * math.pi;
    canvas.drawArc(rect, safeZoneStart, safeZoneSweep, false, safeZonePaint);

    final normalized = ((angle + 90) / 180).clamp(0.0, 1.0);
    final markerTheta = math.pi + normalized * math.pi;
    final markerCenter = Offset(
      center.dx + radius * math.cos(markerTheta),
      center.dy + radius * math.sin(markerTheta),
    );

    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(markerCenter, 8, markerPaint);

    final markerOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(markerCenter, 8, markerOutlinePaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
}
