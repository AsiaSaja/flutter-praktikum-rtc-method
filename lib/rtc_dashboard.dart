import 'package:flutter/material.dart';

import 'comm/mqtt.dart';

class RtcDashboard extends StatelessWidget {
  const RtcDashboard({
    required this.log,
    required this.mqttStatus,
    required this.mqttConnecting,
    required this.mqttConnected,
    required this.mqttDeviceStatus,
    required this.mqttTemperature,
    required this.mqttHumidity,
    required this.mqttGasAdc,
    required this.mqttDeviceTime,
    required this.mqttLastAlert,
    required this.mqttLastUpdated,
    required this.mqttMessagesReceived,
    required this.pushStatus,
    required this.pushToken,
    required this.pushLastMessage,
    required this.pushInitializing,
    required this.pushSupported,
    required this.rtcStatus,
    required this.rtcConnecting,
    required this.rtcConnected,
    required this.rtcSignalingConnected,
    required this.restLoading,
    required this.pollingActive,
    required this.sseActive,
    required this.wsConnecting,
    required this.wsStatus,
    required this.wsController,
    required this.roomController,
    required this.rtcMessageController,
    required this.onRest,
    required this.onStartPolling,
    required this.onStopPolling,
    required this.onStartSse,
    required this.onStopSse,
    required this.onConnectWebSocket,
    required this.onDisconnectWebSocket,
    required this.onSendWebSocket,
    required this.onConnectMqtt,
    required this.onDisconnectMqtt,
    required this.onInitializePushNotifications,
    required this.onJoinRtc,
    required this.onOfferRtc,
    required this.onDisconnectRtc,
    required this.onSendRtc,
    required this.onClearLog,
    super.key,
  });

  final String log;
  final String mqttStatus;
  final bool mqttConnecting;
  final bool mqttConnected;
  final String mqttDeviceStatus;
  final double? mqttTemperature;
  final double? mqttHumidity;
  final int? mqttGasAdc;
  final String? mqttDeviceTime;
  final String mqttLastAlert;
  final String mqttLastUpdated;
  final int mqttMessagesReceived;
  final String pushStatus;
  final String? pushToken;
  final String pushLastMessage;
  final bool pushInitializing;
  final bool pushSupported;
  final String rtcStatus;
  final bool rtcConnecting;
  final bool rtcConnected;
  final bool rtcSignalingConnected;
  final bool restLoading;
  final bool pollingActive;
  final bool sseActive;
  final bool wsConnecting;
  final String wsStatus;
  final TextEditingController wsController;
  final TextEditingController roomController;
  final TextEditingController rtcMessageController;
  final VoidCallback onRest;
  final VoidCallback onStartPolling;
  final VoidCallback onStopPolling;
  final VoidCallback onStartSse;
  final VoidCallback onStopSse;
  final VoidCallback onConnectWebSocket;
  final VoidCallback onDisconnectWebSocket;
  final VoidCallback onSendWebSocket;
  final VoidCallback onConnectMqtt;
  final VoidCallback onDisconnectMqtt;
  final VoidCallback onInitializePushNotifications;
  final VoidCallback onJoinRtc;
  final VoidCallback onOfferRtc;
  final VoidCallback onDisconnectRtc;
  final VoidCallback onSendRtc;
  final VoidCallback onClearLog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RTC Lab',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  Text(
                    'Praktikum komunikasi real-time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 700 ? 32.0 : 18.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              32,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(context),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      context,
                      'Metode praktikum',
                      'Pilih dan jalankan metode komunikasi untuk mengamati perilakunya.',
                    ),
                    const SizedBox(height: 14),
                    _buildRestCard(context),
                    _buildPollingCard(),
                    _buildSseCard(),
                    _buildWebSocketCard(),
                    _buildMqttCard(),
                    _buildWebRtcCard(),
                    _buildPushNotificationCard(),
                    const SizedBox(height: 8),
                    _buildSectionTitle(
                      context,
                      'Tahap berikutnya',
                      'Metode ditampilkan untuk melengkapi ringkasan praktikum.',
                    ),
                    const SizedBox(height: 14),
                    _buildComingSoonCards(context),
                    const SizedBox(height: 28),
                    _buildLogCard(),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'RTC Lab • Realtime Communication',
                        style: TextStyle(
                          color: Color(0xFF7B8995),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF155E75), Color(0xFF176B87), Color(0xFF2585A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B87).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PRAKTIKUM • REALTIME COMMUNICATION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Eksplorasi metode komunikasi',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            'Bandingkan cara aplikasi bertukar data — mulai dari request sederhana hingga komunikasi peer-to-peer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroStat('6', 'dapat dicoba'),
              _buildHeroStat('2', 'tahap berikutnya'),
              _buildHeroStat('1', 'dashboard'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required int number,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String status,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E9EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$number. $title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status, color),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRestCard(BuildContext context) => _buildMethodCard(
    number: 1,
    icon: Icons.http_rounded,
    color: const Color(0xFF176B87),
    title: 'REST API',
    subtitle: 'Request-response melalui HTTP • GET /api/data',
    status: restLoading ? 'MEMINTA DATA' : 'SIAP DICOBA',
    child: Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: onRest,
        icon: restLoading
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_rounded),
        label: const Text('Ambil data'),
      ),
    ),
  );

  Widget _buildPollingCard() => _buildMethodCard(
    number: 2,
    icon: Icons.sync_rounded,
    color: const Color(0xFFB36B16),
    title: 'Polling',
    subtitle: 'Client meminta data ke server dengan interval berkala • 2 detik',
    status: pollingActive ? 'BERJALAN' : 'SIAP DICOBA',
    child: Wrap(
      spacing: 9,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: pollingActive ? null : onStartPolling,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Mulai polling'),
        ),
        OutlinedButton.icon(
          onPressed: pollingActive ? onStopPolling : null,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Hentikan'),
        ),
      ],
    ),
  );

  Widget _buildSseCard() => _buildMethodCard(
    number: 3,
    icon: Icons.event_note_rounded,
    color: const Color(0xFF27845A),
    title: 'Server-Sent Events',
    subtitle: 'Stream event satu arah dari server ke client melalui HTTP',
    status: sseActive ? 'AKTIF' : 'SIAP DICOBA',
    child: Wrap(
      spacing: 9,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: sseActive ? null : onStartSse,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Hubungkan SSE'),
        ),
        OutlinedButton.icon(
          onPressed: sseActive ? onStopSse : null,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Putuskan'),
        ),
      ],
    ),
  );

  Widget _buildWebSocketCard() => _buildMethodCard(
    number: 4,
    icon: Icons.swap_horiz_rounded,
    color: const Color(0xFF7652A5),
    title: 'WebSocket',
    subtitle: 'Koneksi dua arah yang tetap terbuka • real-time',
    status: wsStatus.toUpperCase(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: wsConnecting ? null : onConnectWebSocket,
              icon: const Icon(Icons.wifi_rounded),
              label: const Text('Hubungkan'),
            ),
            OutlinedButton.icon(
              onPressed: _wsIsInactive ? null : onDisconnectWebSocket,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Putuskan'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: wsController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendWebSocket(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan untuk server',
                  prefixIcon: Icon(Icons.edit_outlined),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              onPressed: _wsIsInactive ? null : onSendWebSocket,
              tooltip: 'Kirim pesan WebSocket',
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
    ),
  );

  bool get _wsIsInactive =>
      wsStatus == 'Terputus' || wsStatus == 'Belum terhubung';

  Widget _buildMqttCard() => _buildMethodCard(
    number: 5,
    icon: Icons.hub_rounded,
    color: const Color(0xFF16818B),
    title: 'MQTT',
    subtitle: 'Publish-subscribe • ${MqttDemo.broker}:${MqttDemo.port}',
    status: mqttConnecting
        ? 'MENGHUBUNGKAN'
        : mqttConnected
        ? 'TERHUBUNG'
        : 'SIAP DICOBA',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailLine('Perangkat ESP32', mqttDeviceStatus),
        const SizedBox(height: 8),
        _buildDetailLine('Status', mqttStatus),
        const SizedBox(height: 8),
        _buildDetailLine(
          'Data terakhir',
          '$mqttLastUpdated • $mqttMessagesReceived pesan diterima',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: mqttConnecting ? null : onConnectMqtt,
              icon: mqttConnecting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_rounded),
              label: const Text('Connect & subscribe'),
            ),
            OutlinedButton.icon(
              onPressed: mqttConnecting || !mqttConnected
                  ? null
                  : onDisconnectMqtt,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Putuskan'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Telemetry ESP32',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _buildMqttReading('Suhu', mqttTemperature, '°C', decimals: 2),
            _buildMqttReading('Kelembapan', mqttHumidity, '%', decimals: 2),
            _buildMqttReading('Gas (MQ-2)', mqttGasAdc, 'ADC', decimals: 0),
            _buildMqttReading('Waktu perangkat', mqttDeviceTime, ''),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailLine('Alarm terakhir', mqttLastAlert),
        const SizedBox(height: 9),
        const Text(
          'Ambang alarm ESP32: suhu ≥ 35°C dan gas ≥ 2000 ADC. '
          'Peringatan gas ≥ 1500 ADC hanya tampil di Serial Monitor.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 9),
        const Text(
          'Topic: iot/esp32/dht22/temperature, iot/esp32/dht22/humidity, '
          'iot/esp32/gas, iot/esp32/rtc, iot/esp32/alert, dan '
          'iot/esp32/status. Broker/topic bersifat publik.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
        ),
      ],
    ),
  );

  Widget _buildMqttReading(
    String label,
    Object? rawValue,
    String unit, {
    int? decimals,
  }) {
    final number = rawValue is num ? rawValue : null;
    final displayValue = number == null
        ? (rawValue == null || rawValue.toString().isEmpty
              ? '—'
              : rawValue.toString())
        : decimals == 0
        ? number.toInt().toString()
        : number.toStringAsFixed(decimals ?? 2);

    return Container(
      width: 145,
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E9ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 5),
          Text(
            unit.isEmpty ? displayValue : '$displayValue $unit',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildWebRtcCard() => _buildMethodCard(
    number: 6,
    icon: Icons.device_hub_rounded,
    color: const Color(0xFFB14D71),
    title: 'WebRTC DataChannel',
    subtitle: 'Komunikasi peer-to-peer dengan MQTT untuk signaling',
    status: rtcConnecting
        ? 'MENGHUBUNGKAN'
        : rtcConnected
        ? 'TERHUBUNG'
        : 'SIAP DICOBA',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buka aplikasi di dua perangkat. Peer bergabung terlebih dahulu, '
          'lalu host membuat offer. Keduanya memakai room ID yang sama.',
          style: TextStyle(
            color: Color(0xFF526171),
            height: 1.45,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: roomController,
          enabled: !rtcConnecting && !rtcSignalingConnected,
          decoration: const InputDecoration(
            labelText: 'Room ID',
            hintText: 'contoh: rtc-kelompok-7',
            prefixIcon: Icon(Icons.meeting_room_outlined),
            isDense: true,
          ),
        ),
        const SizedBox(height: 9),
        _buildDetailLine('Status', rtcStatus),
        const SizedBox(height: 13),
        Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: rtcConnecting || rtcIsConnected ? null : onJoinRtc,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Join sebagai peer'),
            ),
            FilledButton.tonalIcon(
              onPressed: rtcConnecting || rtcIsConnected ? null : onOfferRtc,
              icon: const Icon(Icons.call_made_rounded),
              label: const Text('Buat offer (host)'),
            ),
            OutlinedButton.icon(
              onPressed: rtcIsConnected || rtcConnecting
                  ? onDisconnectRtc
                  : null,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Putuskan'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: rtcMessageController,
                enabled: rtcConnected,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendRtc(),
                decoration: const InputDecoration(
                  labelText: 'Pesan peer-to-peer',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              onPressed: rtcConnected ? onSendRtc : null,
              tooltip: 'Kirim pesan WebRTC',
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'Signaling memakai broker/topic publik. Gunakan room ID unik dan '
          'hindari pesan sensitif. Jaringan tertentu mungkin memerlukan TURN.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
        ),
      ],
    ),
  );

  Widget _buildPushNotificationCard() => _buildMethodCard(
    number: 8,
    icon: Icons.notifications_active_outlined,
    color: const Color(0xFF8A5BB5),
    title: 'Push Notification',
    subtitle: 'Firebase Cloud Messaging • Android',
    status: !pushSupported
        ? 'ANDROID SAJA'
        : pushInitializing
        ? 'MENYIAPKAN'
        : pushToken != null
        ? 'SIAP'
        : 'BELUM AKTIF',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailLine('Status', pushStatus),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: !pushSupported || pushInitializing
              ? null
              : onInitializePushNotifications,
          icon: pushInitializing
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications_active_outlined),
          label: const Text('Aktifkan & minta izin'),
        ),
        const SizedBox(height: 12),
        _buildDetailLine('Notifikasi', pushLastMessage),
        if (pushToken != null) ...[
          const SizedBox(height: 12),
          const Text(
            'FCM token untuk uji kirim dari Firebase Console',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            pushToken!,
            style: const TextStyle(
              color: Color(0xFF263746),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 9),
        Text(
          pushSupported
              ? 'Untuk tes, gunakan Firebase Console → Messaging dan kirim '
                    'notifikasi ke token perangkat ini. Saat aplikasi terbuka, '
                    'pesan akan tampil di sini; saat di latar, Android '
                    'menampilkan notifikasi.'
              : 'FCM saat ini hanya diaktifkan untuk Android. Jalankan aplikasi '
                    'di perangkat Android untuk meminta izin dan menerima '
                    'notifikasi.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  bool get rtcIsConnected => rtcSignalingConnected || rtcConnected;

  Widget _buildDetailLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color: Color(0xFF263746),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildComingSoonCard(
              width: cardWidth,
              number: 7,
              title: 'gRPC',
              subtitle: 'RPC dengan Protocol Buffers',
              icon: Icons.account_tree_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildComingSoonCard({
    required double width,
    required int number,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFFF9FAFB),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E9EF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF768493), size: 20),
                  const Spacer(),
                  _buildStatusBadge('SEGERA', const Color(0xFF768493)),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '$number. $title',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF13212D),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  color: Color(0xFF8FD3C7),
                  size: 20,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Log percobaan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: log.isEmpty ? null : onClearLog,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB8C6D1),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: const Text('Bersihkan'),
                ),
              ],
            ),
            const Divider(color: Color(0xFF31414E), height: 18),
            Container(
              constraints: const BoxConstraints(minHeight: 110, maxHeight: 230),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1922),
                borderRadius: BorderRadius.circular(13),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  log.isEmpty
                      ? 'Log kosong. Jalankan metode untuk melihat aktivitas.'
                      : log,
                  style: const TextStyle(
                    color: Color(0xFFB8E8D0),
                    fontSize: 12,
                    height: 1.55,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
