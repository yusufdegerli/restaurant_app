import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  WebSocket? _socket;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  static const _reconnectInterval = Duration(seconds: 5);
  StreamController<String>? _controller;
  bool _isClosed = false;

  WebSocketService() {
    _controller = StreamController<String>.broadcast();
  }

  Stream<String> get stream => _controller!.stream;

  Future<void> connect({void Function(String message)? onMessageReceived}) async {
    if (_isConnecting || (_socket != null && _socket!.readyState == WebSocket.open)) {
      return;
    }
    _isConnecting = true;
    try {
      _socket = await WebSocket.connect('ws://192.168.56.1:5235/ws');
      _isConnecting = false;
      _reconnectTimer?.cancel();
      _socket!.listen(
        (message) {
          if (!_isClosed) {
            _controller?.add(message);
            onMessageReceived?.call(message);
          }
        },
        onDone: () {
          if (!_isClosed) {
            _controller?.addError('WebSocket connection closed');
            _scheduleReconnect(onMessageReceived);
          }
        },
        onError: (error) {
          if (!_isClosed) {
            _controller?.addError(error);
            _scheduleReconnect(onMessageReceived);
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (!_isClosed) {
        _controller?.addError(e);
      }
      _isConnecting = false;
      _scheduleReconnect(onMessageReceived);
    }
  }

  void _scheduleReconnect(void Function(String message)? onMessageReceived) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isClosed) {
        if (_controller == null || _controller!.isClosed) {
          _controller = StreamController<String>.broadcast();
        }
        connect(onMessageReceived: onMessageReceived);
      }
    });
  }

  void send(String message) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(message);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.close();
    _socket = null;
    if (!_isClosed) {
      _isClosed = true;
      _controller?.close();
    }
  }

  Future<void> notifyTableMove(int sourceTableId, int targetTableId, int ticketId) async {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      return;
    }
    final message = jsonEncode({
      'type': 'ticket_updated',
      'data': {'tableId': targetTableId, 'ticketId': ticketId},
    });
    send(message);
  }
}