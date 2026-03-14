import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_painter.dart'; // Import the custom painter

class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({super.key});

  @override
  State<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // Our AI Pose Detector
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Choose the front camera (since the user films themselves)
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Initialize the camera controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false, // We don't need the microphone
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // HERE IS THE MAGIC: Start the video stream and send frames for analysis
      _cameraController?.startImageStream(_processCameraImage);
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final camera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    _processImage(inputImage);
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy) return;
    _isBusy = true;

    try {
      // The AI analyzes the image
      final poses = await _poseDetector.processImage(inputImage);

      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null) {
        // If a body is found, create the painter to draw the skeleton
        final painter = PosePainter(
          poses,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
        );
        _customPaint = CustomPaint(painter: painter);
      } else {
        _customPaint = null;
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _poseDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                // 1. Display the raw camera feed
                CameraPreview(_cameraController!),

                // 2. Overlay the AI points and bones
                if (_customPaint != null) _customPaint!,
              ],
            ),
    );
  }
}
