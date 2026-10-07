import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDataService {
  static final ProfileDataService _instance = ProfileDataService._internal();
  factory ProfileDataService() => _instance;
  ProfileDataService._internal();

  // ICE Contact
  String iceName = 'Maria Santos Dela Cruz';
  String iceRelationship = 'Mother / Guardian';
  String icePhone = '+63 918 123 4567';

  // Medical Info
  String bloodType = 'O+';
  String allergies = 'None reported';
  String conditions = 'Asthma (mild)';

  // Emergency Settings
  bool sirenEnabled = true;
  bool flashlightStrobeEnabled = true;
  bool geofenceAlertsEnabled = true;

  // Notifications
  bool pushNotificationsEnabled = true;
  bool weatherAdvisoriesEnabled = true;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      iceName = prefs.getString('profile_ice_name') ?? iceName;
      iceRelationship = prefs.getString('profile_ice_relationship') ?? iceRelationship;
      icePhone = prefs.getString('profile_ice_phone') ?? icePhone;

      bloodType = prefs.getString('profile_blood_type') ?? bloodType;
      allergies = prefs.getString('profile_allergies') ?? allergies;
      conditions = prefs.getString('profile_conditions') ?? conditions;

      sirenEnabled = prefs.getBool('profile_siren_enabled') ?? sirenEnabled;
      flashlightStrobeEnabled =
          prefs.getBool('profile_flashlight_enabled') ?? flashlightStrobeEnabled;
      geofenceAlertsEnabled =
          prefs.getBool('profile_geofence_enabled') ?? geofenceAlertsEnabled;

      pushNotificationsEnabled =
          prefs.getBool('profile_push_enabled') ?? pushNotificationsEnabled;
      weatherAdvisoriesEnabled =
          prefs.getBool('profile_weather_enabled') ?? weatherAdvisoriesEnabled;

      _initialized = true;
    } catch (e) {
      debugPrint('ProfileDataService init error: $e');
    }
  }

  Future<void> saveIceContact({
    required String name,
    required String relationship,
    required String phone,
  }) async {
    iceName = name;
    iceRelationship = relationship;
    icePhone = phone;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_ice_name', name);
      await prefs.setString('profile_ice_relationship', relationship);
      await prefs.setString('profile_ice_phone', phone);
    } catch (e) {
      debugPrint('Error saving ICE contact: $e');
    }
  }

  Future<void> saveMedicalInfo({
    required String blood,
    required String allergy,
    required String condition,
  }) async {
    bloodType = blood;
    allergies = allergy;
    conditions = condition;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_blood_type', blood);
      await prefs.setString('profile_allergies', allergy);
      await prefs.setString('profile_conditions', condition);
    } catch (e) {
      debugPrint('Error saving medical info: $e');
    }
  }

  Future<void> setEmergencySettings({
    bool? siren,
    bool? flashlight,
    bool? geofence,
  }) async {
    if (siren != null) sirenEnabled = siren;
    if (flashlight != null) flashlightStrobeEnabled = flashlight;
    if (geofence != null) geofenceAlertsEnabled = geofence;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (siren != null) await prefs.setBool('profile_siren_enabled', siren);
      if (flashlight != null) {
        await prefs.setBool('profile_flashlight_enabled', flashlight);
      }
      if (geofence != null) {
        await prefs.setBool('profile_geofence_enabled', geofence);
      }
    } catch (e) {
      debugPrint('Error saving emergency settings: $e');
    }
  }

  Future<void> setNotificationSettings({
    bool? push,
    bool? weather,
  }) async {
    if (push != null) pushNotificationsEnabled = push;
    if (weather != null) weatherAdvisoriesEnabled = weather;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (push != null) await prefs.setBool('profile_push_enabled', push);
      if (weather != null) {
        await prefs.setBool('profile_weather_enabled', weather);
      }
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }
}
