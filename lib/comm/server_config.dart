class ServerConfig {
  static const String _serverHost = String.fromEnvironment(
    'SERVER_IP',
    defaultValue: '192.168.1.74',
  );

  static String get httpBaseUrl => 'http://$_serverHost:3000';

  static String get wsBaseUrl => 'ws://$_serverHost:3000';
}
