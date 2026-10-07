import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Model for API responses
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      statusCode: json['statusCode'] ?? 200,
    );
  }
}

/// Backend API Service for BISU-Alert
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  /// Root of the BISU-Alert PHP API — the folder that holds `auth/`,
  /// `incidents/`, `alerts/` and friends. Endpoint paths below are appended to
  /// it verbatim, including the `.php` suffix.
  ///
  /// Defaults to:
  ///   - `http://localhost/bisu-alert/backend/api` on Windows, macOS, Linux, and Web
  ///   - `http://10.0.2.2/bisu-alert/backend/api` on Android Emulator
  ///
  /// Can be overridden via `--dart-define=API_BASE_URL=...` or at runtime.
  static String get defaultBaseUrl {
    const String fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost/bisu-alert/backend/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // Use port 8000 if the built-in PHP server is running; Apache runs on 80.
      return 'http://localhost:8000/bisu-alert/backend/api';
    }
    // Android emulator should target the host's built-in server on port 8000.
    return 'http://10.0.2.2:8000/bisu-alert/backend/api';
  }

  String? _customBaseUrl;

  /// Current base URL in use.
  String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  /// Set a runtime custom base URL (useful when testing with physical devices or dev servers).
  void setCustomBaseUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _customBaseUrl = null;
    } else {
      String clean = url.trim();
      if (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      _customBaseUrl = clean;
    }
  }

  /// Restores a previously configured custom base URL from persistent storage.
  Future<void> loadSavedBaseUrl() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString('custom_api_base_url');
      if (saved != null && saved.trim().isNotEmpty) {
        setCustomBaseUrl(saved);
      }
    } catch (_) {}
  }

  /// Pings the backend to verify whether the server and database are reachable.
  Future<bool> testConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/alerts/active.php'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  final http.Client _httpClient = http.Client();

  /// Get request headers with authentication token
  Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Build the exception for a failed response, preferring the API's own
  /// message over the bare status code.
  ///
  /// The PHP layer answers `{"success": false, "error": {"message": "...",
  /// "code": "..."}}`, and that message ("Incorrect password.", "Description is
  /// required.") is what a user actually needs to see. [fallback] is used when
  /// the body is not JSON at all — a PHP fatal, a proxy error page, and so on.
  ApiException _errorFor(String fallback, int statusCode, String body) {
    String message = fallback;
    String? code;

    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final dynamic error = decoded['error'];
        final dynamic rawMessage = error is Map
            ? error['message']
            : (decoded['message'] ?? error);
        if (rawMessage != null && '$rawMessage'.trim().isNotEmpty) {
          message = '$rawMessage'.trim();
        }
        if (error is Map && error['code'] != null) {
          code = '${error['code']}';
        }
      }
    } catch (_) {
      // Not JSON — `fallback` already names the status code.
    }

    return ApiException(message: message, statusCode: statusCode, code: code);
  }

  /// Make GET request
  Future<T> get<T>(
    String endpoint, {
    String? token,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return fromJson(data);
      } else {
        throw _errorFor(
          'Failed to load data: ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('GET Error: $e');
      }
      rethrow;
    }
  }

  /// Make POST request
  Future<T> post<T>(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return fromJson(data);
      } else {
        throw _errorFor(
          'Failed to create resource: ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('POST Error: $e');
      }
      rethrow;
    }
  }

  /// Make PUT request
  Future<T> put<T>(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _httpClient.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return fromJson(data);
      } else {
        throw _errorFor(
          'Failed to update resource: ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('PUT Error: $e');
      }
      rethrow;
    }
  }

  /// Make DELETE request
  Future<void> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _errorFor(
          'Failed to delete resource: ${response.statusCode}',
          response.statusCode,
          response.body,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('DELETE Error: $e');
      }
      rethrow;
    }
  }

  /// Upload file with multipart/form-data
  Future<T> uploadFile<T>(
    String endpoint, {
    required String filePath,
    required String fileField,
    Map<String, String>? additionalFields,
    String? token,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      request.headers.addAll(_getHeaders(token: token));
      request.files.add(
        await http.MultipartFile.fromPath(fileField, filePath),
      );

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return fromJson(data);
      } else {
        throw _errorFor(
          'File upload failed: ${response.statusCode}',
          response.statusCode,
          responseBody,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Upload Error: $e');
      }
      rethrow;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  /// Machine-readable code from the API's error envelope, e.g. `unknown_email`
  /// or `wrong_password`. Null when the response carried no code.
  final String? code;

  ApiException({
    required this.message,
    required this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}
