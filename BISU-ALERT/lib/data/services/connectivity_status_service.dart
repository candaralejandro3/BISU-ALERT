import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Connectivity Status Service - singleton pattern
class ConnectivityStatusService {
  static final ConnectivityStatusService _instance =
      ConnectivityStatusService._internal();

  factory ConnectivityStatusService() {
    return _instance;
  }

  ConnectivityStatusService._internal();

  final Connectivity _connectivity = Connectivity();
  late Stream<List<ConnectivityResult>> _connectivityStream;
  ConnectivityStatus _status = ConnectivityStatus.unknown;

  ConnectivityStatus get status => _status;
  Stream<ConnectivityStatus> get statusStream =>
      _connectivityStream.map(_parseConnectivityResult);

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _status = _parseConnectivityResult(result);

      _connectivityStream = _connectivity.onConnectivityChanged;
      _connectivityStream.listen((result) {
        _status = _parseConnectivityResult(result);
        if (kDebugMode) {
          print('Connectivity status changed: $_status');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing connectivity: $e');
      }
    }
  }

  /// Parse stream result (multiple results)
  ConnectivityStatus _parseConnectivityResult(
    List<ConnectivityResult> result,
  ) {
    if (result.isEmpty) {
      return ConnectivityStatus.unknown;
    }
    
    // If any connection is active, we're online
    if (result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet)) {
      return ConnectivityStatus.online;
    }
    
    if (result.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    
    return ConnectivityStatus.unknown;
  }

  /// Check if device is online
  bool isOnline() => _status == ConnectivityStatus.online;

  /// Get status as string
  String getStatusText() {
    return switch (_status) {
      ConnectivityStatus.online => 'Online',
      ConnectivityStatus.offline => 'Offline',
      ConnectivityStatus.unknown => 'Unknown',
    };
  }

  /// Get status icon
  IconData getStatusIcon() {
    return switch (_status) {
      ConnectivityStatus.online => Icons.cloud_done,
      ConnectivityStatus.offline => Icons.cloud_off,
      ConnectivityStatus.unknown => Icons.cloud_queue,
    };
  }
}
