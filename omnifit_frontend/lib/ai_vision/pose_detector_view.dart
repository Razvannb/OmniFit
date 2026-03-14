import 'dart:async'; // Added for the Countdown Timer
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_painter.dart';

/// [PoseDetectorView] is the "Brain" of the AI Vision module.
/// It handles camera streaming, ML processing, angle math,
/// and the State Machine for auto-counting repetitions.
class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({super.key});

  @override
  State<PoseDetectorView> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  // --- Core Camera & ML Variables ---
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;

  // --- Exercise State Machine & UI Variables ---
  String _selectedExercise = 'Squat';
  final List<String> _exercises = ['Squat', 'Pushup'];

  int _reps = 0; // The Rep Counter
  bool _isDown =
      false; // Tracks if the user is currently at the bottom of the movement
  String _feedbackText = "Ready! Get in position."; // Dynamic instructions
  Color _feedbackColor = Colors.white;

  // --- Countdown State Variables ---
  int _countdownValue = 5;
  bool _isCountingDown = false;
  Timer? _timer;

  // --- NEW: Info Banner State ---
  bool _showInfo = true; // Starts open to instruct the user initially

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Start the preparation timer as soon as camera is ready
      _startExerciseCountdown();

      _cameraController?.startImageStream(_processCameraImage);
    }
  }

  // Countdown Logic
  void _startExerciseCountdown() {
    _timer?.cancel();
    setState(() {
      _isCountingDown = true;
      _countdownValue = 5;
      _reps = 0; // Reset reps when we restart
      _isDown = false;
      _feedbackText = "Get ready!";
      _feedbackColor = Colors.white;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
      } else {
        setState(() {
          _isCountingDown = false;
          _feedbackText = "GO!";
          _feedbackColor = Colors.greenAccent;
        });
        timer.cancel();
      }
    });
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
      final poses = await _poseDetector.processImage(inputImage);

      // Only count reps if countdown is finished
      if (poses.isNotEmpty && !_isCountingDown) {
        _processRepetitionLogic(poses.first);
      }

      // Pass the body coordinates to the "Painter" just for drawing visuals
      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null) {
        final painter = PosePainter(
          poses,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          _selectedExercise,
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
      setState(() {}); // Refresh the screen with new lines and text
    }
  }

  // ==========================================
  //         THE AI BRAIN (MATH & LOGIC)
  // ==========================================

  double _calculateAngle(
    PoseLandmark first,
    PoseLandmark middle,
    PoseLandmark last,
  ) {
    double result =
        math.atan2(last.y - middle.y, last.x - middle.x) -
        math.atan2(first.y - middle.y, first.x - middle.x);
    double angle = result * 180 / math.pi;
    angle = angle.abs();
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  void _processRepetitionLogic(Pose pose) {
    PoseLandmark? p1, p2, p3;

    if (_selectedExercise == 'Squat') {
      p1 = pose.landmarks[PoseLandmarkType.rightHip];
      p2 = pose.landmarks[PoseLandmarkType.rightKnee];
      p3 = pose.landmarks[PoseLandmarkType.rightAnkle];
    } else if (_selectedExercise == 'Pushup') {
      p1 = pose.landmarks[PoseLandmarkType.rightShoulder];
      p2 = pose.landmarks[PoseLandmarkType.rightElbow];
      p3 = pose.landmarks[PoseLandmarkType.rightWrist];
    }

    if (p1 != null && p2 != null && p3 != null) {
      final double currentAngle = _calculateAngle(p1, p2, p3);

      if (currentAngle < 90.0) {
        if (!_isDown) {
          _isDown = true;
          _feedbackText = "Perfect! Now go up.";
          _feedbackColor = Colors.greenAccent;
        }
      } else if (currentAngle > 150.0) {
        if (_isDown) {
          _reps++;
          _isDown = false;
          _feedbackText = "Great job! Go lower again.";
          _feedbackColor = Colors.white;
        }
      } else {
        if (!_isDown) {
          _feedbackText = "Go lower!";
          _feedbackColor = Colors.orangeAccent;
        }
      }
    }
  }

  // ==========================================

  String _getInstructionText() {
    if (_selectedExercise == 'Squat') {
      return "Place phone on your side.\nEnsure hip, knee & ankle are visible.";
    } else {
      return "Place phone on your side.\nEnsure shoulder, elbow & wrist are visible.";
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _timer?.cancel();
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
                Center(
                  child: AspectRatio(
                    aspectRatio: 1 / _cameraController!.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!),
                        if (_customPaint != null) _customPaint!,
                      ],
                    ),
                  ),
                ),

                // Visual Countdown Overlay
                if (_isCountingDown)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        "$_countdownValue",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // UI OVERLAY: Dropdown Menu (Aligned Top: 60)
                Positioned(
                  top: 60,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedExercise,
                      dropdownColor: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      items: _exercises.map((String exercise) {
                        return DropdownMenuItem<String>(
                          value: exercise,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(exercise),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != _selectedExercise) {
                          setState(() {
                            _selectedExercise = newValue;
                            _showInfo = true; // Auto-show info for new exercise
                          });
                          _startExerciseCountdown();
                        }
                      },
                    ),
                  ),
                ),

                // UI OVERLAY: The Reps Counter (Aligned Top: 60)
                Positioned(
                  top: 60,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "REPS: $_reps",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                // UI OVERLAY: Dynamic Feedback Text
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      _feedbackText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedbackColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // UI OVERLAY: Reset Button (Bottom Right)
                // NEW: Hidden when Info Banner is open!
                if (!_showInfo)
                  Positioned(
                    bottom: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: _startExerciseCountdown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.refresh, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Reset",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // UI OVERLAY: Info Banner OR Collapsed (i) Button (Bottom Left)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: _showInfo ? 20 : null, // Expand only if open
                  child: _showInfo
                      // OPEN STATE: Full banner
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _showInfo = false; // Close on tap
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getInstructionText(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        )
                      // CLOSED STATE: Small (i) button
                      : GestureDetector(
                          onTap: () {
                            setState(() {
                              _showInfo = true; // Open on tap
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
