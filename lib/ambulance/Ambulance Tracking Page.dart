import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AmbulanceTrackerPage extends StatefulWidget {
  final String bookingId;
  final double patientLat;
  final double patientLng;

  const AmbulanceTrackerPage({
    super.key,
    required this.bookingId,
    required this.patientLat,
    required this.patientLng,
  });

  @override
  State<AmbulanceTrackerPage> createState() => _AmbulanceTrackerPageState();
}

class _AmbulanceTrackerPageState extends State<AmbulanceTrackerPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Map<MarkerId, Marker> _markers = {};

  // Styles
  static const Color primaryBlue = Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Error loading tracking data"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;

          // Fallback if driver hasn't updated location yet
          LatLng driverLocation = data['driverLocation'] != null
              ? LatLng(
                  data['driverLocation']['lat'],
                  data['driverLocation']['lng'],
                )
              : LatLng(widget.patientLat + 0.01, widget.patientLng + 0.01);

          _updateMarkers(driverLocation);

          return Stack(
            children: [
              // 1. THE MAP
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.patientLat, widget.patientLng),
                  zoom: 14.0,
                ),
                markers: Set<Marker>.of(_markers.values),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

              // 2. LIVE INFO CARD
              Positioned(
                bottom: 20,
                left: 15,
                right: 15,
                child: _buildInfoCard(data),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateMarkers(LatLng driverPos) {
    setState(() {
      // Patient Marker
      _markers[const MarkerId('patient')] = Marker(
        markerId: const MarkerId('patient'),
        position: LatLng(widget.patientLat, widget.patientLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Your Location"),
      );

      // Moving Ambulance Marker
      _markers[const MarkerId('ambulance')] = Marker(
        markerId: const MarkerId('ambulance'),
        position: driverPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: "Ambulance"),
      );
    });
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    String status = data['status'] ?? "Searching...";
    String driverName = data['driverName'] ?? "Assigning Driver...";
    String eta = data['eta'] ?? "Calculating...";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "ETA: $eta",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: primaryBlue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Emergency Medical Technician",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _callNumber(data['driverPhone'] ?? "911"),
                icon: const Icon(Icons.phone, color: Colors.green, size: 28),
              ),
              IconButton(
                onPressed: () {
                  // Navigate to your existing ChatPage
                  // Navigator.push(...)
                },
                icon: const Icon(
                  Icons.chat_bubble,
                  color: primaryBlue,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _confirmCancel(),
              child: const Text(
                "CANCEL EMERGENCY REQUEST",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callNumber(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Emergency?"),
        content: const Text(
          "Are you sure you want to cancel the ambulance request?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("NO"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .update({'status': 'cancelled'});
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit tracking page
            },
            child: const Text(
              "YES, CANCEL",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
