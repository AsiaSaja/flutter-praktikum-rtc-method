import 'package:flutter_http_sse/client/sse_client.dart'; // Path diubah ke client/
import 'package:flutter_http_sse/enum/request_method_type_enum.dart'; // Import Enum baru
import 'package:flutter_http_sse/model/sse_request.dart';
import 'package:flutter_http_sse/model/sse_response.dart';

import 'server_config.dart';

class SSEService {
  final SSEClient _sseClient = SSEClient();
  final String _connectionId = 'sse_connection_1';

  void connect({
    void Function(SSEResponse response)? onData,
    void Function(Object error)? onError,
  }) {
    final request = SSERequest(
      requestType: RequestMethodType.get,
      url: '${ServerConfig.httpBaseUrl}/api/events',

      onData: (data) {
        print('SSE Data Masuk: $data');
        onData?.call(data);
      },

      onError: (error) {
        print('SSE Error: $error');
        onError?.call(Exception(error));
      },
      onDone: () => print('SSE Connection Closed'),
      retry: true,
    );

    final Stream<SSEResponse> stream = _sseClient.connect(
      _connectionId,
      request,
    );

    stream.listen(
      (SSEResponse response) {},
      onError: (Object error) {
        print('Stream Error: $error');
        onError?.call(error);
      },
      onDone: () => print('Stream Closed'),
    );
  }

  void disconnect() {
    _sseClient.close(connectionId: _connectionId);
    print('SSE Connection Manually Closed');
  }
}
