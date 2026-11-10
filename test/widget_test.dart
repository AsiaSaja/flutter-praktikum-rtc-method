import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:realtime_communication/comm/web_rtc.dart';
import 'package:realtime_communication/main.dart';

void main() {
  testWidgets('MQTT telemetry dashboard is shown before connecting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('5. MQTT'), findsOneWidget);
    expect(
      find.text('Publish-subscribe • broker.hivemq.com:1883'),
      findsOneWidget,
    );
    expect(find.text('Telemetry ESP32'), findsOneWidget);
    expect(find.text('Suhu'), findsOneWidget);
    expect(find.text('Kelembapan'), findsOneWidget);
    expect(find.text('Gas (MQ-2)'), findsOneWidget);
    expect(find.text('Waktu perangkat'), findsOneWidget);
    expect(find.text('Connect & subscribe'), findsOneWidget);
    expect(find.textContaining('iot/esp32/dht22/temperature'), findsOneWidget);
    expect(find.text('Publish'), findsNothing);
    expect(find.text('6. WebRTC DataChannel'), findsOneWidget);
    expect(find.text('8. Push Notification'), findsOneWidget);
    expect(find.text('Aktifkan & minta izin'), findsOneWidget);
    expect(find.text('Join sebagai peer'), findsOneWidget);
    expect(find.text('Buat offer (host)'), findsOneWidget);
    expect(find.text('Pesan peer-to-peer'), findsOneWidget);
    expect(find.text('7. gRPC'), findsOneWidget);
    expect(find.text('Aktifkan & minta izin'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard sections fit a wide report layout', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    expect(find.text('Eksplorasi metode komunikasi'), findsOneWidget);
    expect(find.text('1. REST API'), findsOneWidget);
    expect(find.text('6. WebRTC DataChannel'), findsOneWidget);
    expect(find.text('8. Push Notification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('WebRTC rejects invalid room IDs before connecting', () async {
    final demo = WebRtcMqttDemo();

    await expectLater(
      demo.connectToRoom(
        roomId: 'room/with/slashes',
        isInitiator: false,
        onStatus: (_) {},
        onMessage: (_) {},
      ),
      throwsArgumentError,
    );
  });
}
