import 'package:flutter/material.dart';

enum LocationType {
  emergencyHub,
  clinic,
  security,
  fireEquipment,
  evacuationZone,
  emergencyExit,
  fireExtinguisher,
  building,
}

extension LocationTypeExtension on LocationType {
  String get label {
    switch (this) {
      case LocationType.emergencyHub:
        return 'Emergency Hubs';
      case LocationType.clinic:
        return 'Clinic';
      case LocationType.security:
        return 'Security';
      case LocationType.fireEquipment:
        return 'Fire Equipment';
      case LocationType.evacuationZone:
        return 'Evacuation Zones';
      case LocationType.emergencyExit:
        return 'Emergency Exits';
      case LocationType.fireExtinguisher:
        return 'Fire Extinguishers';
      case LocationType.building:
        return 'Buildings';
    }
  }

  IconData get icon {
    switch (this) {
      case LocationType.emergencyHub:
        return Icons.emergency_outlined;
      case LocationType.clinic:
        return Icons.local_hospital_outlined;
      case LocationType.security:
        return Icons.shield_outlined;
      case LocationType.fireEquipment:
        return Icons.fire_truck_outlined;
      case LocationType.evacuationZone:
        return Icons.health_and_safety_outlined;
      case LocationType.emergencyExit:
        return Icons.door_front_door_outlined;
      case LocationType.fireExtinguisher:
        return Icons.water_drop_outlined;
      case LocationType.building:
        return Icons.business_outlined;
    }
  }

  Color get color {
    switch (this) {
      case LocationType.emergencyHub:
        return const Color(0xFF2E7D32); // Green
      case LocationType.clinic:
        return const Color(0xFFE53935); // Red
      case LocationType.security:
        return const Color(0xFF1976D2); // Blue
      case LocationType.fireEquipment:
        return const Color(0xFFD84315); // Deep orange
      case LocationType.evacuationZone:
        return const Color(0xFFFBC02D); // Yellow / Amber
      case LocationType.emergencyExit:
        return const Color(0xFF00897B); // Teal
      case LocationType.fireExtinguisher:
        return const Color(0xFFC2185B); // Pinkish red
      case LocationType.building:
        return const Color(0xFF546E7A); // Slate
    }
  }
}

class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.contactNumber,
    this.landmarkCode,
  });

  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final LocationType type;
  final String contactNumber;
  final String? landmarkCode;
}
