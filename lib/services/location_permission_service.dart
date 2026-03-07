import 'package:geolocator/geolocator.dart';

class PermissionService {
  static Future<void> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw "Turn ON GPS";
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw "Enable location permission from Settings";
    }
  }

  static Future<void> requestAllPermissions() async {}
}
