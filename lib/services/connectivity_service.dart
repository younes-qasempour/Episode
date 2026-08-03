import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final SyncService _syncService;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;

  ConnectivityService({
    Connectivity? connectivity,
    required SyncService syncService,
  })  : _connectivity = connectivity ?? Connectivity(),
        _syncService = syncService;

  void startListening({String? boundUserId}) {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        triggerDebouncedSync(boundUserId: boundUserId);
      }
    });
  }

  void triggerDebouncedSync({
    String? boundUserId,
    Duration duration = const Duration(seconds: 3),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      _syncService.syncNow(boundUserId: boundUserId);
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    _subscription = null;
    _debounceTimer = null;
  }
}
