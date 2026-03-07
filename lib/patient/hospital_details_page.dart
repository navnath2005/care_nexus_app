import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NearbyHospitalsPage extends StatefulWidget {
  const NearbyHospitalsPage({super.key});

  @override
  State<NearbyHospitalsPage> createState() => _NearbyHospitalsPageState();
}

class _NearbyHospitalsPageState extends State<NearbyHospitalsPage> {
  List hospitals = [];

  final String apiKey = "AIzaSyAjVSfFbUnQSb4UK4l8r2V5ZlGM4bAAI7w";

  @override
  void initState() {
    super.initState();
    getNearbyHospitals();
  }

  Future<void> getNearbyHospitals() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double lat = position.latitude;
    double lng = position.longitude;

    String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=$lat,$lng"
        "&radius=5000"
        "&type=hospital"
        "&key=$apiKey";

    var response = await http.get(Uri.parse(url));

    var data = json.decode(response.body);

    setState(() {
      hospitals = data["results"];
    });
  }

  Future<void> openMaps(double lat, double lng) async {
    final Uri uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Hospitals"),
        backgroundColor: const Color(0xFF1E3A8A),
      ),

      body: hospitals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: hospitals.length,
              itemBuilder: (context, index) {
                var hospital = hospitals[index];

                var location = hospital["geometry"]["location"];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_hospital,
                      color: Colors.red,
                    ),
                    title: Text(hospital["name"]),
                    subtitle: Text(hospital["vicinity"] ?? ""),
                    trailing: IconButton(
                      icon: const Icon(Icons.navigation),
                      onPressed: () {
                        openMaps(location["lat"], location["lng"]);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
