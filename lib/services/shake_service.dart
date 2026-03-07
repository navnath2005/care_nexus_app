import 'dart:math';
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  static const double shakeThreshold = 15.0;
  static DateTime _lastShake = DateTime.now();

  static void listen(VoidCallback onShake) {
    userAccelerometerEvents.listen((event) {
      double gForce = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (gForce > shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShake).inSeconds > 2) {
          _lastShake = now;
          onShake();
        }
      }
    });
  }
}
