import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String _cachedAlertsKey = 'cached_alerts';
  static const String _cachedContactsKey = 'cached_contacts';
  static const String _cachedMapKey = 'cached_map_data';
  static const String _cachedReportsKey = 'cached_reports';

  /// Cache alerts for offline access
  static Future<void> cacheAlerts(List<Map<String, dynamic>> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(alerts);
      await prefs.setString(_cachedAlertsKey, jsonString);
    } catch (e) {
      debugPrint('Error caching alerts: $e');
    }
  }

  /// Retrieve cached alerts
  static Future<List<Map<String, dynamic>>> getCachedAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedAlertsKey);
      if (jsonString != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      debugPrint('Error retrieving cached alerts: $e');
    }
    return [];
  }

  /// Cache emergency contacts for offline access
  static Future<void> cacheContacts(List<Map<String, dynamic>> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(contacts);
      await prefs.setString(_cachedContactsKey, jsonString);
    } catch (e) {
      debugPrint('Error caching contacts: $e');
    }
  }

  /// Retrieve cached contacts
  static Future<List<Map<String, dynamic>>> getCachedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedContactsKey);
      if (jsonString != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      debugPrint('Error retrieving cached contacts: $e');
    }
    return [];
  }

  /// Cache map data for offline access
  static Future<void> cacheMapData(Map<String, dynamic> mapData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(mapData);
      await prefs.setString(_cachedMapKey, jsonString);
    } catch (e) {
      debugPrint('Error caching map data: $e');
    }
  }

  /// Retrieve cached map data
  static Future<Map<String, dynamic>> getCachedMapData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedMapKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      debugPrint('Error retrieving cached map data: $e');
    }
    return {};
  }

  /// Store a pending report to be synced when online
  static Future<void> savePendingReport(Map<String, dynamic> report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingReports =
          prefs.getStringList(_cachedReportsKey) ?? [];
      pendingReports.add(jsonEncode(report));
      await prefs.setStringList(_cachedReportsKey, pendingReports);
    } catch (e) {
      debugPrint('Error saving pending report: $e');
    }
  }

  /// Get all pending reports
  static Future<List<Map<String, dynamic>>> getPendingReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingReports =
          prefs.getStringList(_cachedReportsKey) ?? [];
      return pendingReports
          .map((report) => Map<String, dynamic>.from(jsonDecode(report)))
          .toList();
    } catch (e) {
      debugPrint('Error retrieving pending reports: $e');
    }
    return [];
  }

  /// Clear a pending report after successful sync
  static Future<void> clearPendingReport(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingReports =
          prefs.getStringList(_cachedReportsKey) ?? [];
      if (index < pendingReports.length) {
        pendingReports.removeAt(index);
        await prefs.setStringList(_cachedReportsKey, pendingReports);
      }
    } catch (e) {
      debugPrint('Error clearing pending report: $e');
    }
  }
}
