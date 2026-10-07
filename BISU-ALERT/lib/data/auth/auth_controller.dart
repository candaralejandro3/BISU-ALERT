import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/app_user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _Account {
  _Account({required this.password, required this.user});

  String password;
  AppUser user;
}

/// Authentication for the BISU-Alert app.
///
/// Sign-in and registration go to the PHP backend first, so a session carries a
/// real bearer token and new accounts land in `bisu_alert26.users`. When the
/// server cannot be reached — no WAMP running, phone on another network — the
/// controller falls back to the in-memory registry below, which mirrors the
/// accounts seeded by `backend/database/02_seed.sql`. That keeps the demo
/// usable offline without ever accepting a password the server rejected.
///
/// Fallback accounts live only as long as the app process does; a restart
/// resets the registry to the seeded list.
class AuthController extends ChangeNotifier {
  static const String demoEmail = 'student@bisu.edu.ph';
  static const String demoPassword = 'bisualert';

  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  /// Mirrors section 5 of `backend/database/02_seed.sql`. Every seeded account
  /// uses [demoPassword]; keep the two lists in step when adding users.
  final Map<String, _Account> _accounts = <String, _Account>{
    demoEmail: _Account(
      password: demoPassword,
      user: const AppUser(
        fullName: 'Juan Dela Cruz',
        email: demoEmail,
        campusId: '2024-00123',
        role: CampusRole.student,
        department: 'College of Computer Studies',
        phoneNumber: '+63 917 456 1234',
        wantsEmergencyLocationAlerts: true,
      ),
    ),
    'security@bisu.edu.ph': _Account(
      password: demoPassword,
      user: const AppUser(
        fullName: 'Ramon Bautista',
        email: 'security@bisu.edu.ph',
        campusId: 'EMP-2019-0044',
        role: CampusRole.security,
        department: 'Campus Security Office',
        phoneNumber: '+63 38 000 9112',
        wantsEmergencyLocationAlerts: true,
      ),
    ),
    'clinic@bisu.edu.ph': _Account(
      password: demoPassword,
      user: const AppUser(
        fullName: 'Liza Mercado',
        email: 'clinic@bisu.edu.ph',
        campusId: 'EMP-2021-0117',
        role: CampusRole.staff,
        department: 'University Clinic',
        phoneNumber: '+63 38 000 9111',
        wantsEmergencyLocationAlerts: true,
      ),
    ),
    'faculty@bisu.edu.ph': _Account(
      password: demoPassword,
      user: const AppUser(
        fullName: 'Prof. Ana Reyes',
        email: 'faculty@bisu.edu.ph',
        campusId: 'EMP-2018-0201',
        role: CampusRole.faculty,
        department: 'College of Agriculture & Forestry',
        phoneNumber: '+63 917 222 8890',
        wantsEmergencyLocationAlerts: false,
      ),
    ),
    'maintenance@bisu.edu.ph': _Account(
      password: demoPassword,
      user: const AppUser(
        fullName: 'Mario Villanueva',
        email: 'maintenance@bisu.edu.ph',
        campusId: 'EMP-2020-0088',
        role: CampusRole.staff,
        department: 'Physical Plant & Maintenance',
        phoneNumber: '+63 918 552 3311',
        wantsEmergencyLocationAlerts: true,
      ),
    ),
    'registrar@bisu.edu.ph': _Account(
      password: demoPassword,
      user: const AppUser(
        fullName: 'Grace Lim',
        email: 'registrar@bisu.edu.ph',
        campusId: 'EMP-2017-0032',
        role: CampusRole.staff,
        department: 'Office of the Registrar',
        phoneNumber: '+63 917 883 4410',
        wantsEmergencyLocationAlerts: false,
      ),
    ),
    'guidance@bisu.edu.ph': _Account(
      password: demoPassword,
      user: const AppUser(
        fullName: 'Noel Aparece',
        email: 'guidance@bisu.edu.ph',
        campusId: 'EMP-2016-0011',
        role: CampusRole.faculty,
        department: 'Guidance & Counseling Office',
        phoneNumber: '+63 919 447 7725',
        wantsEmergencyLocationAlerts: true,
      ),
    ),
  };

  AppUser? _currentUser;
  bool _isBusy = false;
  String? _token;
  bool _isOfflineSession = false;

  AppUser? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  /// True while a sign-in or registration request is in flight.
  bool get isBusy => _isBusy;

  /// Bearer token for the signed-in user, or null when the session was served
  /// from the offline fallback. Screens that call the API should treat a null
  /// token as "the backend never saw this session".
  String? get token => _token;

  /// True when the current session came from the in-memory fallback because the
  /// backend was unreachable.
  bool get isOfflineSession => _isOfflineSession;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final String key = _normalize(email);

    await _run(() async {
      try {
        final AuthResponse response = await _authService.login(
          email: key,
          password: password,
        );

        final AppUser user = response.user.toAppUser();
        _token = response.token;
        _currentUser = user;
        _isOfflineSession = false;

        // Cache it so a later sign-in still works if WAMP goes away.
        _accounts[key] = _Account(password: password, user: user);
        return;
      } on ApiException catch (error) {
        // 401/403 is the server authoritatively rejecting the credentials or
        // the account. Falling back to the local list here would let a
        // disabled account in through the back door.
        if (error.statusCode == 401 || error.statusCode == 403) {
          throw AuthException(error.message);
        }
        if (kDebugMode) {
          print('Login fell back to offline accounts: $error');
        }
      } catch (error) {
        // Socket errors, DNS failures, timeouts, malformed responses.
        if (kDebugMode) {
          print('Login fell back to offline accounts: $error');
        }
      }

      _signInOffline(key, password);
    });
  }

  /// Sign in against the seeded registry when the backend is unreachable.
  void _signInOffline(String key, String password) {
    final _Account? account = _accounts[key];
    if (account == null) {
      throw const AuthException(
        'Cannot reach the BISU-Alert server, and no offline account uses that '
        'email. Check your connection and try again.',
      );
    }
    if (account.password != password) {
      throw const AuthException('Incorrect password. Please try again.');
    }

    _token = null;
    _currentUser = account.user;
    _isOfflineSession = true;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String campusId,
    required CampusRole role,
    required String department,
    required String phoneNumber,
    required String password,
    required bool wantsEmergencyLocationAlerts,
  }) async {
    final String key = _normalize(email);

    await _run(() async {
      try {
        final AuthResponse response = await _authService.register(
          fullName: fullName.trim(),
          email: key,
          campusId: campusId.trim(),
          role: role.name,
          department: department.trim(),
          phoneNumber: phoneNumber.trim(),
          password: password,
          wantsEmergencyLocationAlerts: wantsEmergencyLocationAlerts,
        );

        final AppUser user = response.user.toAppUser();
        _token = response.token;
        _currentUser = user;
        _isOfflineSession = false;
        _accounts[key] = _Account(password: password, user: user);
        return;
      } on ApiException catch (error) {
        // 409 email_taken, 422 validation, or database errors from the backend.
        throw AuthException(error.message);
      } catch (error) {
        if (kDebugMode) {
          print('Registration database connection failure: $error');
        }
        throw AuthException(
          'Cannot reach MySQL database at ${ApiService().baseUrl}. '
          'Please make sure WAMP / PHP backend server is running so the user is saved to the database.',
        );
      }
    });
  }

  void signOut() {
    if (_currentUser == null) {
      return;
    }
    _currentUser = null;
    _token = null;
    _isOfflineSession = false;
    // Fire-and-forget: the local session is gone either way, and a failed
    // round trip should not keep the user staring at the dashboard. `logout()`
    // swallows its own errors, so nothing escapes here.
    unawaited(_authService.logout());
    notifyListeners();
  }

  void updateProfile({
    String? campusId,
    String? department,
    String? phoneNumber,
    bool? wantsEmergencyLocationAlerts,
  }) {
    final AppUser? user = _currentUser;
    if (user == null) {
      return;
    }

    final AppUser updated = user.copyWith(
      campusId: campusId,
      department: department,
      phoneNumber: phoneNumber,
      wantsEmergencyLocationAlerts: wantsEmergencyLocationAlerts,
    );

    _currentUser = updated;
    _accounts[user.email]?.user = updated;
    notifyListeners();

    // Best effort push to the server; the local copy is already updated so the
    // settings screen stays responsive whether or not WAMP answers.
    if (_token != null) {
      unawaited(_pushProfile(
        campusId: campusId,
        department: department,
        phoneNumber: phoneNumber,
        wantsEmergencyLocationAlerts: wantsEmergencyLocationAlerts,
      ));
    }
  }

  /// Change password with backend sync and offline account support.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final AppUser? user = _currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to change your password.');
    }

    await _run(() async {
      try {
        if (_token != null) {
          await _authService.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
        }
        // Update local offline registry if present
        final String key = _normalize(user.email);
        final _Account? acc = _accounts[key];
        if (acc != null) {
          if (acc.password != currentPassword && _token == null) {
            throw const AuthException('Current password does not match.');
          }
          acc.password = newPassword;
        }
      } on ApiException catch (e) {
        throw AuthException(e.message);
      }
    });
  }

  /// Delete account and clear credentials.
  Future<void> deleteAccount() async {
    final AppUser? user = _currentUser;
    if (user == null) return;

    await _run(() async {
      try {
        if (_token != null) {
          await _authService.deleteAccount();
        }
        final String key = _normalize(user.email);
        _accounts.remove(key);
      } catch (e) {
        if (kDebugMode) {
          print('Account deletion note: $e');
        }
      } finally {
        signOut();
      }
    });
  }

  /// Mirrors a local profile edit to the backend, absorbing failures so an
  /// offline save still looks like a save.
  Future<void> _pushProfile({
    String? campusId,
    String? department,
    String? phoneNumber,
    bool? wantsEmergencyLocationAlerts,
  }) async {
    try {
      await _authService.updateProfile(
        campusId: campusId,
        department: department,
        phoneNumber: phoneNumber,
        wantsEmergencyLocationAlerts: wantsEmergencyLocationAlerts,
      );
    } catch (error) {
      if (kDebugMode) {
        print('Profile sync to the server failed: $error');
      }
    }
  }

  Future<void> _run(FutureOr<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _normalize(String email) => email.trim().toLowerCase();
}
