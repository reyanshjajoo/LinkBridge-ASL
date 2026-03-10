import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

typedef FrameCallback = void Function(CameraImage image);

class CameraView extends StatefulWidget {
  final FrameCallback onFrame;

  const CameraView({Key? key, required this.onFrame}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? controller;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    controller = CameraController(
      cameras![0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    controller!.startImageStream((CameraImage image) {
      widget.onFrame(image);
    });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(controller!);
  }
}