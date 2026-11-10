# RTC Lab

Aplikasi Flutter untuk mencoba metode komunikasi real-time dari satu dashboard.
Pilih metode di menu; koneksi atau timer metode aktif dihentikan ketika metode
lain dipilih.

## Metode

Siap dicoba:

- WebSocket
- REST API
- Polling
- Server-Sent Events (SSE)
- MQTT telemetry ESP32 dengan broker publik HiveMQ
  (`broker.hivemq.com:1883`)
- WebRTC DataChannel dengan MQTT sebagai signaling
- Push Notification menggunakan Firebase Cloud Messaging (Android)

Ditampilkan sebagai tahap pengembangan berikutnya:

- gRPC

## Menguji Push Notification

Firebase dikonfigurasi untuk Android dan Windows, tetapi penerimaan FCM pada
aplikasi saat ini diaktifkan untuk Android. Jalankan aplikasi pada perangkat
Android, pilih **Aktifkan & minta izin**, lalu salin FCM token yang tampil.
Kirim pesan uji ke token tersebut dari Firebase Console → Messaging. Pesan
foreground ditampilkan di kartu Push Notification dan log; notifikasi yang
diterima saat aplikasi di latar ditampilkan oleh Android.

MQTT menerima data sensor ESP32/Wokwi dari topic:

- `iot/esp32/dht22/temperature` — suhu dalam °C
- `iot/esp32/dht22/humidity` — kelembapan dalam persen
- `iot/esp32/gas` — nilai ADC sensor gas
- `iot/esp32/rtc` — timestamp perangkat atau uptime
- `iot/esp32/alert` — perubahan status alarm
- `iot/esp32/status` — status perangkat (`online`)

Hubungkan ESP32/Wokwi dan aplikasi ke broker publik HiveMQ yang sama. Aplikasi
menampilkan data yang diterima; pengiriman telemetry dilakukan ESP32 setiap
tiga detik. Ambang alarm pada contoh ESP32 adalah suhu 35°C dan gas ADC 2000;
peringatan gas ADC 1500 hanya ditulis ke Serial Monitor. Broker dan topic
bersifat publik, sehingga jangan kirim informasi pribadi atau rahasia.
Signaling WebRTC memakai topic publik
`rtc-lab/<room-id>/signaling`; gunakan room ID yang unik dan jangan gunakan
room ini untuk pertukaran informasi rahasia.

Untuk menguji WebRTC, buka aplikasi pada dua perangkat. Masukkan room ID yang
sama di keduanya, pilih **Join room** pada satu perangkat terlebih dahulu,
kemudian pilih **Buat offer (host)** pada perangkat lainnya. Setelah DataChannel
terhubung, kirim pesan melalui kolom WebRTC. Implementasi memakai STUN publik;
beberapa jaringan/NAT mungkin membutuhkan server TURN agar peer dapat
terhubung.

## Menjalankan server dan aplikasi

Jalankan server lokal:

```sh
cd server
npm start
```

Di terminal lain, jalankan aplikasi Flutter:

```sh
flutter pub get
flutter run
```

Server lokal pada port `3000` menyediakan REST, WebSocket, dan SSE. MQTT
terhubung langsung ke broker publik dan tidak memerlukan server lokal ini.
Konfigurasi REST, WebSocket, dan SSE kembali memakai HTTP/WS lokal dengan
default `192.168.1.74:3000`. Jika alamat komputer server berbeda, ubah
`SERVER_IP` di `lib/comm/server_config.dart` atau jalankan dengan
`flutter run --dart-define=SERVER_IP=<IP-komputer>`. Pastikan ponsel dan
komputer berada di jaringan yang sama.

Aplikasi menampilkan status koneksi serta log pesan/event untuk membantu
mengamati hasil percobaan.
