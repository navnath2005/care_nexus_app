import 'dart:async';
import 'package:flutter/material.dart';
import 'package:care_nexus/services/sos_service.dart';

class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  Timer? _timer;
  int _countdown = 5;
  bool _cancelled = false;

  void _startCountdown() {
    _cancelled = false;
    _countdown = 5;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_countdown == 0) {
              timer.cancel();
              _timer = null;

              if (!_cancelled) {
                Navigator.pop(context);
                _triggerSOS();
              }
            } else {
              setState(() => _countdown--);
            }
          });

          return AlertDialog(
            title: const Text("🚨 Emergency SOS"),
            content: Text(
              "Sending SOS in $_countdown seconds…",
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _cancelled = true;
                  _timer?.cancel();
                  _timer = null;
                  Navigator.pop(context);
                },
                child: const Text(
                  "CANCEL",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _triggerSOS() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚑 Navigating to nearest ambulance")),
      );

      await SosService.navigateToNearestAmbulance();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ SOS failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _startCountdown,
      child: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Long-press SOS to activate")),
          );
        },
        child: const Icon(Icons.sos, color: Colors.white, size: 32),
      ),
    );
  }
}
