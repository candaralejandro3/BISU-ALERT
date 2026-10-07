import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Emergency contact model
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String location;
  final String category; // Security, Medical, Disaster, Clinic
  final String? description;
  final double? latitude;
  final double? longitude;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.location,
    required this.category,
    this.description,
    this.latitude,
    this.longitude,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'location': location,
    'category': category,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Emergency Contact API Service
class EmergencyContactApiService {
  static final EmergencyContactApiService _instance =
      EmergencyContactApiService._internal();

  factory EmergencyContactApiService() {
    return _instance;
  }

  EmergencyContactApiService._internal();

  final ApiService _apiService = ApiService();

  /// Get all emergency contacts
  Future<List<EmergencyContact>> getContacts({
    String? token,
  }) async {
    try {
      return await _apiService.get(
        '/contacts/list.php',
        token: token,
        fromJson: (json) {
          final list = json['data'] ?? json;
          return (list as List)
              .map((item) => EmergencyContact.fromJson(item))
              .toList();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching emergency contacts: $e');
      }
      rethrow;
    }
  }

  /// Get contacts by category
  Future<List<EmergencyContact>> getContactsByCategory(
    String category, {
    String? token,
  }) async {
    try {
      final allContacts = await getContacts(token: token);
      return allContacts
          .where((contact) =>
              contact.category.toLowerCase() == category.toLowerCase())
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching contacts by category: $e');
      }
      rethrow;
    }
  }
}
