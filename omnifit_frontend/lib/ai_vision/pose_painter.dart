import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// [PosePainter] is now strictly a View element (a dumb component).
/// Its ONLY responsibility is to draw dots and lines on the screen
/// directly over the camera feed.
/// It contains NO business logic, NO math, and NO state.
class PosePainter extends CustomPainter {
  // The list of human bodies (poses) detected by the AI in the current camera frame
  final List<Pose> poses;
  
  // The actual resolution of the raw image coming from the camera
  final Size absoluteImageSize;
  
  // The rotation of the camera sensor (portrait vs landscape)
  final InputImageRotation rotation;
  
  // The currently selected exercise (e.g., 'Squat', 'Pushup')
  final String exerciseType;

  // Constructor
  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.exerciseType,
  );

  /// This is the main drawing method. It acts like a brush painting on a transparent glass
  /// placed on top of the camera video.
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Styling for the joints (the dots on body parts)
    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.greenAccent;

    // 2. Styling for the bones (the lines connecting the joints)
    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = Colors.white;

    // Iterate through every person detected in the frame (usually just one)
    for (final pose in poses) {
      
      // Step A: Draw all detected joints (dots) on the body
      pose.landmarks.forEach((_, landmark) {
        // Convert the raw X and Y coordinates from the camera resolution 
        // to fit the actual screen size of the phone
        final double x = translateX(
          landmark.x,
          rotation,
          size,
          absoluteImageSize,
        );
        final double y = translateY(
          landmark.y,
          rotation,
          size,
          absoluteImageSize,
        );
        
        // Draw a small circle at the translated X, Y coordinate
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      });

      // Step B: Draw the specific connecting lines (bones) based on the selected exercise
      if (exerciseType == 'Squat') {
        // For a squat, we only care about drawing the line connecting Hip -> Knee -> Ankle
        _drawBones(
          canvas,
          size,
          pose,
          bonePaint,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.rightAnkle,
        );
      } else if (exerciseType == 'Pushup') {
        // For a pushup, we care about the arm: Shoulder -> Elbow -> Wrist
        _drawBones(
          canvas,
          size,
          pose,
          bonePaint,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.rightWrist,
        );
      }
    }
  }

  /// Helper function to draw lines between 3 specific joints
  void _drawBones(
    Canvas canvas,
    Size size,
    Pose pose,
    Paint bonePaint,
    PoseLandmarkType p1,
    PoseLandmarkType p2,
    PoseLandmarkType p3,
  ) {
    // Get the raw data for the 3 requested body parts
    final joint1 = pose.landmarks[p1];
    final joint2 = pose.landmarks[p2];
    final joint3 = pose.landmarks[p3];

    // Proceed ONLY if the AI can clearly see all 3 joints on the camera
    if (joint1 != null && joint2 != null && joint3 != null) {
      
      // Translate the coordinates for all 3 points to match the screen
      final pos1 = Offset(
        translateX(joint1.x, rotation, size, absoluteImageSize),
        translateY(joint1.y, rotation, size, absoluteImageSize),
      );
      final pos2 = Offset(
        translateX(joint2.x, rotation, size, absoluteImageSize),
        translateY(joint2.y, rotation, size, absoluteImageSize),
      );
      final pos3 = Offset(
        translateX(joint3.x, rotation, size, absoluteImageSize),
        translateY(joint3.y, rotation, size, absoluteImageSize),
      );

      // Draw line from Joint 1 to Joint 2 (e.g., Hip to Knee)
      canvas.drawLine(pos1, pos2, bonePaint);
      // Draw line from Joint 2 to Joint 3 (e.g., Knee to Ankle)
      canvas.drawLine(pos2, pos3, bonePaint);
    }
  }

  /// Determines if Flutter needs to redraw the screen. 
  /// It only repaints if new movement is detected, screen size changes, or exercise changes.
  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.exerciseType != exerciseType;
  }

  // ==========================================
  // --- Translation Helpers for Camera Aspect Ratio ---
  // The camera might capture a 1920x1080 image, but your phone screen 
  // might be 800x400. These functions scale the AI's coordinates to fit your screen perfectly.
  // ==========================================

  // Scales and translates the horizontal (X) coordinate
  double translateX(
    double x,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / absoluteImageSize.height;
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / absoluteImageSize.height;
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  // Scales and translates the vertical (Y) coordinate
  double translateY(
    double y,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / absoluteImageSize.width;
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }
}