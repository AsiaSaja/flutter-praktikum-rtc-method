import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'comm/mqtt.dart';
import 'comm/polling.dart';
import 'comm/pusnotf.dart';
import 'comm/rest.dart';
import 'comm/sse.dart';
import 'comm/web_rtc.dart';
import 'comm/ws.dart';
import 'rtc_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (PushNotificationService.isSupported) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF176B87);
    return MaterialApp(
      title: 'RTC Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F6F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3F6F9),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE4EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE4EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
      ),
      home: const CommHomePage(),
    );
  }
}

class CommHomePage extends StatefulWidget {
  const CommHomePage({super.key});

  @override
  State<CommHomePage> createState() => _CommHomePageState();
}

class _CommHomePageState extends State<CommHomePage> {
  final _sseService = SSEService();
  final _pollingService = PollingService();
  final _wsService = WebSocketService();
  final _mqttDemo = MqttDemo();
  final _webRtcDemo = WebRtcMqttDemo();
  final _pushNotificationService = PushNotificationService();

  final _wsInputController = TextEditingController();
  final _rtcRoomController = TextEditingController();
  final _rtcMessageController = TextEditingController();

  String _log = 'Tekan tombol metode untuk memulai percobaan.';
  String _mqttStatus = 'Belum terhubung';
  String _mqttDeviceStatus = 'Menunggu status ESP32';
  String _mqttLastAlert = 'Belum ada alarm';
  String _mqttLastUpdated = 'Belum ada data';
  String? _mqttDeviceTime;
  double? _mqttTemperature;
  double? _mqttHumidity;
  int? _mqttGasAdc;
  String _rtcStatus = 'Belum terhubung';
  String _wsStatus = 'Belum terhubung';
  int _mqttMessagesReceived = 0;
  String _pushStatus = 'Belum diaktifkan';
  String? _pushToken;
  String _pushLastMessage = 'Belum ada notifikasi masuk';
  bool _pushInitializing = false;
  bool _mqttConnecting = false;
  bool _rtcConnecting = false;
  bool _rtcConnected = false;
  bool _restLoading = false;
  bool _pollingActive = false;
  bool _sseActive = false;
  bool _wsConnecting = false;

  Future<void> _testRestApi() async {
    setState(() => _restLoading = true);
    try {
      final data = await getData();
      _appendLog('REST GET /api/data berhasil: $data');
    } catch (error) {
      _appendLog('REST API error: $error');
    } finally {
      if (mounted) setState(() => _restLoading = false);
    }
  }

  void _startPolling() {
    _pollingService.startPolling(
      onData: (data) => _appendLog('Polling menerima data: $data'),
      onError: (error) => _appendLog('Polling error: $error'),
    );
    setState(() => _pollingActive = true);
    _appendLog('Polling dimulai (interval 2 detik).');
  }

  void _stopPolling() {
    _pollingService.stopPolling();
    setState(() => _pollingActive = false);
    _appendLog('Polling dihentikan.');
  }

  void _startSse() {
    _sseService.connect(
      onData: (response) {
        _appendLog(
          'SSE event ${response.event.isEmpty ? '(message)' : response.event}: '
          '${response.data ?? response.rawResponse}',
        );
      },
      onError: (error) => _appendLog('SSE error: $error'),
    );
    setState(() => _sseActive = true);
    _appendLog('Koneksi SSE dimulai.');
  }

  void _stopSse() {
    _sseService.disconnect();
    setState(() => _sseActive = false);
    _appendLog('Koneksi SSE dihentikan.');
  }

  void _connectWebSocket() {
    setState(() {
      _wsConnecting = true;
      _wsStatus = 'Menghubungkan...';
    });
    _wsService.onMessageReceived = (message) {
      if (!mounted) return;
      setState(() {
        _wsConnecting = false;
        _wsStatus = 'Menerima data';
      });
      _appendLog('Pesan WebSocket diterima: $message');
    };
    _wsService.connect();
  }

  Future<void> _disconnectWebSocket() async {
    await _wsService.disconnect();
    if (!mounted) return;
    setState(() {
      _wsConnecting = false;
      _wsStatus = 'Terputus';
    });
    _appendLog('WebSocket diputuskan.');
  }

  void _sendWebSocketMessage() {
    final message = _wsInputController.text.trim();
    if (message.isEmpty) return;
    _wsService.sendMessage(message);
    _appendLog('Pesan WebSocket dikirim: $message');
    _wsInputController.clear();
  }

  Future<void> _connectMqtt() async {
    setState(() {
      _mqttConnecting = true;
      _mqttStatus = 'Menghubungkan ke ${MqttDemo.broker}...';
    });
    try {
      await _mqttDemo.connect(
        onMessage: (topic, message) {
          if (!mounted) return;
          setState(() {
            final value = message.trim();
            switch (topic) {
              case MqttDemo.temperatureTopic:
                _mqttTemperature = double.tryParse(value);
              case MqttDemo.humidityTopic:
                _mqttHumidity = double.tryParse(value);
              case MqttDemo.gasTopic:
                _mqttGasAdc = int.tryParse(value);
              case MqttDemo.timeTopic:
                _mqttDeviceTime = value;
              case MqttDemo.statusTopic:
                _mqttDeviceStatus = value;
              case MqttDemo.alertTopic:
                _mqttLastAlert = value;
            }
            _mqttMessagesReceived++;
            _mqttLastUpdated = TimeOfDay.now().format(context);
          });
          if (topic == MqttDemo.alertTopic ||
              topic == MqttDemo.statusTopic) {
            _appendLog('MQTT masuk [$topic]: $message');
          }
        },
        onStatus: (status) {
          if (mounted) setState(() => _mqttStatus = status);
        },
      );
    } catch (error) {
      if (mounted) setState(() => _mqttStatus = 'Gagal terhubung: $error');
      _appendLog('MQTT error: $error');
    } finally {
      if (mounted) setState(() => _mqttConnecting = false);
    }
  }

  Future<void> _disconnectMqtt() async {
    await _mqttDemo.disconnect();
    if (mounted) setState(() => _mqttStatus = 'Koneksi MQTT dihentikan');
  }

  Future<void> _initializePushNotifications() async {
    setState(() {
      _pushInitializing = true;
      _pushStatus = 'Meminta izin notifikasi...';
    });
    try {
      final token = await _pushNotificationService.initialize(
        onMessage: (message) {
          if (!mounted) return;
          final title = message.notification?.title ?? 'Pesan data';
          final body = message.notification?.body ??
              (message.data.isEmpty ? 'Notifikasi diterima' : message.data);
          setState(() => _pushLastMessage = '$title: $body');
          _appendLog('Push notification masuk: $title — $body');
        },
      );
      if (!mounted) return;
      setState(() {
        _pushToken = token;
        _pushStatus = token == null
            ? 'Token tidak tersedia'
            : 'Siap menerima notifikasi';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _pushStatus = 'Gagal menyiapkan FCM: $error');
      _appendLog('Push notification error: $error');
    } finally {
      if (mounted) setState(() => _pushInitializing = false);
    }
  }

  Future<void> _startWebRtc({required bool isInitiator}) async {
    setState(() {
      _rtcConnecting = true;
      _rtcConnected = false;
      _rtcStatus = 'Menyiapkan signaling...';
    });
    try {
      await _webRtcDemo.connectToRoom(
        roomId: _rtcRoomController.text.trim(),
        isInitiator: isInitiator,
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _rtcStatus = status;
            _rtcConnected = _webRtcDemo.isDataChannelOpen;
          });
        },
        onMessage: (message) => _appendLog('WebRTC masuk: $message'),
      );
      if (isInitiator) await _webRtcDemo.createOffer();
    } catch (error) {
      if (mounted) {
        setState(() {
          _rtcStatus = 'WebRTC gagal: $error';
          _rtcConnected = false;
        });
      }
      _appendLog('WebRTC error: $error');
    } finally {
      if (mounted) setState(() => _rtcConnecting = false);
    }
  }

  Future<void> _disconnectWebRtc() async {
    await _webRtcDemo.disconnect();
    if (!mounted) return;
    setState(() {
      _rtcStatus = 'WebRTC dihentikan';
      _rtcConnected = false;
      _rtcConnecting = false;
    });
  }

  Future<void> _sendWebRtcMessage() async {
    final message = _rtcMessageController.text.trim();
    if (message.isEmpty) return;
    try {
      await _webRtcDemo.sendMessage(message);
      _appendLog('WebRTC keluar: $message');
      _rtcMessageController.clear();
    } catch (error) {
      if (mounted) setState(() => _rtcStatus = '$error');
      _appendLog('WebRTC error: $error');
    }
  }

  void _appendLog(String message) {
    if (!mounted) return;
    setState(() {
      final time = TimeOfDay.now().format(context);
      _log = '[$time] $message\n$_log';
      final lines = _log.split('\n');
      if (lines.length > 30) _log = lines.take(30).join('\n');
    });
  }

  @override
  void dispose() {
    _sseService.disconnect();
    _pollingService.stopPolling();
    _wsService.disconnect();
    unawaited(_mqttDemo.disconnect());
    unawaited(_webRtcDemo.disconnect());
    unawaited(_pushNotificationService.dispose());
    _wsInputController.dispose();
    _rtcRoomController.dispose();
    _rtcMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RtcDashboard(
      log: _log,
      mqttStatus: _mqttStatus,
      mqttConnecting: _mqttConnecting,
      mqttConnected: _mqttDemo.isConnected,
      mqttDeviceStatus: _mqttDeviceStatus,
      mqttTemperature: _mqttTemperature,
      mqttHumidity: _mqttHumidity,
      mqttGasAdc: _mqttGasAdc,
      mqttDeviceTime: _mqttDeviceTime,
      mqttLastAlert: _mqttLastAlert,
      mqttLastUpdated: _mqttLastUpdated,
      mqttMessagesReceived: _mqttMessagesReceived,
      pushStatus: _pushStatus,
      pushToken: _pushToken,
      pushLastMessage: _pushLastMessage,
      pushInitializing: _pushInitializing,
      pushSupported: PushNotificationService.isSupported,
      rtcStatus: _rtcStatus,
      rtcConnecting: _rtcConnecting,
      rtcConnected: _rtcConnected,
      rtcSignalingConnected: _webRtcDemo.isSignalingConnected,
      restLoading: _restLoading,
      pollingActive: _pollingActive,
      sseActive: _sseActive,
      wsConnecting: _wsConnecting,
      wsStatus: _wsStatus,
      wsController: _wsInputController,
      roomController: _rtcRoomController,
      rtcMessageController: _rtcMessageController,
      onRest: _testRestApi,
      onStartPolling: _startPolling,
      onStopPolling: _stopPolling,
      onStartSse: _startSse,
      onStopSse: _stopSse,
      onConnectWebSocket: _connectWebSocket,
      onDisconnectWebSocket: _disconnectWebSocket,
      onSendWebSocket: _sendWebSocketMessage,
      onConnectMqtt: _connectMqtt,
      onDisconnectMqtt: _disconnectMqtt,
      onInitializePushNotifications: _initializePushNotifications,
      onJoinRtc: () => _startWebRtc(isInitiator: false),
      onOfferRtc: () => _startWebRtc(isInitiator: true),
      onDisconnectRtc: _disconnectWebRtc,
      onSendRtc: _sendWebRtcMessage,
      onClearLog: () => setState(() => _log = ''),
    );
  }
}
