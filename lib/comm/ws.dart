import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'server_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  Function(String)? onMessageReceived;

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(ServerConfig.wsBaseUrl));

    print('Menghubungkan ke WebSocket...');

    _channel!.stream.listen(
      (message) {
        print('Dari server: $message');
        if (onMessageReceived != null) {
          onMessageReceived!(message);
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('Koneksi WebSocket ditutup');
      },
    );
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(
        jsonEncode({
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      print('Pesan terkirim: $message');
    } else {
      print('Gagal mengirim: WebSocket belum terhubung.');
    }
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    print('WebSocket diputuskan.');
  }
}
