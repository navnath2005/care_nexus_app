import 'package:care_nexus/ambulance/Navigation%20service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Live navigation and tracking screen for active bookings
class NavigationScreen extends StatefulWidget {
  final String bookingId;
  final String destination;
  final double destinationLat;
  final double destinationLng;
  final String patientName;
  final String emergencyType;
  final String priority;

  const NavigationScreen({
    Key? key,
    required this.bookingId,
    required this.destination,
    required this.destinationLat,
    required this.destinationLng,
    required this.patientName,
    required this.emergencyType,
    required this.priority,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  Position? _currentPosition;
  double _distance = 0;
  bool _isLoading = true;
  bool _isNavigating = false;
  late Stream<Position> _locationStream;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await NavigationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _updateDistance();
        });

        // Start live location updates
        _locationStream = NavigationService.getLocationUpdates();
        _locationStream.listen((Position newPosition) {
          if (mounted) {
            setState(() {
              _currentPosition = newPosition;
              _updateDistance();
            });
            // Update location in Firestore
            _updateLocationInFirestore(newPosition);
          }
        });
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to get your location');
      }
    }
  }

  void _updateDistance() {
    if (_currentPosition != null) {
      _distance = NavigationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.destinationLat,
        widget.destinationLng,
      );
    }
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
            'ambulanceLocation': GeoPoint(
              position.latitude,
              position.longitude,
            ),
            'lastLocationUpdate': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating location in Firestore: $e');
    }
  }

  Future<void> _startNavigation() async {
    setState(() => _isNavigating = true);
    try {
      await NavigationService.launchGoogleMapsNavigation(
        destinationLat: widget.destinationLat,
        destinationLng: widget.destinationLng,
        destinationLabel: widget.destination,
      );
      setState(() => _isNavigating = false);
    } catch (e) {
      debugPrint('Error launching navigation: $e');
      _showError('Failed to open navigation app');
      setState(() => _isNavigating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'URGENT':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('En Route'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section
                Expanded(
                  flex: 2,
                  child: _currentPosition != null
                      ? AmbulanceMap(
                          currentLat: _currentPosition!.latitude,
                          currentLng: _currentPosition!.longitude,
                          destinationLat: widget.destinationLat,
                          destinationLng: widget.destinationLng,
                          destinationLabel: widget.patientName,
                        )
                      : const Center(child: Text('Unable to load map')),
                ),

                // Route Info Section
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.patientName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.emergencyType,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(
                                    widget.priority,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.priority,
                                  style: TextStyle(
                                    color: _getPriorityColor(widget.priority),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Distance and Time
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '${_distance.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Distance',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey[300],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${(_distance * 2).toStringAsFixed(0)} min',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Est. Time',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.destination,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Navigation Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isNavigating
                                  ? null
                                  : _startNavigation,
                              icon: const Icon(Icons.navigation_rounded),
                              label: Text(
                                _isNavigating
                                    ? 'Opening Navigation...'
                                    : 'Start Navigation',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Call Patient Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement phone call
                              },
                              icon: const Icon(Icons.call_rounded),
                              label: const Text(
                                'Call Patient',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
