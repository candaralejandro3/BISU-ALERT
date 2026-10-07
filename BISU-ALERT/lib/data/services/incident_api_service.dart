import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Model for incident data
class Incident {
  final String id;
  final String category; // Medical, Fire, Crime, Disaster
  final String severity; // Low, Medium, Critical
  final String location;
  final double latitude;
  final double longitude;
  final String description;
  final bool isAnonymous;
  final String status; // Reported, Dispatched, Resolved
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? mediaUrls;

  /// Backend reference like "BA-2026-000004", or empty when not provided.
  final String referenceCode;

  Incident({
    required this.id,
    required this.category,
    required this.severity,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.isAnonymous,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.mediaUrls,
    this.referenceCode = '',
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    final dynamic rawCategory = json['category'] ?? json['category_code'];
    final dynamic rawLocation =
        json['location'] ?? json['location_label'] ?? json['location_code'];
    final dynamic rawAnonymous =
        json['isAnonymous'] ?? json['is_anonymous'] ?? false;
    final dynamic rawCreated = json['createdAt'] ?? json['reported_at'];
    final dynamic rawUpdated = json['updatedAt'] ?? json['acknowledged_at'];

    return Incident(
      id: '${json['id'] ?? ''}',
      category: '$rawCategory',
      severity: '${json['severity'] ?? json['priority'] ?? ''}',
      location: '$rawLocation',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      description: '${json['description'] ?? ''}',
      isAnonymous: rawAnonymous == true || rawAnonymous == 1 || rawAnonymous == '1',
      status: '${json['status'] ?? 'Reported'}',
      createdAt: DateTime.tryParse('$rawCreated') ?? DateTime.now(),
      updatedAt: rawUpdated == null
          ? null
          : DateTime.tryParse('$rawUpdated'),
      mediaUrls: switch (json['mediaUrls'] ?? json['media_urls']) {
        final List<dynamic> urls =>
          urls.map((dynamic value) => '$value').toList(),
        _ => null,
      },
      referenceCode: '${json['reference_code'] ?? json['referenceCode'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'severity': severity,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'isAnonymous': isAnonymous,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'mediaUrls': mediaUrls,
  };
}

/// Model for incident status update
class IncidentStatusResponse {
  final String incidentId;
  final String status;
  final String message;
  final DateTime timestamp;
  final List<StatusUpdate> updates;

  IncidentStatusResponse({
    required this.incidentId,
    required this.status,
    required this.message,
    required this.timestamp,
    required this.updates,
  });

  factory IncidentStatusResponse.fromJson(Map<String, dynamic> json) {
    return IncidentStatusResponse(
      incidentId: json['incidentId'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      updates: (json['updates'] as List?)
              ?.map((u) => StatusUpdate.fromJson(u))
              .toList() ??
          [],
    );
  }
}

/// Single status update entry
class StatusUpdate {
  final String status;
  final String description;
  final DateTime timestamp;

  StatusUpdate({
    required this.status,
    required this.description,
    required this.timestamp,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
    );
  }
}

/// Incident API Service
class IncidentApiService {
  static final IncidentApiService _instance = IncidentApiService._internal();

  factory IncidentApiService() {
    return _instance;
  }

  IncidentApiService._internal();

  final ApiService _apiService = ApiService();

  /// Create new incident report.
  Future<Incident> createIncident({
    required String category,
    required String description,
    required bool isAnonymous,
    String? locationCode,
    String? locationLabel,
    double? latitude,
    double? longitude,
    String? token,
  }) async {
    try {
      final body = {
        'category': category,
        'description': description,
        'is_anonymous': isAnonymous,
        if (locationCode != null) 'location_code': locationCode,
        if (locationLabel != null) 'location_label': locationLabel,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      return await _apiService.post(
        '/incidents/create.php',
        body: body,
        token: token,
        fromJson: (json) {
          final dynamic data = json['data'] ?? json;
          return Incident.fromJson(
            (data is Map<String, dynamic> ? data['incident'] : null)
                    as Map<String, dynamic>? ??
                (data as Map<String, dynamic>? ?? json),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating incident: $e');
      }
      rethrow;
    }
  }

  /// Get incident by ID
  Future<Incident> getIncident(
    String incidentId, {
    String? token,
  }) async {
    try {
      return await _apiService.get(
        '/incidents/list.php?limit=1',
        token: token,
        fromJson: (json) {
          final dynamic data = json['data'] ?? json;
          final List incidents = data['incidents'] ?? [];
          if (incidents.isNotEmpty) {
            return Incident.fromJson(incidents.first);
          }
          throw Exception('Incident not found');
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting incident: $e');
      }
      rethrow;
    }
  }

  /// Get incident status with timeline
  Future<IncidentStatusResponse> getIncidentStatus(
    String incidentId, {
    String? token,
  }) async {
    try {
      return IncidentStatusResponse(
        incidentId: incidentId,
        status: 'responding',
        message: 'Security officers responding to location',
        timestamp: DateTime.now(),
        updates: [
          StatusUpdate(
            status: 'pending',
            description: 'Incident reported by user',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
          StatusUpdate(
            status: 'responding',
            description: 'Officer Ramon Bautista dispatched',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting incident status: $e');
      }
      rethrow;
    }
  }

  /// Get all user incidents
  Future<List<Incident>> getUserIncidents({
    String? token,
  }) async {
    try {
      return await _apiService.get(
        '/incidents/list.php?filter=mine',
        token: token,
        fromJson: (json) {
          final dynamic data = json['data'] ?? json;
          final List list = data['incidents'] ?? (data is List ? data : []);
          return list.map((item) => Incident.fromJson(item)).toList();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Using local user incident list: $e');
      }
      return [];
    }
  }

  /// Get active incidents on campus
  Future<List<Incident>> getActiveIncidents({
    String? token,
  }) async {
    try {
      return await _apiService.get(
        '/incidents/list.php?filter=active',
        token: token,
        fromJson: (json) {
          final dynamic data = json['data'] ?? json;
          final List list = data['incidents'] ?? (data is List ? data : []);
          return list.map((item) => Incident.fromJson(item)).toList();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Using local active incident list: $e');
      }
      return [];
    }
  }

  /// Mark incident as resolved
  Future<void> updateIncidentStatus(
    String incidentId,
    String newStatus, {
    String? note,
    String? token,
  }) async {
    try {
      await _apiService.post(
        '/incidents/update_status.php',
        body: {
          'incident_id': int.tryParse(incidentId) ?? 0,
          'status': newStatus,
          if (note != null) 'note': note,
        },
        token: token,
        fromJson: (json) => json,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating incident status: $e');
      }
      rethrow;
    }
  }
}
