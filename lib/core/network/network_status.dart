import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class NetworkStatusNotifier extends AsyncNotifier<NetworkStatus> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  Future<NetworkStatus> build() async {
    final results = await Connectivity().checkConnectivity();
    _sub = Connectivity().onConnectivityChanged.listen(_onChanged);
    ref.onDispose(() => _sub?.cancel());
    return _toStatus(results);
  }

  void _onChanged(List<ConnectivityResult> results) {
    state = AsyncData(_toStatus(results));
  }

  static NetworkStatus _toStatus(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none)
          ? NetworkStatus.online
          : NetworkStatus.offline;
}

final networkStatusProvider =
    AsyncNotifierProvider<NetworkStatusNotifier, NetworkStatus>(
  NetworkStatusNotifier.new,
);

extension NetworkStatusRef on WidgetRef {
  bool get isOffline =>
      watch(networkStatusProvider).valueOrNull == NetworkStatus.offline;
}
