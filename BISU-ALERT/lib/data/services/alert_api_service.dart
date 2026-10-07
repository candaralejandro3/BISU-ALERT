import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Model for campus alert/announcement
class CampusAlert {
  final String id;
  final String title;
  final String message;
  final String priority; // low, medium, high, critical
  final String category; // Weather, Security, Announcement, Disaster
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? imageUrl;

  CampusAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.expiresAt,
    this.imageUrl,
  });

  factory CampusAlert.fromJson(Map<String, dynamic> json) {
    return CampusAlert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'low',
      category: json['category'] ?? 'Announcement',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      imageUrl: json['imageUrl'],
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isCritical => priority.toLowerCase() == 'critical';
  bool get isHigh => priority.toLowerCase() == 'high';
}

/// Model for paginated alert response
class AlertsResponse {
  final List<CampusAlert> alerts;
  final int total;
  final int limit;
  final int offset;

  AlertsResponse({
    required this.alerts,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    return AlertsResponse(
      alerts: (json['alerts'] as List?)
              ?.map((a) => CampusAlert.fromJson(a))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
    );
  }

  bool get hasMore => offset + limit < total;
}

/// Alert API Service
class AlertApiService {
  static final AlertApiService _instance = AlertApiService._internal();

  factory AlertApiService() {
    return _instance;
  }

  AlertApiService._internal();

  final ApiService _apiService = ApiService();

  /// Get alert feed with pagination
  Future<AlertsResponse> getAlertsFeed({
    int limit = 20,
    int offset = 0,
    String? category,
    String? token,
  }) async {
    try {
      String endpoint = '/alerts/list.php?limit=$limit&offset=$offset';
      if (category != null) {
        endpoint += '&category=$category';
      }

      return await _apiService.get(
        endpoint,
        token: token,
        fromJson: (json) => AlertsResponse.fromJson(json['data'] ?? json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching alerts: $e');
      }
      rethrow;
    }
  }

  /// Get specific alert details
  Future<CampusAlert> getAlert(
    String alertId, {
    String? token,
  }) async {
    try {
      return await _apiService.get(
        '/api/alerts/$alertId',
        token: token,
        fromJson: (json) => CampusAlert.fromJson(json['data'] ?? json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting alert: $e');
      }
      rethrow;
    }
  }

  /// Get critical alerts only (priority = critical)
  Future<List<CampusAlert>> getCriticalAlerts({
    String? token,
  }) async {
    try {
      final response = await getAlertsFeed(
        limit: 50,
        category: 'Critical',
        token: token,
      );
      return response.alerts
          .where((alert) => alert.isCritical && !alert.isExpired)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting critical alerts: $e');
      }
      return [];
    }
  }

  /// Get weather alerts
  Future<List<CampusAlert>> getWeatherAlerts({
    String? token,
  }) async {
    try {
      final response = await getAlertsFeed(
        limit: 20,
        category: 'Weather',
        token: token,
      );
      return response.alerts.where((alert) => !alert.isExpired).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting weather alerts: $e');
      }
      return [];
    }
  }

  /// Get security alerts
  Future<List<CampusAlert>> getSecurityAlerts({
    String? token,
  }) async {
    try {
      final response = await getAlertsFeed(
        limit: 20,
        category: 'Security',
        token: token,
      );
      return response.alerts.where((alert) => !alert.isExpired).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting security alerts: $e');
      }
      return [];
    }
  }
}
