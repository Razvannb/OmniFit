import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  // The magic function from your plan to calculate the angle
  double calculateAngle(Offset first, Offset middle, Offset last) {
    double result =
        math.atan2(last.dy - middle.dy, last.dx - middle.dx) -
        math.atan2(first.dy - middle.dy, first.dx - middle.dx);
    double angle = result * 180 / math.pi;
    angle = angle.abs();
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.greenAccent; // Points color

    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = Colors.white; // Color of the lines between points (bones)

    for (final pose in poses) {
      // 1. Draw all detected points on the body
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

      // 2. Extract specific points for the Squat (using the right leg)
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      // If the AI clearly sees the hip, knee, and ankle, perform the calculations
      if (rightHip != null && rightKnee != null && rightAnkle != null) {
        // Transform coordinates
        final hipPos = Offset(
          translateX(rightHip.x, rotation, size, absoluteImageSize),
          translateY(rightHip.y, rotation, size, absoluteImageSize),
        );
        final kneePos = Offset(
          translateX(rightKnee.x, rotation, size, absoluteImageSize),
          translateY(rightKnee.y, rotation, size, absoluteImageSize),
        );
        final anklePos = Offset(
          translateX(rightAnkle.x, rotation, size, absoluteImageSize),
          translateY(rightAnkle.y, rotation, size, absoluteImageSize),
        );

        // Draw leg lines (Hip -> Knee -> Ankle)
        canvas.drawLine(hipPos, kneePos, bonePaint);
        canvas.drawLine(kneePos, anklePos, bonePaint);

        // Calculate the knee angle
        final double kneeAngle = calculateAngle(hipPos, kneePos, anklePos);

        // 3. Feedback logic (Squat)
        String feedbackText = "GO LOWER!";
        Color feedbackColor = Colors.redAccent;

        if (kneeAngle < 90.0) {
          feedbackText = "PERFECT!";
          feedbackColor = Colors.greenAccent;
        }

        // 4. Draw the angle and feedback on the screen
        _drawText(
          canvas,
          "${kneeAngle.toStringAsFixed(0)}°",
          kneePos,
          Colors.yellow,
        );
        _drawFeedback(canvas, size, feedbackText, feedbackColor);
      }
    }
  }

  // Helper to draw the degrees right next to the knee
  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(position.dx + 10, position.dy - 10));
  }

  // Helper to draw "GO LOWER!" or "PERFECT!" at the top of the screen
  void _drawFeedback(Canvas canvas, Size size, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, 50));
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation;
  }

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
