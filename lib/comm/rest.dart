import 'dart:convert';

import 'package:http/http.dart' as http;

import 'server_config.dart';

Future<Map<String, dynamic>> getData() async {
  final response = await http.get(
    Uri.parse('${ServerConfig.httpBaseUrl}/api/data'),
  );

  if (response.statusCode != 200) {
    throw Exception('Gagal mengambil data');
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> sendMessage(String message) async {
  final response = await http.post(
    Uri.parse('${ServerConfig.httpBaseUrl}/api/message'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'message': message}),
  );

  if (response.statusCode != 200) {
    throw Exception('Gagal mengirim pesan');
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}
