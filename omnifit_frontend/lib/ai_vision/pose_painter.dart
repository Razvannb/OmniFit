import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// [PosePainter] is now strictly a View element (a dumb component).
/// Its ONLY responsibility is to draw dots and lines on the screen.
/// It contains NO business logic, NO math, and NO state.
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final String exerciseType;

  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.exerciseType,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Styling for the joints (dots)
    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.greenAccent;

    // Styling for the bones (lines)
    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = Colors.white;

    for (final pose in poses) {
      // Draw all detected joints on the body
      pose.landmarks.forEach((_, landmark) {
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
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      });

      // Draw the specific connecting lines based on the selected exercise
      if (exerciseType == 'Squat') {
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
    final joint1 = pose.landmarks[p1];
    final joint2 = pose.landmarks[p2];
    final joint3 = pose.landmarks[p3];

    // If all 3 joints are visible, draw the lines connecting them
    if (joint1 != null && joint2 != null && joint3 != null) {
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

      canvas.drawLine(pos1, pos2, bonePaint);
      canvas.drawLine(pos2, pos3, bonePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.exerciseType != exerciseType;
  }

  // --- Translation Helpers for Camera Aspect Ratio ---
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
