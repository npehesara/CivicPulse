import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// Service that pings the backend when the app starts so that the Render
/// free-tier instance has time to wake up from its sleeping state.
class BackendWarmupService {
  static final BackendWarmupService _instance = BackendWarmupService._internal();
  factory BackendWarmupService() => _instance;
  BackendWarmupService._internal();

  Completer<bool>? _warmupCompleter;
  bool _isWarmedUp = false;

  bool get isWarmedUp => _isWarmedUp;

  /// Starts the warm-up request in the background. Safe to call multiple times.
  Future<bool> warmUp({Duration timeout = const Duration(seconds: 45)}) {
    if (_isWarmedUp) return Future.value(true);
    if (_warmupCompleter != null) return _warmupCompleter!.future;

    final completer = Completer<bool>();
    _warmupCompleter = completer;

    _executeWarmup(timeout).then((success) {
      _isWarmedUp = success;
      if (!completer.isCompleted) {
        completer.complete(success);
      }
    }).catchError((_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  Future<bool> _executeWarmup(Duration timeout) async {
    try {
      final uri = Uri.parse(ApiConstants.oauthDiscoveryUrl);
      final response = await http.get(uri).timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void reset() {
    _warmupCompleter = null;
    _isWarmedUp = false;
  }
}
