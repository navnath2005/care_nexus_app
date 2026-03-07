import 'package:care_nexus/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'location_permission_service.dart';

class SosService {
  static get import => null;

  static Future<void> navigateToNearestAmbulance() async {
    // 🔥 FORCE permission dialog
    await PermissionService.requestLocationPermission();

    // Now Android WILL ask permission
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    Future<void> triggerSOS() async {
      final pos = await LocationService.getCurrentLocation();
      // send pos.latitude & pos.longitude
    }

    final Uri mapsUri = Uri(
      scheme: "https",
      host: "www.google.com",
      path: "/maps/dir/",
      queryParameters: {
        "api": "1",
        "origin": "${position.latitude},${position.longitude}",
        "destination": "ambulance",
        "travelmode": "driving",
      },
    );

    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }
}
