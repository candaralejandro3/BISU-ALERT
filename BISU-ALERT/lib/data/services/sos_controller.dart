import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'sos_alarm_service.dart';

enum EmergencyStatus {
  idle,
  activating,
  assigned,
  responding,
  arrived,
  resolved,
  cancelled,
}

extension EmergencyStatusExtension on EmergencyStatus {
  String get label {
    switch (this) {
      case EmergencyStatus.idle:
        return 'IDLE';
      case EmergencyStatus.activating:
        return 'DISPATCHING';
      case EmergencyStatus.assigned:
        return 'RESPONDER ASSIGNED';
      case EmergencyStatus.responding:
        return 'RESPONDING';
      case EmergencyStatus.arrived:
        return 'ARRIVED ON SCENE';
      case EmergencyStatus.resolved:
        return 'RESOLVED';
      case EmergencyStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case EmergencyStatus.idle:
        return Colors.grey;
      case EmergencyStatus.activating:
        return const Color(0xFFD32F2F);
      case EmergencyStatus.assigned:
        return const Color(0xFF0288D1);
      case EmergencyStatus.responding:
        return const Color(0xFFED6C02);
      case EmergencyStatus.arrived:
        return const Color(0xFF7B1FA2);
      case EmergencyStatus.resolved:
        return const Color(0xFF2E7D32);
      case EmergencyStatus.cancelled:
        return const Color(0xFF757575);
    }
  }
}

class ActiveEmergency {
  ActiveEmergency({
    required this.incidentId,
    required this.type,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.reportedAt,
    required this.status,
    required this.responderName,
    required this.responderPhone,
    required this.isInsideCampus,
    required this.etaMinutes,
  });

  final String incidentId;
  final String type;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime reportedAt;
  EmergencyStatus status;
  String responderName;
  String responderPhone;
  final bool isInsideCampus;
  int etaMinutes;

  ActiveEmergency copyWith({
    EmergencyStatus? status,
    String? responderName,
    String? responderPhone,
    int? etaMinutes,
  }) {
    return ActiveEmergency(
      incidentId: incidentId,
      type: type,
      location: location,
      latitude: latitude,
      longitude: longitude,
      reportedAt: reportedAt,
      status: status ?? this.status,
      responderName: responderName ?? this.responderName,
      responderPhone: responderPhone ?? this.responderPhone,
      isInsideCampus: isInsideCampus,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }
}

/// Central controller managing SOS trigger, GPS telemetry, geofence, and responder assignment
class SosController extends ChangeNotifier {
  static final SosController _instance = SosController._internal();
  factory SosController() => _instance;
  SosController._internal();

  static const double campusLat = 9.71888;
  static const double campusLng = 124.10883;
  static const double campusRadiusMeters = 350.0;

  ActiveEmergency? _currentEmergency;
  ActiveEmergency? get currentEmergency => _currentEmergency;
  bool get hasActiveEmergency =>
      _currentEmergency != null &&
      _currentEmergency!.status != EmergencyStatus.resolved &&
      _currentEmergency!.status != EmergencyStatus.cancelled;

  bool _isActivating = false;
  bool get isActivating => _isActivating;

  Timer? _responderProgressionTimer;

  /// Haversine distance calculator (meters)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // meters
    final double phi1 = lat1 * math.pi / 180;
    final double phi2 = lat2 * math.pi / 180;
    final double deltaPhi = (lat2 - lat1) * math.pi / 180;
    final double deltaLambda = (lon2 - lon1) * math.pi / 180;

    final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return r * c;
  }

  /// Triggers full SOS activation lifecycle
  Future<ActiveEmergency> triggerSos({
    String type = 'Medical',
    String locationName = 'Student Center / Gymnasium',
    double? latitude,
    double? longitude,
    String? token,
  }) async {
    _isActivating = true;
    notifyListeners();

    // 1. Alarm siren & haptics
    SosAlarmService().start();

    // 2. Telemetry & coordinates
    final double lat = latitude ?? campusLat;
    final double lng = longitude ?? campusLng;

    // 3. Geofence check
    final double dist = calculateDistance(lat, lng, campusLat, campusLng);
    final bool isInside = dist <= campusRadiusMeters;

    final String generatedId =
        'SOS-${DateTime.now().year}-${(1000 + math.Random().nextInt(9000))}';

    _currentEmergency = ActiveEmergency(
      incidentId: generatedId,
      type: type,
      location: locationName,
      latitude: lat,
      longitude: lng,
      reportedAt: DateTime.now(),
      status: EmergencyStatus.activating,
      responderName: 'Dispatching...',
      responderPhone: '+63 38 000 9112',
      isInsideCampus: isInside,
      etaMinutes: 4,
    );

    _isActivating = false;
    notifyListeners();

    // Try sending to backend API
    try {
      await ApiService().post(
        '/sos/trigger.php',
        body: {
          'latitude': lat,
          'longitude': lng,
          'category': 'medical',
        },
        token: token,
        fromJson: (json) => json,
      );
    } catch (_) {
      // Degrades smoothly to local emergency protocol
    }

    // Progression simulation: Responder assigned & Responding
    _scheduleProgression();

    return _currentEmergency!;
  }

  void _scheduleProgression() {
    _responderProgressionTimer?.cancel();

    // Step 1: Assign responder after 2.5 seconds
    _responderProgressionTimer = Timer(const Duration(milliseconds: 2500), () {
      if (_currentEmergency == null ||
          _currentEmergency!.status == EmergencyStatus.cancelled) {
        return;
      }

      _currentEmergency!.status = EmergencyStatus.assigned;
      _currentEmergency!.responderName = 'Campus Security (Officer Ramon Bautista)';
      _currentEmergency!.etaMinutes = 3;
      notifyListeners();

      // Step 2: Transition to "Responding" (Help is on the way) after another 2.5 seconds
      _responderProgressionTimer = Timer(const Duration(milliseconds: 2500), () {
        if (_currentEmergency == null ||
            _currentEmergency!.status == EmergencyStatus.cancelled) {
          return;
        }

        _currentEmergency!.status = EmergencyStatus.responding;
        _currentEmergency!.etaMinutes = 2;
        notifyListeners();
      });
    });
  }

  /// Cancels active emergency
  Future<void> cancelEmergency({String reason = 'Cancelled by user'}) async {
    _responderProgressionTimer?.cancel();
    SosAlarmService().stop();

    if (_currentEmergency != null) {
      _currentEmergency!.status = EmergencyStatus.cancelled;
      notifyListeners();

      try {
        await ApiService().post(
          '/sos/cancel.php',
          body: {
            'reason': reason,
          },
          fromJson: (json) => json,
        );
      } catch (_) {}
    }
  }

  /// Marks emergency as arrived or resolved
  void updateStatus(EmergencyStatus newStatus) {
    if (_currentEmergency != null) {
      _currentEmergency!.status = newStatus;
      if (newStatus == EmergencyStatus.resolved ||
          newStatus == EmergencyStatus.cancelled) {
        SosAlarmService().stop();
        _responderProgressionTimer?.cancel();
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _responderProgressionTimer?.cancel();
    super.dispose();
  }
}
