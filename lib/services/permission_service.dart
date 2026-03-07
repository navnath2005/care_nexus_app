import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAllPermissions() async {
    // Request permissions one by one (Android-safe)
    await Permission.location.request();
    await Permission.camera.request();
    await Permission.storage.request();

    // Android 13+ only
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> requestLocationPermission() async {}
}
