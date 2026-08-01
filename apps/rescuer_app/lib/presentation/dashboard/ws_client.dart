import 'dart:async';
import 'dart:convert';

import 'package:data/data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RescuerWsClient {
  RescuerWsClient(this._api);

  final ApiClient _api;
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> connect() async {
    final token = await _api.accessToken;
    if (token == null) return;
    final base = _api.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$base/api/v1/ws/rescuer?token=$token');
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (data) {
        try {
          final map = jsonDecode(data as String) as Map<String, dynamic>;
          _controller.add(map);
        } catch (_) {}
      },
      onError: (_) {},
      onDone: () {},
    );
  }

  void dispose() {
    _channel?.sink.close();
    _controller.close();
  }
}
