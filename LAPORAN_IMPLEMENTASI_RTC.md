# Laporan Implementasi Aplikasi RTC Lab

## 1. Pendahuluan

RTC Lab adalah aplikasi Flutter untuk mempelajari beberapa pola komunikasi
real-time melalui satu dashboard. Aplikasi menggabungkan metode berbasis
request/response, koneksi streaming, publish-subscribe, komunikasi peer-to-peer,
dan push notification.

Laporan ini merangkum implementasi yang tersedia di source code saat laporan
disusun. Status "dapat dicoba" tidak berarti semua metode telah diuji pada
setiap perangkat atau kondisi jaringan.

## 2. Ringkasan status implementasi

| No. | Metode | Status pada aplikasi |
|---:|---|---|
| 1 | REST API | Implementasi GET dan POST tersedia; dashboard menyediakan percobaan GET. |
| 2 | Polling | Dapat mengambil data REST berulang dengan interval dua detik. |
| 3 | Server-Sent Events (SSE) | Client menerima event dari endpoint streaming lokal. |
| 4 | WebSocket | Client dapat mengirim dan menerima pesan melalui server lokal. |
| 5 | MQTT | Dashboard subscribe ke enam topic telemetry ESP32/Wokwi melalui HiveMQ. |
| 6 | WebRTC DataChannel | Pertukaran pesan peer-to-peer dengan MQTT sebagai signaling. |
| 7 | gRPC | Belum diimplementasikan; masih ditampilkan sebagai metode tahap berikutnya. |
| 8 | Push Notification | Integrasi Firebase Cloud Messaging (FCM) dasar tersedia untuk Android; pengiriman uji end-to-end belum dikonfirmasi. |

## 3. Implementasi masing-masing metode

### 3.1 REST API

REST digunakan untuk mengambil data terakhir dari backend melalui HTTP GET.
Client juga menyediakan fungsi HTTP POST untuk mengirim pesan JSON.

Potongan penting dari `lib/comm/rest.dart`:

```dart
final response = await http.get(
  Uri.parse('${ServerConfig.httpBaseUrl}/api/data'),
);
```

Fungsi `getData()` memeriksa status HTTP dan mendekode body JSON sebagai
`Map<String, dynamic>`. Fungsi `sendMessage()` mengirim pesan dengan header
`Content-Type: application/json`. Referensi: [rest.dart, fungsi getData dan
sendMessage](lib/comm/rest.dart#L7).

Backend menyediakan endpoint `GET /api/data` dan `POST /api/message`.
Dashboard menjalankan permintaan GET untuk demonstrasi. Referensi: [server.js,
endpoint REST](server/server.js#L48).

### 3.2 Polling

Polling menjalankan permintaan REST berulang menggunakan `Timer.periodic`.
Interval default adalah dua detik. Hasil dan error diteruskan ke callback agar
dapat dicatat pada dashboard.

Potongan penting dari `lib/comm/polling.dart`:

```dart
_pollingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
  _,
) async {
  try {
    final data = await getData();
    onData?.call(data);
  } catch (e) {
    onError?.call(e);
  }
});
```

Timer dibatalkan melalui `stopPolling()` saat percobaan dihentikan. Referensi:
[polling.dart, startPolling dan stopPolling](lib/comm/polling.dart#L8).

### 3.3 Server-Sent Events (SSE)

SSE mempertahankan koneksi HTTP untuk menerima event dari server. Client
mengakses endpoint `/api/events`, meneruskan event dan error ke callback, serta
mengaktifkan opsi retry pada request.

Potongan penting dari `lib/comm/sse.dart`:

```dart
final request = SSERequest(
  requestType: RequestMethodType.get,
  url: '${ServerConfig.httpBaseUrl}/api/events',
  onData: (data) => onData?.call(data),
  retry: true,
);
```

Backend mengatur response bertipe `text/event-stream`, mengirim event
`connected`, lalu menulis pembaruan ketika data baru tersedia. Referensi:
[sse.dart, connect dan disconnect](lib/comm/sse.dart#L12), [server.js, endpoint
SSE](server/server.js#L65).

### 3.4 WebSocket

WebSocket menyediakan koneksi dua arah. Client membuka koneksi ke URL WebSocket,
mendengarkan stream pesan, dan mengirim pesan JSON yang berisi teks serta
timestamp. Backend membalas pesan sebagai echo.

Potongan penting dari `lib/comm/ws.dart`:

```dart
_channel = WebSocketChannel.connect(Uri.parse(ServerConfig.wsBaseUrl));
```

Pengiriman pesan dilakukan melalui sink channel:

```dart
_channel!.sink.add(jsonEncode({
  'message': message,
  'timestamp': DateTime.now().toIso8601String(),
}));
```

Referensi: [ws.dart, WebSocketService](lib/comm/ws.dart#L7), [server.js,
handler WebSocket](server/server.js#L80).

### 3.5 MQTT

Client MQTT menghubungkan aplikasi ke broker publik HiveMQ pada
`broker.hivemq.com:1883`, kemudian subscribe ke topic telemetry ESP32 berikut:

- `iot/esp32/dht22/temperature`
- `iot/esp32/dht22/humidity`
- `iot/esp32/gas`
- `iot/esp32/rtc`
- `iot/esp32/alert`
- `iot/esp32/status`

Potongan penting dari `lib/comm/mqtt.dart`:

```dart
for (final topic in topics) {
  client.subscribe(topic, MqttQos.atMostOnce);
}
```

Dashboard memparse suhu, kelembapan, dan nilai gas; waktu, status perangkat,
serta pesan alarm ditampilkan sebagai teks. Publisher telemetry-nya adalah
simulasi ESP32/Wokwi, yang mengirimkan data periodik. Referensi: [mqtt.dart,
daftar topic dan connect](lib/comm/mqtt.dart#L8), [main.dart, pemetaan pesan ke
state dashboard](lib/main.dart#L175), [README, topic MQTT dan ambang alarm](README.md#L33).

### 3.6 WebRTC DataChannel

WebRTC digunakan untuk mengirim pesan teks langsung antar-peer melalui
DataChannel. Untuk menemukan peer dan menukar informasi koneksi (signaling),
aplikasi memakai MQTT dan room topic
`rtc-lab/<room-id>/signaling`. Room ID divalidasi agar hanya terdiri dari huruf,
angka, tanda hubung, dan garis bawah.

Potongan penting dari `lib/comm/web_rtc.dart`:

```dart
final peerConnection = await createPeerConnection({
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
  ],
});
```

Host membuat offer, peer menjawab dengan answer, dan kedua sisi bertukar ICE
candidate melalui signaling. Setelah DataChannel terbuka, pesan dikirim melalui
channel tersebut. Referensi: [web_rtc.dart, connectToRoom, createOffer dan
sendMessage](lib/comm/web_rtc.dart#L32), [web_rtc.dart, signaling topic dan
PeerConnection](lib/comm/web_rtc.dart#L164).

Implementasi ini berfokus pada pesan teks DataChannel, bukan streaming audio
atau video.

### 3.7 gRPC

gRPC belum memiliki implementasi client/server dalam project saat ini.
Dashboard hanya menampilkan gRPC sebagai metode tahap berikutnya. Karena itu,
gRPC belum dapat digunakan untuk percobaan dan belum ada hasil pengujian
protokol ini yang dapat dilaporkan. Referensi status UI: [rtc_dashboard.dart,
kartu tahap berikutnya](lib/rtc_dashboard.dart#L868).

### 3.8 Push Notification (Firebase Cloud Messaging)

Push Notification memakai Firebase Core dan Firebase Messaging. Konfigurasi
platform dihasilkan oleh FlutterFire dan tersedia untuk Android dan Windows,
tetapi service aplikasi secara eksplisit membatasi aktivasi FCM ke Android.
Saat pengguna mengaktifkan fitur, aplikasi meminta izin notifikasi,
mendaftarkan listener untuk pesan foreground dan pesan yang membuka aplikasi,
serta mengambil registration token untuk pengujian melalui Firebase Console.

Potongan penting dari `lib/comm/pusnotf.dart`:

```dart
final settings = await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

Listener pesan aktif dan token diambil setelah inisialisasi. Referensi:
[pusnotf.dart, PushNotificationService](lib/comm/pusnotf.dart#L14), [main.dart,
registrasi background handler dan aktivasi layanan](lib/main.dart#L13).

Pesan foreground ditampilkan di kartu dashboard dan log aplikasi. Notifikasi
yang diterima ketika aplikasi berada di latar bergantung pada konfigurasi dan
perilaku Android/FCM. Pengiriman uji dari Firebase Console belum dianggap
terverifikasi sampai berhasil dicoba pada perangkat.

## 4. Konfigurasi backend lokal

REST, Polling, SSE, dan WebSocket menggunakan backend lokal. Host ditentukan
oleh `SERVER_IP` dan secara default bernilai `192.168.1.74`; HTTP dan WebSocket
menggunakan port `3000`.

Potongan penting dari `lib/comm/server_config.dart`:

```dart
static const String _serverHost = String.fromEnvironment(
  'SERVER_IP',
  defaultValue: '192.168.1.74',
);
```

Referensi: [server_config.dart](lib/comm/server_config.dart#L1). Backend
mengirim data simulasi baru setiap dua detik dan mendistribusikannya ke
endpoint REST, koneksi SSE, dan client WebSocket. Server mendengarkan pada
`0.0.0.0:3000`. Referensi: [server.js, simulasi dan server listener](server/server.js#L18).

Untuk akses dari perangkat lain, server harus berjalan dan IP host harus dapat
dijangkau dari jaringan perangkat. Nilai `SERVER_IP` dapat diubah saat
menjalankan Flutter melalui `--dart-define=SERVER_IP=<IP-komputer>`.

## 5. Kendala selama pengembangan dan pengujian

1. **Ketergantungan pada backend dan jaringan lokal.** REST, Polling, SSE, dan
   WebSocket memerlukan backend aktif pada port `3000`. Perangkat uji harus
   dapat menjangkau IP komputer server; firewall, alamat IP yang berubah, atau
   perangkat pada jaringan berbeda dapat menghambat pengujian.
2. **Keterbatasan broker MQTT publik.** MQTT memakai HiveMQ publik tanpa
   autentikasi pada konfigurasi praktikum ini. Koneksi internet diperlukan,
   topic dapat diakses pihak lain, dan data sensitif tidak boleh dipublikasikan.
3. **Keterbatasan konektivitas WebRTC.** WebRTC bergantung pada signaling MQTT,
   STUN publik, dan konektivitas antar-peer. Sebagian konfigurasi NAT/firewall
   dapat memerlukan TURN; server TURN belum dikonfigurasi. Untuk demonstrasi,
   dibutuhkan dua peer dengan room ID yang sama.
4. **Setup FlutterFire dan Firebase.** Perintah `flutterfire` awalnya tidak
   tersedia sampai FlutterFire CLI dipasang. Proses konfigurasi juga menemui
   kegagalan Ruby `cannot load such file -- xcodeproj` ketika memproses platform
   Apple. Konfigurasi yang ada tidak berarti dukungan FCM semua platform telah
   selesai; implementasi push saat ini hanya mengaktifkan Android.
5. **Pengujian end-to-end Push Notification.** Pengujian memerlukan perangkat
   Android, izin notifikasi, registration token, koneksi Firebase, serta pesan
   uji yang dikirim dari Firebase Console. Alur konfigurasi dan build sudah
   disiapkan, tetapi keberhasilan pengiriman nyata belum dikonfirmasi.
6. **gRPC belum dikembangkan.** Metode ini masih menjadi placeholder sehingga
   belum ada komunikasi gRPC untuk diuji atau dibandingkan.
7. **Cakupan WebRTC terbatas.** Implementasi saat ini menguji pesan teks melalui
   DataChannel; fitur media audio/video belum menjadi bagian aplikasi.

## 6. Kesimpulan

RTC Lab telah menyediakan satu dashboard untuk mencoba REST API, Polling, SSE,
WebSocket, MQTT telemetry ESP32, WebRTC DataChannel, dan integrasi dasar Push
Notification berbasis FCM untuk Android. Implementasi backend lokal memberi
data simulasi untuk REST, Polling, SSE, dan WebSocket; MQTT menampilkan
telemetry yang diterbitkan ESP32/Wokwi; WebRTC memakai MQTT sebagai signaling
dan STUN untuk membantu pembentukan koneksi peer.

Pengujian yang dilakukan pada lingkungan lokal dan perangkat yang tersedia
memiliki keterbatasan jaringan serta ketergantungan layanan eksternal. Oleh
karena itu, belum semua metode dapat divalidasi end-to-end dalam seluruh
kondisi. Secara khusus, gRPC belum diimplementasikan dan pengiriman push FCM
nyata masih perlu diuji. Pengembangan berikutnya dapat mencakup implementasi
gRPC, pengujian FCM pada perangkat Android, konfigurasi TURN untuk jaringan
yang membutuhkannya, serta pengujian konektivitas pada lingkungan server dan
jaringan yang sesuai.
