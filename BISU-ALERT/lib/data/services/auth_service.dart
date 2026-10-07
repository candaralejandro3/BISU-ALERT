import 'package:flutter/foundation.dart';
import '../model/app_user.dart';
import 'api_service.dart';

/// Model for user data
class User {
  final String id;
  final String email;

  /// Full name as stored in `users.full_name`. [firstName]/[lastName] are
  /// derived from it, since the backend keeps one name column.
  final String fullName;
  final String firstName;
  final String lastName;
  final String? idNumber;
  final String? phone;
  final String role; // student, faculty, staff, security, visitor
  final String? department;
  final bool wantsEmergencyLocationAlerts;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    this.idNumber,
    this.phone,
    required this.role,
    this.department,
    this.wantsEmergencyLocationAlerts = true,
    required this.createdAt,
  });

  /// Accepts either the PHP API's snake_case shape (see `shape_user()` in
  /// `api/config/bootstrap.php`) or the camelCase shape this model writes back
  /// out, so a cached [toJson] payload still round-trips.
  factory User.fromJson(Map<String, dynamic> json) {
    final String name = '${json['full_name'] ?? json['fullName'] ?? ''}'.trim();
    final List<String> parts = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    final dynamic wantsAlerts = json['wants_emergency_location_alerts'] ??
        json['wantsEmergencyLocationAlerts'];
    final dynamic created = json['created_at'] ?? json['createdAt'];

    return User(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      fullName: name,
      // A single-word name keeps the whole thing as the first name rather than
      // leaving an empty string behind.
      firstName: '${json['firstName'] ?? (parts.isEmpty ? '' : parts.first)}',
      lastName:
          '${json['lastName'] ?? (parts.length < 2 ? '' : parts.skip(1).join(' '))}',
      idNumber: _optional(json['campus_id'] ?? json['idNumber']),
      phone: _optional(json['phone_number'] ?? json['phone']),
      role: '${json['role'] ?? 'student'}',
      department: _optional(json['department']),
      wantsEmergencyLocationAlerts:
          wantsAlerts == null || wantsAlerts == true || wantsAlerts == 1 || wantsAlerts == '1',
      createdAt: DateTime.tryParse('$created') ?? DateTime.now(),
    );
  }

  static String? _optional(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'firstName': firstName,
    'lastName': lastName,
    'idNumber': idNumber,
    'phone': phone,
    'role': role,
    'department': department,
    'wantsEmergencyLocationAlerts': wantsEmergencyLocationAlerts,
    'createdAt': createdAt.toIso8601String(),
  };

  /// The UI layer speaks [AppUser]; this is the one place the two shapes meet.
  AppUser toAppUser() {
    return AppUser(
      fullName: fullName.isEmpty ? email : fullName,
      email: email,
      campusId: idNumber ?? '',
      role: campusRoleFromCode(role),
      department: department ?? '',
      phoneNumber: phone ?? '',
      wantsEmergencyLocationAlerts: wantsEmergencyLocationAlerts,
    );
  }
}

/// Maps a `campus_roles.code` value onto the app's [CampusRole] enum.
CampusRole campusRoleFromCode(String code) {
  return switch (code.trim().toLowerCase()) {
    'faculty' => CampusRole.faculty,
    'staff' => CampusRole.staff,
    'security' => CampusRole.security,
    'visitor' => CampusRole.visitor,
    _ => CampusRole.student,
  };
}

/// Model for auth response
class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

/// Authentication Service
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final ApiService _apiService = ApiService();

  String? _token;
  User? _currentUser;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// User login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
      };

      final response = await _apiService.post(
        '/auth/login.php',
        body: body,
        fromJson: (json) => AuthResponse.fromJson(json['data'] ?? json),
      );

      _token = response.token;
      _currentUser = response.user;

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error logging in: $e');
      }
      rethrow;
    }
  }

  /// User registration.
  ///
  /// Mirrors the body `api/auth/register.php` expects. The backend re-checks the
  /// same rules the register form does and answers 409 `email_taken` or 422
  /// (`invalid_email` | `weak_password` | `invalid_phone` | `unknown_role`).
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String campusId,
    required String role,
    required String department,
    required String phoneNumber,
    required String password,
    bool wantsEmergencyLocationAlerts = true,
  }) async {
    try {
      final body = {
        'full_name': fullName,
        'email': email,
        'campus_id': campusId,
        'role': role,
        'department': department,
        'phone_number': phoneNumber,
        'password': password,
        'wants_emergency_location_alerts': wantsEmergencyLocationAlerts,
      };

      final response = await _apiService.post(
        '/auth/register.php',
        body: body,
        fromJson: (json) => AuthResponse.fromJson(json['data'] ?? json),
      );

      _token = response.token;
      _currentUser = response.user;

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error registering: $e');
      }
      rethrow;
    }
  }

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      return await _apiService.get(
        '/auth/me.php',
        token: _token,
        fromJson: (json) {
          final dynamic data = json['data'] ?? json;
          return User.fromJson(
            (data is Map<String, dynamic> ? data['user'] : null)
                    as Map<String, dynamic>? ??
                data as Map<String, dynamic>,
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting profile: $e');
      }
      rethrow;
    }
  }

  /// Partial update of the signed-in user's own profile.
  ///
  /// `api/users/update_profile.php` takes POST (not PUT), applies only the keys
  /// present in the body, and rejects an empty body with 422 `no_changes`.
  /// Identity fields (name, email, role) are deliberately not editable here.
  Future<User> updateProfile({
    String? campusId,
    String? department,
    String? phoneNumber,
    bool? wantsEmergencyLocationAlerts,
  }) async {
    try {
      final body = {
        if (campusId != null) 'campus_id': campusId,
        if (department != null) 'department': department,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (wantsEmergencyLocationAlerts != null)
          'wants_emergency_location_alerts': wantsEmergencyLocationAlerts,
      };

      final user = await _apiService.post(
        '/users/update_profile.php',
        body: body,
        token: _token,
        fromJson: (json) {
          final dynamic data = json['data'] ?? json;
          return User.fromJson(
            (data is Map<String, dynamic> ? data['user'] : null)
                    as Map<String, dynamic>? ??
                data as Map<String, dynamic>,
          );
        },
      );

      _currentUser = user;
      return user;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      rethrow;
    }
  }

  /// User logout
  Future<void> logout() async {
    try {
      await _apiService.post(
        '/auth/logout.php',
        body: {},
        token: _token,
        fromJson: (json) => json,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error logging out: $e');
      }
    } finally {
      _token = null;
      _currentUser = null;
    }
  }

  /// Change user account password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        '/auth/change_password.php',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        token: _token,
        fromJson: (json) => json,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error changing password: $e');
      }
      rethrow;
    }
  }

  /// Delete user account and revoke all sessions
  Future<void> deleteAccount() async {
    try {
      await _apiService.post(
        '/auth/delete_account.php',
        body: {},
        token: _token,
        fromJson: (json) => json,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      rethrow;
    } finally {
      clear();
    }
  }

  /// Set token (for testing or restoring from storage)
  void setToken(String token) {
    _token = token;
  }

  /// Clear authentication
  void clear() {
    _token = null;
    _currentUser = null;
  }
}
