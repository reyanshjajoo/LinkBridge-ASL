import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraView extends StatefulWidget {

  final Function(CameraImage) onFrame;

  const CameraView({super.key, required this.onFrame});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {

  CameraController? controller;

  @override
  void initState() {
    super.initState();
    startCamera();
  }

  Future startCamera() async {

    final cameras = await availableCameras();

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller!.initialize();

    controller!.startImageStream((image) {
      widget.onFrame(image);
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(controller!);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}