import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttDemo {
  static const broker = 'broker.hivemq.com';
  static const port = 1883;
  static const temperatureTopic = 'iot/esp32/dht22/temperature';
  static const humidityTopic = 'iot/esp32/dht22/humidity';
  static const gasTopic = 'iot/esp32/gas';
  static const timeTopic = 'iot/esp32/rtc';
  static const alertTopic = 'iot/esp32/alert';
  static const statusTopic = 'iot/esp32/status';
  static const topics = [
    temperatureTopic,
    humidityTopic,
    gasTopic,
    timeTopic,
    alertTopic,
    statusTopic,
  ];

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect({
    required void Function(String topic, String message) onMessage,
    required void Function(String status) onStatus,
  }) async {
    if (isConnected) return;
    await disconnect();

    final client = MqttServerClient.withPort(
      broker,
      'rtc_lab_${DateTime.now().microsecondsSinceEpoch}',
      port,
    );
    _client = client;
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 10000;
    client.onConnected = () => onStatus('Terhubung ke $broker:$port');
    client.onDisconnected = () => onStatus('Koneksi MQTT terputus');

    try {
      final status = await client.connect();
      if (status?.state != MqttConnectionState.connected) {
        throw Exception(
          'Koneksi broker gagal: ${status?.state ?? 'status tidak tersedia'}',
        );
      }

      final updates = client.updates;
      if (updates == null) {
        throw StateError('Stream pesan MQTT tidak tersedia');
      }

      for (final topic in topics) {
        client.subscribe(topic, MqttQos.atMostOnce);
      }
      _updates = updates.listen((events) {
        for (final event in events) {
          final payload = event.payload;
          if (payload is! MqttPublishMessage) continue;
          final message = MqttPublishPayload.bytesToStringAsString(
            payload.payload.message,
          );
          onMessage(event.topic, message);
        }
      }, onError: (Object error) => onStatus('MQTT error: $error'));
      onStatus('Terhubung. Subscribe: ${topics.length} topic sensor ESP32');
    } catch (_) {
      client.disconnect();
      if (identical(_client, client)) _client = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _updates?.cancel();
    _updates = null;
    final client = _client;
    _client = null;
    client?.disconnect();
  }
}
