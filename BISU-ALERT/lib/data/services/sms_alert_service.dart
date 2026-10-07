import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsAlertService {
  /// BISU Bilar Campus Security Hotline
  /// TODO: Replace with actual campus security hotline number
  /// Format: +63XXXXXXXXXX (Philippines)
  static const String campusSecurityHotline = '+639123456789';

  /// Backup emergency numbers
  static const String policeEmergency = '911'; // PNP
  static const String medicalEmergency = '911'; // BFP/Ambulance
  static const String disasterManagement = '09209662687'; // MDRRMO Negros Oriental

  /// Send SOS alert via SMS when offline
  static Future<bool> sendSosAlert({
    required String phoneNumber,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final String message = 'ALERT|SOS|Campus Bilar|Lat:$latitude,Long:$longitude|Emergency assistance needed';
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending SMS alert: $e');
      }
      return false;
    }
  }

  /// Send SOS alert to campus security
  static Future<bool> sendSosToCampusSecurity({
    required double latitude,
    required double longitude,
  }) async {
    return sendSosAlert(
      phoneNumber: campusSecurityHotline,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Send SOS alert to emergency services
  static Future<bool> sendSosToEmergency({
    required double latitude,
    required double longitude,
  }) async {
    return sendSosAlert(
      phoneNumber: policeEmergency,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Send incident report via SMS when offline
  static Future<bool> sendIncidentReportSms({
    required String phoneNumber,
    required String incidentType, // Medical, Fire, Crime, Disaster
    required String location,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final String message = 'INCIDENT|$incidentType|$location|Lat:$latitude,Long:$longitude|Desc:${description ?? 'No description'}';
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending incident SMS: $e');
      }
      return false;
    }
  }
}
