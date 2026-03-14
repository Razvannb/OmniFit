import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({super.key});

  @override
  State<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Find out available cameras on the device
    _cameras = await availableCameras();

    if (_cameras != null && _cameras!.isNotEmpty) {
      // We choose the front camera
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Initialize the camera controller with the selected camera
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController
        ?.dispose(); // We dispose the camera controller when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniFit - Corecție Formă AI'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isCameraInitialized
          ? CameraPreview(
              _cameraController!,
            ) // We show the camera preview if it's initialized
          : const Center(
              child:
                  CircularProgressIndicator(), // We show a loading indicator until the camera is initialized
            ),
    );
  }
}
