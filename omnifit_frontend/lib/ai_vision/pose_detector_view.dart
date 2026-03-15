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
  CameraController? _cameraController; // Controls the device's physical camera
  List<CameraDescription>? _cameras; // List of available cameras (front/back)
  bool _isCameraInitialized = false; // Flag to show loading screen until camera is ready
  
  // The Google ML Kit engine that finds human body parts in an image
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );
  
  bool _canProcess = true; // Flag to allow/stop image processing
  bool _isBusy = false; // Prevents processing a new frame while the current one is still being analyzed
  CustomPaint? _customPaint; // The visual lines/dots drawn over the body

  // --- Exercise State Machine & UI Variables ---
  String _selectedExercise = 'Squat'; // Default exercise
  final List<String> _exercises = ['Squat', 'Pushup']; // Available exercises in the dropdown

  int _reps = 0; // The Rep Counter (how many squats/pushups you did)
  bool _isDown = false; // Tracks if the user is currently at the bottom of the movement
  String _feedbackText = "Ready! Get in position."; // Dynamic instructions shown on screen
  Color _feedbackColor = Colors.white; // Color of the feedback text (changes to green/orange)

  // --- Countdown State Variables ---
  // Gives the user 5 seconds to step back and get in position
  int _countdownValue = 5;
  bool _isCountingDown = false;
  Timer? _timer;

  // --- Info Banner State ---
  bool _showInfo = true; // Starts open to instruct the user initially

  @override
  void initState() {
    super.initState();
    // Start turning on the camera as soon as this screen is opened
    _initializeCamera();
  }

  // Sets up the camera stream
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Find the front-facing (selfie) camera, otherwise use the first available one
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        // Different platforms need different image formats
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Start the 5-second preparation timer as soon as camera is ready
      _startExerciseCountdown();

      // Start listening to the camera feed. 
      // This calls _processCameraImage dozens of times per second.
      _cameraController?.startImageStream(_processCameraImage);
    }
  }

  // Countdown Logic (5 -> 4 -> 3 -> 2 -> 1 -> GO)
  void _startExerciseCountdown() {
    _timer?.cancel(); // Cancel any existing timer
    setState(() {
      _isCountingDown = true;
      _countdownValue = 5;
      _reps = 0; // Reset reps when we restart
      _isDown = false;
      _feedbackText = "Get ready!";
      _feedbackColor = Colors.white;
    });

    // Run a function every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() => _countdownValue--); // Decrease number
      } else {
        // Countdown finished! Time to start the exercise
        setState(() {
          _isCountingDown = false;
          _feedbackText = "GO!";
          _feedbackColor = Colors.greenAccent;
        });
        timer.cancel(); // Stop the timer
      }
    });
  }

  // Prepares the raw camera data for the AI model
  Future<void> _processCameraImage(CameraImage image) async {
    // Convert the camera image planes into a continuous byte array
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
    
    // Calculate how the image needs to be rotated (portrait/landscape)
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
        
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // Package the raw bytes and metadata into an object ML Kit understands
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

    // Send the packaged image to the AI brain
    _processImage(inputImage);
  }

  // The actual AI processing step
  Future<void> _processImage(InputImage inputImage) async {
    // If we are already processing a frame, skip this one to prevent lag
    if (!_canProcess || _isBusy) return;
    _isBusy = true;

    try {
      // Ask ML Kit to find the human body poses in this image
      final poses = await _poseDetector.processImage(inputImage);

      // If a body is found and the countdown is over, count the reps
      if (poses.isNotEmpty && !_isCountingDown) {
        _processRepetitionLogic(poses.first);
      }

      // Pass the body coordinates to the "Painter" to draw the skeleton lines
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

    _isBusy = false; // We are done, ready for the next frame
    if (mounted) {
      setState(() {}); // Refresh the screen with new lines and text
    }
  }

  // ==========================================
  //         THE AI BRAIN (MATH & LOGIC)
  // ==========================================

  // Calculates the angle between 3 points (e.g., Hip -> Knee -> Ankle)
  double _calculateAngle(
    PoseLandmark first,
    PoseLandmark middle,
    PoseLandmark last,
  ) {
    // Uses trigonometry (atan2) to find the angle in radians, then converts to degrees
    double result =
        math.atan2(last.y - middle.y, last.x - middle.x) -
        math.atan2(first.y - middle.y, first.x - middle.x);
    double angle = result * 180 / math.pi;
    angle = angle.abs(); // Ensure angle is positive
    if (angle > 180) angle = 360 - angle; // Normalize angle to 0-180 degrees
    return angle;
  }

  // Determines if a repetition has been completed based on joint angles
  void _processRepetitionLogic(Pose pose) {
    PoseLandmark? p1, p2, p3;

    // Pick the relevant body parts based on the selected exercise
    if (_selectedExercise == 'Squat') {
      p1 = pose.landmarks[PoseLandmarkType.rightHip];
      p2 = pose.landmarks[PoseLandmarkType.rightKnee];
      p3 = pose.landmarks[PoseLandmarkType.rightAnkle];
    } else if (_selectedExercise == 'Pushup') {
      p1 = pose.landmarks[PoseLandmarkType.rightShoulder];
      p2 = pose.landmarks[PoseLandmarkType.rightElbow];
      p3 = pose.landmarks[PoseLandmarkType.rightWrist];
    }

    // If all 3 points are visible on screen
    if (p1 != null && p2 != null && p3 != null) {
      // Calculate the current angle of the joint (Knee for squat, Elbow for pushup)
      final double currentAngle = _calculateAngle(p1, p2, p3);

      // Phase 1: Going Down
      // If the angle is less than 90 degrees, the user is at the bottom of the movement
      if (currentAngle < 90.0) {
        if (!_isDown) {
          _isDown = true; // Mark that they reached the bottom
          _feedbackText = "Perfect! Now go up.";
          _feedbackColor = Colors.greenAccent;
        }
      } 
      // Phase 2: Going Up
      // If the angle is > 150 degrees, the user is standing back up straight
      else if (currentAngle > 150.0) {
        if (_isDown) {
          _reps++; // Rep completed! Increase counter
          _isDown = false; // Reset the state for the next rep
          _feedbackText = "Great job! Go lower again.";
          _feedbackColor = Colors.white;
        }
      } 
      // Phase 3: In between / Incomplete movement
      else {
        if (!_isDown) {
          _feedbackText = "Go lower!";
          _feedbackColor = Colors.orangeAccent;
        }
      }
    }
  }

  // ==========================================

  // Returns helpful hints based on the active exercise
  String _getInstructionText() {
    if (_selectedExercise == 'Squat') {
      return "Place phone on your side.\nEnsure hip, knee & ankle are visible.";
    } else {
      return "Place phone on your side.\nEnsure shoulder, elbow & wrist are visible.";
    }
  }

  // Cleanup: Turn off camera and AI when leaving this screen
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
      // Show a loading spinner if camera is not ready yet
      body: !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator())
          // Stack allows placing widgets on top of each other
          : Stack(
              fit: StackFit.expand,
              children: [
                // 1. The Camera Feed & Skeleton Drawing
                Center(
                  child: AspectRatio(
                    aspectRatio: 1 / _cameraController!.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!), // Live camera video
                        if (_customPaint != null) _customPaint!, // The AI Skeleton lines
                      ],
                    ),
                  ),
                ),

                // 2. Visual Countdown Overlay (Big numbers in the center)
                if (_isCountingDown)
                  Container(
                    color: Colors.black54, // Semi-transparent black background
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

                // 3. UI OVERLAY: Dropdown Menu (Top Right)
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
                      underline: const SizedBox(), // Removes the default underline
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
                        // When a new exercise is selected, update state and restart countdown
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

                // 4. UI OVERLAY: The Reps Counter Badge (Top Left)
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

                // 5. UI OVERLAY: Dynamic Feedback Text (Below Top Bar)
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      _feedbackText, // Will say "Go lower!", "Perfect!", etc.
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedbackColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          // Adds a black shadow to make text readable over the camera feed
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

                // 6. UI OVERLAY: Reset Button (Bottom Right)
                // Hidden when Info Banner is open to avoid clutter
                if (!_showInfo)
                  Positioned(
                    bottom: 40,
                    right: 20,
                    child: GestureDetector(
                      onTap: _startExerciseCountdown, // Restarts timer and resets reps
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

                // 7. UI OVERLAY: Info Banner OR Collapsed (i) Button (Bottom Left)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: _showInfo ? 20 : null, // Expand across screen only if open
                  child: _showInfo
                      // OPEN STATE: Full banner with instructions
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _showInfo = false; // Close banner when tapped
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
                                    _getInstructionText(), // Shows specific tip for Squat/Pushup
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
                              _showInfo = true; // Open banner when tapped
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
