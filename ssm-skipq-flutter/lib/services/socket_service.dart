import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import '../models/order.dart';
import '../models/settings.dart';
import 'api_client.dart';

class SocketService {
  SocketService(this._api);

  final ApiClient _api;
  io.Socket? _socket;

  io.Socket? get socket => _socket;

  Future<void> connect() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) return;

    _socket?.dispose();
    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void joinStudentRoom() {
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('join:student');
    } else {
      socket.once('connect', (_) => socket.emit('join:student'));
    }
  }

  void joinManagerRoom() {
    _socket?.emit('join:manager');
  }

  void onOrderUpdated(void Function(Order order) handler) {
    _socket?.on('order:updated', (data) {
      if (data is Map) {
        handler(Order.fromJson(Map<String, dynamic>.from(data)));
      }
    });
  }

  void onOrderCreated(void Function(Order order) handler) {
    _socket?.on('order:created', (data) {
      if (data is Map) {
        handler(Order.fromJson(Map<String, dynamic>.from(data)));
      }
    });
  }

  void onOrderingWindow(void Function(OrderingWindow window) handler) {
    _socket?.on('settings:ordering-window', (data) {
      if (data is Map) {
        handler(OrderingWindow.fromJson(Map<String, dynamic>.from(data)));
      }
    });
  }

  void off(String event) {
    _socket?.off(event);
  }
}
