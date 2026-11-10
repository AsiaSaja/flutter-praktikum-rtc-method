import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt.dart';

class WebRtcMqttDemo {
  MqttServerClient? _signalingClient;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _signalingUpdates;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final List<RTCIceCandidate> _pendingCandidates = [];
  Future<void> _signalQueue = Future<void>.value();
  String? _roomId;
  late final String _peerId = 'peer_${DateTime.now().microsecondsSinceEpoch}';
  bool _isInitiator = false;
  bool _hasRemoteDescription = false;
  bool _closed = false;
  void Function(String status)? _onStatus;
  void Function(String message)? _onMessage;

  bool get isSignalingConnected =>
      _signalingClient?.connectionStatus?.state ==
      MqttConnectionState.connected;

  bool get isDataChannelOpen =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  Future<void> connectToRoom({
    required String roomId,
    required bool isInitiator,
    required void Function(String status) onStatus,
    required void Function(String message) onMessage,
  }) async {
    final normalizedRoomId = roomId.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{3,48}$').hasMatch(normalizedRoomId)) {
      throw ArgumentError(
        'Room ID harus 3–48 karakter: huruf, angka, "-" atau "_".',
      );
    }

    await disconnect();
    _closed = false;
    _roomId = normalizedRoomId;
    _isInitiator = isInitiator;
    _onStatus = onStatus;
    _onMessage = onMessage;
    _setStatus('Menghubungkan signaling ke ${MqttDemo.broker}...');

    final client = MqttServerClient.withPort(
      MqttDemo.broker,
      'webrtc_$_peerId',
      MqttDemo.port,
    );
    _signalingClient = client;
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 10000;
    client.onDisconnected = () {
      if (!_closed) _setStatus('Koneksi MQTT signaling terputus');
    };

    try {
      final status = await client.connect();
      if (status?.state != MqttConnectionState.connected) {
        throw StateError(
          'Gagal terhubung ke broker signaling: '
          '${status?.state ?? 'status tidak tersedia'}',
        );
      }

      final updates = client.updates;
      if (updates == null) {
        throw StateError('Stream signaling MQTT tidak tersedia');
      }

      final topic = _signalTopic;
      client.subscribe(topic, MqttQos.atMostOnce);
      _signalingUpdates = updates.listen(
        (events) {
          for (final event in events) {
            if (event.topic != topic || event.payload is! MqttPublishMessage) {
              continue;
            }
            final payload = event.payload as MqttPublishMessage;
            final message = MqttPublishPayload.bytesToStringAsString(
              payload.payload.message,
            );
            _signalQueue = _signalQueue
                .then((_) => _handleSignal(message))
                .catchError((Object error) {
                  if (!_closed) {
                    _setStatus('Gagal memproses signaling: $error');
                  }
                });
          }
        },
        onError: (Object error) {
          if (!_closed) _setStatus('MQTT signaling error: $error');
        },
      );
      _setStatus(
        isInitiator
            ? 'Signaling siap. Membuat koneksi sebagai host...'
            : 'Bergabung ke room. Menunggu offer dari host...',
      );
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  Future<void> createOffer() async {
    if (!isSignalingConnected || !_isInitiator) {
      throw StateError('Hubungkan sebagai host sebelum membuat offer');
    }

    final peerConnection = await _ensurePeerConnection();
    final channel = await peerConnection.createDataChannel(
      'rtc-chat',
      RTCDataChannelInit(),
    );
    _attachDataChannel(channel);

    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    await _publishSignal({'type': 'offer', 'from': _peerId, 'sdp': offer.sdp});
    _setStatus('Offer dikirim. Menunggu peer menjawab...');
  }

  Future<void> sendMessage(String message) async {
    final channel = _dataChannel;
    if (channel == null || !isDataChannelOpen) {
      throw StateError('DataChannel belum terbuka');
    }
    await channel.send(RTCDataChannelMessage(message));
  }

  Future<void> disconnect() async {
    _closed = true;
    await _signalingUpdates?.cancel();
    _signalingUpdates = null;
    _signalingClient?.disconnect();
    _signalingClient = null;

    final channel = _dataChannel;
    _dataChannel = null;
    await channel?.close();

    final peerConnection = _peerConnection;
    _peerConnection = null;
    _hasRemoteDescription = false;
    _signalQueue = Future<void>.value();
    _pendingCandidates.clear();
    if (peerConnection != null) {
      await peerConnection.close();
      await peerConnection.dispose();
    }
  }

  String get _signalTopic => 'rtc-lab/$_roomId/signaling';

  Future<RTCPeerConnection> _ensurePeerConnection() async {
    final current = _peerConnection;
    if (current != null) return current;

    final peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });
    _peerConnection = peerConnection;

    peerConnection.onIceCandidate = (candidate) {
      if (candidate.candidate == null || _closed) return;
      unawaited(_publishCandidate(candidate));
    };
    peerConnection.onConnectionState = (state) {
      if (!_closed) _setStatus('WebRTC: $state');
    };
    peerConnection.onIceConnectionState = (state) {
      if (!_closed) _setStatus('ICE: $state');
    };
    peerConnection.onDataChannel = _attachDataChannel;

    return peerConnection;
  }

  Future<void> _publishCandidate(RTCIceCandidate candidate) async {
    try {
      await _publishSignal({
        'type': 'candidate',
        'from': _peerId,
        'candidate': candidate.toMap(),
      });
    } catch (error) {
      if (!_closed) _setStatus('Gagal mengirim ICE candidate: $error');
    }
  }

  void _attachDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    channel.onDataChannelState = (state) {
      if (_closed) return;
      _setStatus('DataChannel: $state');
    };
    channel.onMessage = (message) {
      if (_closed) return;
      _onMessage?.call(message.isBinary ? '[pesan biner]' : message.text);
    };
  }

  Future<void> _handleSignal(String payload) async {
    if (_closed) return;

    late final Map<String, dynamic> signal;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Payload signaling harus berupa object');
      }
      signal = decoded;
    } on FormatException catch (error) {
      _setStatus('Payload signaling tidak valid: ${error.message}');
      return;
    }

    if (signal['from'] == _peerId) return;

    try {
      switch (signal['type']) {
        case 'offer':
          await _handleOffer(signal);
        case 'answer':
          await _handleAnswer(signal);
        case 'candidate':
          await _handleCandidate(signal);
        default:
          _setStatus('Jenis pesan signaling tidak dikenali');
      }
    } catch (error) {
      if (!_closed) _setStatus('Gagal memproses signaling: $error');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> signal) async {
    if (_isInitiator) return;
    final sdp = signal['sdp'];
    if (sdp is! String || sdp.isEmpty) {
      throw const FormatException('Offer SDP kosong atau tidak valid');
    }

    final peerConnection = await _ensurePeerConnection();
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    );
    _hasRemoteDescription = true;
    await _flushCandidates(peerConnection);

    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    await _publishSignal({
      'type': 'answer',
      'from': _peerId,
      'sdp': answer.sdp,
    });
    _setStatus('Answer dikirim. Menunggu koneksi peer...');
  }

  Future<void> _handleAnswer(Map<String, dynamic> signal) async {
    if (!_isInitiator) return;
    final sdp = signal['sdp'];
    if (sdp is! String || sdp.isEmpty) {
      throw const FormatException('Answer SDP kosong atau tidak valid');
    }

    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      throw StateError('Menerima answer sebelum offer dibuat');
    }
    await peerConnection.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
    _hasRemoteDescription = true;
    await _flushCandidates(peerConnection);
    _setStatus('Answer diterima. Menegosiasikan koneksi peer...');
  }

  Future<void> _handleCandidate(Map<String, dynamic> signal) async {
    final rawCandidate = signal['candidate'];
    if (rawCandidate is! Map<String, dynamic>) {
      throw const FormatException('ICE candidate tidak valid');
    }

    final candidate = RTCIceCandidate(
      rawCandidate['candidate'] as String?,
      rawCandidate['sdpMid'] as String?,
      (rawCandidate['sdpMLineIndex'] as num?)?.toInt(),
    );
    final peerConnection = await _ensurePeerConnection();
    if (!_hasRemoteDescription) {
      _pendingCandidates.add(candidate);
      return;
    }
    await peerConnection.addCandidate(candidate);
  }

  Future<void> _flushCandidates(RTCPeerConnection peerConnection) async {
    final pending = List<RTCIceCandidate>.of(_pendingCandidates);
    _pendingCandidates.clear();
    for (final candidate in pending) {
      await peerConnection.addCandidate(candidate);
    }
  }

  Future<void> _publishSignal(Map<String, dynamic> signal) async {
    final client = _signalingClient;
    if (client == null ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      throw StateError('MQTT signaling tidak terhubung');
    }

    final builder = MqttClientPayloadBuilder()
      ..addString(jsonEncode({...signal, 'room': _roomId}));
    final payload = builder.payload;
    if (payload == null) {
      throw StateError('Gagal membuat payload signaling');
    }
    client.publishMessage(_signalTopic, MqttQos.atMostOnce, payload);
  }

  void _setStatus(String status) {
    if (!_closed) _onStatus?.call(status);
  }
}
