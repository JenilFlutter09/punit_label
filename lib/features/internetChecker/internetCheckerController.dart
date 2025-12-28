import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
/*

class InternetCheckerController extends GetxController {
  final RxBool isConnected = true.obs;
  late final StreamSubscription<ConnectivityResult> _subscription;

  @override
  void onInit() {
    super.onInit();
    _monitorConnection();
  }

  void _monitorConnection() {
    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkConnection();
    });

    // Also check every 10 seconds
    Timer.periodic(Duration(seconds: 10), (_) => _checkConnection());

    // Initial check
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      isConnected.value = false;
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://clients3.google.com/generate_204'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      // .timeout(Duration(seconds: 5));

      isConnected.value = response.statusCode == 204;
    } catch (e) {
      print("Internet check failed: $e");
      isConnected.value = false;
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
*/
import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class InternetCheckerController extends GetxController {
  final RxBool isConnected = true.obs;

  late final StreamSubscription<ConnectivityResult> _subscription;
  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  void _startMonitoring() {
    // Listen to connectivity changes (WiFi/Mobile/None)
    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkConnection();
    });

    // Periodic real internet availability check
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => _checkConnection(),
    );

    // Immediate initial check
    _checkConnection();
  }

  /// Actual check for internet access (not just network)
  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      isConnected.value = false;
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('https://1.1.1.1'))
          .timeout(const Duration(seconds: 4));

      isConnected.value = response.statusCode == 200;
    } catch (e) {
      isConnected.value = false;
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    _periodicTimer?.cancel();
    super.onClose();
  }
}
