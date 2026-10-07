import 'package:flutter/material.dart';

enum IncidentCategory {
  medical,
  fireHazard,
  security,
  facilityDamage,
  accident,
  naturalHazard,
  other,
}

extension IncidentCategoryLabel on IncidentCategory {
  String get label {
    switch (this) {
      case IncidentCategory.medical:
        return 'Medical';
      case IncidentCategory.fireHazard:
        return 'Fire';
      case IncidentCategory.security:
        return 'Security';
      case IncidentCategory.facilityDamage:
        return 'Facility Damage';
      case IncidentCategory.accident:
        return 'Accident';
      case IncidentCategory.naturalHazard:
        return 'Natural Hazard';
      case IncidentCategory.other:
        return 'Other';
    }
  }

  /// The `incident_categories.code` value the API expects in a report body.
  String get code {
    switch (this) {
      case IncidentCategory.medical:
        return 'medical';
      case IncidentCategory.fireHazard:
        return 'fire_hazard';
      case IncidentCategory.security:
        return 'security';
      case IncidentCategory.facilityDamage:
        return 'facility_damage';
      case IncidentCategory.accident:
        return 'accident';
      case IncidentCategory.naturalHazard:
        return 'natural_hazard';
      case IncidentCategory.other:
        return 'other';
    }
  }

  /// Icon used on the report screen's category chips.
  IconData get icon {
    switch (this) {
      case IncidentCategory.medical:
        return Icons.medical_services_outlined;
      case IncidentCategory.fireHazard:
        return Icons.local_fire_department_outlined;
      case IncidentCategory.security:
        return Icons.shield_outlined;
      case IncidentCategory.facilityDamage:
        return Icons.construction_outlined;
      case IncidentCategory.accident:
        return Icons.car_crash_outlined;
      case IncidentCategory.naturalHazard:
        return Icons.cyclone_outlined;
      case IncidentCategory.other:
        return Icons.report_problem_outlined;
    }
  }
}

enum IncidentSeverity {
  low,
  moderate,
  high,
  critical,
}

extension IncidentSeverityExtension on IncidentSeverity {
  String get label {
    switch (this) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.moderate:
        return 'Moderate';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case IncidentSeverity.low:
        return const Color(0xFF2E7D32);
      case IncidentSeverity.moderate:
        return const Color(0xFF0288D1);
      case IncidentSeverity.high:
        return const Color(0xFFED6C02);
      case IncidentSeverity.critical:
        return const Color(0xFFD32F2F);
    }
  }
}
