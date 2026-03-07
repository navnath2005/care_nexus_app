import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Design Tokens (matched with dashboard)
// ─────────────────────────────────────────────
class _MonitorColors {
  static const primary = Color(0xFF0A2463);
  static const primaryLight = Color(0xFF1E4DB7);
  static const accent = Color(0xFF3BCEAC);
  static const danger = Color(0xFFE63946);
  static const warning = Color(0xFFF4A261);
  static const success = Color(0xFF2DC653);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F7FC);
  static const textPrimary = Color(0xFF0D1B2A);
  static const textSecondary = Color(0xFF64748B);
  static const divider = Color(0xFFE2E8F0);

  // Monitor specific
  static const heartbeatGreen = Color(0xFF00E676);
  static const spo2Cyan = Color(0xFF00E5FF);
  static const criticalRed = Color(0xFFFF6B6B);
}

// ─────────────────────────────────────────────
// LiveHealthGraph — Patient Monitor UI (Enhanced)
// ─────────────────────────────────────────────

class LiveHealthGraph extends StatefulWidget {
  final String? patientId;
  final bool isDarkMode;

  const LiveHealthGraph({super.key, this.patientId, this.isDarkMode = false});

  @override
  State<LiveHealthGraph> createState() => _LiveHealthGraphState();
}

class _LiveHealthGraphState extends State<LiveHealthGraph>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref(
    'healthData/history',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FlSpot> _heartSpots = [];
  List<FlSpot> _spo2Spots = [];
  double _xValue = 0;
  double _currentPulse = 0;
  double _currentSpo2 = 0;
  double _currentTemp = 0;
  String _patientName = 'Patient';
  bool _isConnected = false;

  StreamSubscription? _subscription;
  StreamSubscription? _firestoreSubscription;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _listenToFirebase();
    if (widget.patientId != null) {
      _listenToFirestore();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _firestoreSubscription?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  void _listenToFirebase() {
    _subscription = _ref
        .limitToLast(30)
        .onChildAdded
        .listen(
          (event) {
            final data = event.snapshot.value as Map?;
            if (data != null && mounted) {
              setState(() {
                _isConnected = true;
                final heart = (data['pulse'] as num?)?.toDouble() ?? 0;
                final spo2 = (data['spo2'] as num?)?.toDouble() ?? 0;
                final temp = (data['temperature'] as num?)?.toDouble() ?? 0;

                _currentPulse = heart;
                _currentSpo2 = spo2;
                _currentTemp = temp;

                _heartSpots.add(FlSpot(_xValue, heart));
                _spo2Spots.add(FlSpot(_xValue, spo2));
                _xValue++;

                if (_heartSpots.length > 30) {
                  _heartSpots.removeAt(0);
                  _spo2Spots.removeAt(0);
                }
              });

              // Save to Firestore
              _saveVitalToFirestore();
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() => _isConnected = false);
            }
          },
        );
  }

  void _listenToFirestore() {
    if (widget.patientId == null) return;

    _firestoreSubscription = _firestore
        .collection('patients')
        .doc(widget.patientId)
        .snapshots()
        .listen((doc) {
          if (mounted && doc.exists) {
            setState(() {
              _patientName = doc.data()?['name'] ?? 'Patient';
            });
          }
        });
  }

  void _saveVitalToFirestore() {
    if (widget.patientId == null || _currentPulse == 0) return;

    try {
      _firestore.collection('vitals').add({
        'patientId': widget.patientId,
        'patientName': _patientName,
        'heartRate': _currentPulse.toInt(),
        'spo2': _currentSpo2.toInt(),
        'temperature': _currentTemp,
        'timestamp': FieldValue.serverTimestamp(),
        'status': _determineStatus(),
      });
    } catch (e) {
      debugPrint('Error saving vital: $e');
    }
  }

  String _determineStatus() {
    if (_currentPulse > 120 || _currentPulse < 50) return 'critical';
    if (_currentSpo2 < 92) return 'critical';
    if (_currentPulse > 100 || _currentPulse < 60) return 'warning';
    if (_currentSpo2 < 95) return 'warning';
    return 'normal';
  }

  bool get _heartCritical =>
      _currentPulse > 120 || (_currentPulse > 0 && _currentPulse < 50);

  bool get _spo2Critical => _currentSpo2 > 0 && _currentSpo2 < 92;

  bool get _tempCritical =>
      _currentTemp > 103 || (_currentTemp > 0 && _currentTemp < 95);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : _MonitorColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── Monitor Top Bar ───────────────
          _MonitorTopBar(
            blinkController: _blinkController,
            patientName: _patientName,
            isConnected: _isConnected,
            isDarkMode: isDark,
          ),

          // ── ECG Channel ───────────────────
          _MonitorChannel(
            label: 'ECG',
            channelColor: _MonitorColors.heartbeatGreen,
            spots: _heartSpots,
            minY: 40,
            maxY: 160,
            readingLabel: 'HR',
            readingValue: _currentPulse > 0
                ? _currentPulse.toInt().toString()
                : '--',
            readingUnit: 'bpm',
            isCritical: _heartCritical,
            blinkController: _blinkController,
            isDarkMode: isDark,
          ),

          // ── Separator ─────────────────────
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : _MonitorColors.divider,
          ),

          // ── SpO2 Channel ──────────────────
          _MonitorChannel(
            label: 'SpO₂',
            channelColor: _MonitorColors.spo2Cyan,
            spots: _spo2Spots,
            minY: 85,
            maxY: 102,
            readingLabel: 'SpO₂',
            readingValue: _currentSpo2 > 0
                ? _currentSpo2.toInt().toString()
                : '--',
            readingUnit: '%',
            isCritical: _spo2Critical,
            blinkController: _blinkController,
            isDarkMode: isDark,
          ),

          // ── Temperature Indicator (Optional) ───
          if (_currentTemp > 0) ...[
            Container(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : _MonitorColors.divider,
            ),
            _TemperatureIndicator(
              temperature: _currentTemp,
              isCritical: _tempCritical,
              isDarkMode: isDark,
            ),
          ],

          // ── Bottom Status Bar ──────────────
          _MonitorBottomBar(
            pulse: _currentPulse,
            spo2: _currentSpo2,
            isConnected: _isConnected,
            isDarkMode: isDark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Monitor Top Bar (Enhanced)
// ─────────────────────────────────────────────

class _MonitorTopBar extends StatelessWidget {
  final AnimationController blinkController;
  final String patientName;
  final bool isConnected;
  final bool isDarkMode;

  const _MonitorTopBar({
    required this.blinkController,
    required this.patientName,
    required this.isConnected,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode
        ? Colors.white60
        : _MonitorColors.textSecondary;
    final activeColor = isDarkMode
        ? _MonitorColors.heartbeatGreen
        : _MonitorColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATIENT MONITOR',
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                patientName,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : _MonitorColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          FadeTransition(
            opacity: blinkController,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isConnected ? activeColor : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              color: isConnected ? activeColor : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 16),
          _ClockWidget(isDarkMode: isDarkMode),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Live Clock
// ─────────────────────────────────────────────

class _ClockWidget extends StatefulWidget {
  final bool isDarkMode;

  const _ClockWidget({required this.isDarkMode});

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late String _time;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _time,
      style: TextStyle(
        color: widget.isDarkMode
            ? Colors.white38
            : _MonitorColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
        letterSpacing: 1,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Monitor Channel (Enhanced)
// ─────────────────────────────────────────────

class _MonitorChannel extends StatelessWidget {
  final String label;
  final Color channelColor;
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final String readingLabel;
  final String readingValue;
  final String readingUnit;
  final bool isCritical;
  final AnimationController blinkController;
  final bool isDarkMode;

  const _MonitorChannel({
    required this.label,
    required this.channelColor,
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.readingLabel,
    required this.readingValue,
    required this.readingUnit,
    required this.isCritical,
    required this.blinkController,
    required this.isDarkMode,
  });

  Color get _activeColor {
    if (isCritical) {
      return _MonitorColors.criticalRed;
    }
    return channelColor;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left Rail: channel label ───────
          SizedBox(
            width: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _activeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                if (isCritical) ...[
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: blinkController,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _activeColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: _activeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Waveform ──────────────────────
          Expanded(
            child: SizedBox(
              height: 90,
              child: spots.length < 2
                  ? Center(
                      child: Text(
                        'WAITING FOR DATA',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.2)
                              : _MonitorColors.textSecondary.withOpacity(0.3),
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : _Waveform(
                      spots: spots,
                      color: _activeColor,
                      minY: minY,
                      maxY: maxY,
                      isDarkMode: isDarkMode,
                    ),
            ),
          ),

          // ── Right Rail: digital reading ────
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    readingLabel,
                    style: TextStyle(
                      color: _activeColor.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    readingValue,
                    style: TextStyle(
                      color: _activeColor,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    readingUnit,
                    style: TextStyle(
                      color: _activeColor.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Temperature Indicator
// ─────────────────────────────────────────────

class _TemperatureIndicator extends StatelessWidget {
  final double temperature;
  final bool isCritical;
  final bool isDarkMode;

  const _TemperatureIndicator({
    required this.temperature,
    required this.isCritical,
    required this.isDarkMode,
  });

  Color get _tempColor {
    if (isCritical) return _MonitorColors.criticalRed;
    if (temperature > 101.5) return _MonitorColors.warning;
    return _MonitorColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, color: _tempColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Temperature',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white60
                      : _MonitorColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '${temperature.toStringAsFixed(1)}°F',
            style: TextStyle(
              color: _tempColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Waveform Chart
// ─────────────────────────────────────────────

class _Waveform extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final double minY;
  final double maxY;
  final bool isDarkMode;

  const _Waveform({
    required this.spots,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: spots.isNotEmpty ? spots.first.x : 0,
        maxX: spots.isNotEmpty ? spots.last.x : 1,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxY - minY) / 4,
          verticalInterval: 5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDarkMode
                ? Colors.white.withOpacity(0.06)
                : _MonitorColors.divider.withOpacity(0.5),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: isDarkMode
                ? Colors.white.withOpacity(0.04)
                : _MonitorColors.divider.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.8,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, index) {
                if (index == spots.length - 1) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: isDarkMode
                        ? const Color(0xFF0B1120)
                        : Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.25), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 120),
      curve: Curves.linear,
    );
  }
}

// ─────────────────────────────────────────────
// Monitor Bottom Status Bar
// ─────────────────────────────────────────────

class _MonitorBottomBar extends StatelessWidget {
  final double pulse;
  final double spo2;
  final bool isConnected;
  final bool isDarkMode;

  const _MonitorBottomBar({
    required this.pulse,
    required this.spo2,
    required this.isConnected,
    required this.isDarkMode,
  });

  String get _status {
    if (!isConnected) return 'DEVICE DISCONNECTED';
    if (pulse == 0 && spo2 == 0) return 'CONNECTING...';
    if (pulse > 120 || pulse < 50 || spo2 < 92) return 'ALERT — CHECK PATIENT';
    return 'VITALS STABLE';
  }

  Color get _statusColor {
    if (!isConnected) return Colors.grey;
    if (pulse == 0 && spo2 == 0) return Colors.white38;
    if (pulse > 120 || pulse < 50 || spo2 < 92)
      return _MonitorColors.criticalRed;
    return _MonitorColors.heartbeatGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.03)
            : _MonitorColors.divider.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _status,
            style: TextStyle(
              color: _statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            'CareNexus v1.0',
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.15)
                  : _MonitorColors.textSecondary.withOpacity(0.4),
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
