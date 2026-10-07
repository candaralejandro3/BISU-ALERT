import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _lastResults = [ConnectivityResult.none];

  ConnectivityService() {
    _init();
  }

  List<ConnectivityResult> get lastResults => _lastResults;

  bool get isOnline {
    return !_lastResults.contains(ConnectivityResult.none) &&
        (_lastResults.contains(ConnectivityResult.mobile) ||
            _lastResults.contains(ConnectivityResult.wifi) ||
            _lastResults.contains(ConnectivityResult.ethernet));
  }

  Future<void> _init() async {
    try {
      _lastResults = await _connectivity.checkConnectivity();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
    }

    _connectivity.onConnectivityChanged.listen((result) {
      _lastResults = result;
      notifyListeners();
    });
  }
}
