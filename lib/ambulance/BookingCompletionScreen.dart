import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Booking completion screen with detailed reporting
class BookingCompletionScreen extends StatefulWidget {
  final String bookingId;
  final String patientName;
  final String emergencyType;
  final DateTime acceptedAt;

  const BookingCompletionScreen({
    Key? key,
    required this.bookingId,
    required this.patientName,
    required this.emergencyType,
    required this.acceptedAt,
  }) : super(key: key);

  @override
  State<BookingCompletionScreen> createState() =>
      _BookingCompletionScreenState();
}

class _BookingCompletionScreenState extends State<BookingCompletionScreen> {
  late PageController _pageController;
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form data
  final Map<String, dynamic> _completionData = {
    'vitalSigns': {
      'bloodPressure': '',
      'heartRate': '',
      'temperature': '',
      'oxygenLevel': '',
    },
    'treatment': '',
    'hospitalizationRequired': false,
    'hospital': '',
    'notes': '',
    'injuries': [],
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    if (_currentStep != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all steps'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final durationMinutes = now.difference(widget.acceptedAt).inMinutes;

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'durationMinutes': durationMinutes,
            'completionData': _completionData,
          });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error completing booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Emergency Completed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Report submitted successfully',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Complete Emergency'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildVitalSignsStep(),
                _buildTreatmentStep(),
                _buildHospitalizationStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of 4',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vital Signs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Record patient vital signs',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          _buildVitalInputField(
            label: 'Blood Pressure',
            hint: 'e.g., 120/80',
            onChanged: (value) =>
                _completionData['vitalSigns']['bloodPressure'] = value,
          ),
          const SizedBox(height: 16),
          _buildVitalInputField(
            label: 'Heart Rate',
            hint: 'bpm',
            onChanged: (value) =>
                _completionData['vitalSigns']['heartRate'] = value,
          ),
          const SizedBox(height: 16),
          _buildVitalInputField(
            label: 'Temperature',
            hint: '°C',
            onChanged: (value) =>
                _completionData['vitalSigns']['temperature'] = value,
          ),
          const SizedBox(height: 16),
          _buildVitalInputField(
            label: 'Oxygen Level',
            hint: '%',
            onChanged: (value) =>
                _completionData['vitalSigns']['oxygenLevel'] = value,
          ),
        ],
      ),
    );
  }

  Widget _buildVitalInputField({
    required String label,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Treatment Provided',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Describe the treatment administered',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          TextField(
            maxLines: 6,
            onChanged: (value) => _completionData['treatment'] = value,
            decoration: InputDecoration(
              hintText:
                  'E.g., CPR performed, oxygen provided, wound bandaged...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Additional Notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            maxLines: 4,
            onChanged: (value) => _completionData['notes'] = value,
            decoration: InputDecoration(
              hintText: 'Any additional information...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalizationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hospitalization',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Is patient hospitalization required?',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: CheckboxListTile(
              title: const Text('Hospital admission required'),
              value: _completionData['hospitalizationRequired'],
              onChanged: (value) {
                setState(() {
                  _completionData['hospitalizationRequired'] = value ?? false;
                });
              },
              activeColor: const Color(0xFF3B82F6),
            ),
          ),
          if (_completionData['hospitalizationRequired']) ...[
            const SizedBox(height: 20),
            const Text(
              'Hospital Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              onChanged: (value) => _completionData['hospital'] = value,
              decoration: InputDecoration(
                hintText: 'Name of hospital',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final durationMinutes = DateTime.now()
        .difference(widget.acceptedAt)
        .inMinutes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verify all information before submitting',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          _buildReviewCard(
            title: 'Patient Information',
            children: [
              _buildReviewRow('Name', widget.patientName),
              _buildReviewRow('Emergency Type', widget.emergencyType),
              _buildReviewRow('Duration', '$durationMinutes minutes'),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'Vital Signs',
            children: [
              _buildReviewRow(
                'Blood Pressure',
                _completionData['vitalSigns']['bloodPressure'] ?? '-',
              ),
              _buildReviewRow(
                'Heart Rate',
                _completionData['vitalSigns']['heartRate'] ?? '-',
              ),
              _buildReviewRow(
                'Temperature',
                _completionData['vitalSigns']['temperature'] ?? '-',
              ),
              _buildReviewRow(
                'Oxygen Level',
                _completionData['vitalSigns']['oxygenLevel'] ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            title: 'Treatment',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _completionData['treatment'] ?? 'No treatment recorded',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          if (_completionData['hospitalizationRequired']) ...[
            const SizedBox(height: 16),
            _buildReviewCard(
              title: 'Hospitalization',
              children: [
                _buildReviewRow('Hospital', _completionData['hospital'] ?? '-'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_currentStep < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _submitCompletion();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 3 ? 'Submit' : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
