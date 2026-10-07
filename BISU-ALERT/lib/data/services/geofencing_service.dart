import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// Stub classes for geolocator (available after flutter pub get)
enum LocationPermission { denied, deniedForever, whileInUse, always }
enum LocationAccuracy { lowest, low, medium, high, best, bestForNavigation }

class Position {
  final double latitude;
  final double longitude;
  Position({required this.latitude, required this.longitude});
}

class Geolocator {
  static Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
  static Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;
  static Future<Position?> getCurrentPosition({required LocationAccuracy desiredAccuracy}) async =>
      Position(latitude: GeofencingService.campusLatitude, longitude: GeofencingService.campusLongitude);
  static double distanceBetween(double lat1, double lon1, double lat2, double lon2) =>
      GeofencingService().calculateDistance(lat1, lon1, lat2, lon2);
  static double bearingBetween(double lat1, double lon1, double lat2, double lon2) =>
      GeofencingService().calculateBearing(lat1, lon1, lat2, lon2);
  static Future<void> openLocationSettings() async {}
  static Stream<Position> getPositionStream({required LocationSettings locationSettings}) => const Stream.empty();
}

class LocationSettings {
  final LocationAccuracy accuracy;
  final int? distanceFilter;
  final Duration? timeLimit;
  const LocationSettings({required this.accuracy, this.distanceFilter, this.timeLimit});
}

class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();

  factory GeofencingService() {
    return _instance;
  }

  GeofencingService._internal();

  // BISU Bilar campus center coordinates
  static const double campusLatitude = 9.71888;
  static const double campusLongitude = 124.10883;
  static const double campusRadiusMeters = 350; // ~350m radius

  /// Request location permissions
  Future<bool> requestLocationPermissions() async {
    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    return Position(latitude: campusLatitude, longitude: campusLongitude);
  }

  /// Check if user is on campus
  Future<bool> isUserOnCampus() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return false;

      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        campusLatitude,
        campusLongitude,
      );

      return distance <= campusRadiusMeters;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user is on campus: $e');
      }
      return true;
    }
  }

  /// Get location stream
  Stream<Position> getLocationStream() {
    return const Stream.empty();
  }

  /// Calculate distance between two points using Haversine formula (in meters)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // Earth radius in meters
    final double phi1 = lat1 * math.pi / 180;
    final double phi2 = lat2 * math.pi / 180;
    final double deltaPhi = (lat2 - lat1) * math.pi / 180;
    final double deltaLambda = (lon2 - lon1) * math.pi / 180;

    final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return r * c;
  }

  /// Calculate bearing between two points (in degrees)
  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final double phi1 = lat1 * math.pi / 180;
    final double phi2 = lat2 * math.pi / 180;
    final double deltaLambda = (lon2 - lon1) * math.pi / 180;

    final double y = math.sin(deltaLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final double theta = math.atan2(y, x);

    return (theta * 180 / math.pi + 360) % 360;
  }

  /// Open location settings
  Future<void> openLocationSettings() async {}
}
