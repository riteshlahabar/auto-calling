// lib/core/network/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  ConnectivityService() {
    _sub = Connectivity().onConnectivityChanged.listen(_onConnChanged);
    _checkReachability(); // prime initial value
  }

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Note: connectivity_plus v6+ emits List<ConnectivityResult>
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _onConnChanged(List<ConnectivityResult> _) async {
    // Do not infer from connectivity alone; verify real internet reachability
    await _checkReachability();
  }

  Future<void> _checkReachability() async {
    final ok = await InternetConnection().hasInternetAccess;
    if (ok != _isOnline) {
      _isOnline = ok;
      _controller.add(_isOnline);
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
