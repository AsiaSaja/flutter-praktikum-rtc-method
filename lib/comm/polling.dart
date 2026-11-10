import 'dart:async';

import 'rest.dart';

class PollingService {
  Timer? _pollingTimer;

  void startPolling({
    int intervalSeconds = 2,
    void Function(Map<String, dynamic> data)? onData,
    void Function(Object error)? onError,
  }) {
    _pollingTimer?.cancel();

    print('Memulai Polling setiap $intervalSeconds detik...');

    _pollingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
      _,
    ) async {
      try {
        final data = await getData();
        print('Polling Data: $data');
        onData?.call(data);
      } catch (e) {
        print('Polling error: $e');
        onError?.call(e);
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('Polling dihentikan');
  }
}
