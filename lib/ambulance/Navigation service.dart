import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for handling navigation and routing
class NavigationService {
  /// Launch Google Maps navigation to a destination
  static Future<void> launchGoogleMapsNavigation({
    required double destinationLat,
    required double destinationLng,
    required String destinationLabel,
  }) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving&dir_action=navigate';

    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch Google Maps';
      }
    } catch (e) {
      debugPrint('Error launching navigation: $e');
      rethrow;
    }
  }

  /// Get current location with proper error handling
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        openAppSettings();
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in km
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Stream of location updates
  static Stream<Position> getLocationUpdates({
    int distanceFilter = 10, // Update every 10 meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

/// Widget for displaying map with markers
class AmbulanceMap extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? destinationLabel;
  final VoidCallback? onMapCreated;

  const AmbulanceMap({
    Key? key,
    required this.currentLat,
    required this.currentLng,
    this.destinationLat,
    this.destinationLng,
    this.destinationLabel,
    this.onMapCreated,
  }) : super(key: key);

  @override
  State<AmbulanceMap> createState() => _AmbulanceMapState();
}

class _AmbulanceMapState extends State<AmbulanceMap> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _addMarkers();
  }

  void _addMarkers() {
    _markers.clear();

    // Add current location marker (ambulance)
    _markers.add(
      Marker(
        markerId: const MarkerId('ambulance'),
        position: LatLng(widget.currentLat, widget.currentLng),
        infoWindow: const InfoWindow(title: '📍 Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Add destination marker if provided
    if (widget.destinationLat != null && widget.destinationLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(widget.destinationLat!, widget.destinationLng!),
          infoWindow: InfoWindow(
            title: widget.destinationLabel ?? 'Destination',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Draw polyline between markers
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(widget.currentLat, widget.currentLng),
            LatLng(widget.destinationLat!, widget.destinationLng!),
          ],
          color: const Color(0xFF3B82F6),
          width: 5,
          geodesic: true,
        ),
      );

      // Animate camera to show both points
      _animateCameraToBounds();
    }
  }

  void _animateCameraToBounds() {
    if (widget.destinationLat == null || widget.destinationLng == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.currentLat < widget.destinationLat!
            ? widget.currentLat
            : widget.destinationLat!,
        widget.currentLng < widget.destinationLng!
            ? widget.currentLng
            : widget.destinationLng!,
      ),
      northeast: LatLng(
        widget.currentLat > widget.destinationLat!
            ? widget.currentLat
            : widget.destinationLat!,
        widget.currentLng > widget.destinationLng!
            ? widget.currentLng
            : widget.destinationLng!,
      ),
    );

    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  void didUpdateWidget(AmbulanceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLat != widget.currentLat ||
        oldWidget.currentLng != widget.currentLng) {
      _addMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call();
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.currentLat, widget.currentLng),
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
