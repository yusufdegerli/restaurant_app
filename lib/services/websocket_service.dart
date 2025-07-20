import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  WebSocket? _socket;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  static const _reconnectInterval = Duration(seconds: 5);
  StreamController<String>? _controller; // Değişiklik: Nullable StreamController
  bool _isClosed = false; // Yeni: StreamController'ın kapalı olup olmadığını takip eder

  WebSocketService() {
    _controller = StreamController<String>.broadcast(); // Başlangıçta oluştur
  }

  Stream<String> get stream => _controller!.stream;

  Future<void> connect({
    void Function(String message)? onMessageReceived,
  }) async {
    if (_isConnecting ||
        (_socket != null && _socket!.readyState == WebSocket.open)) {
      return;
    }

    _isConnecting = true;
    try {
      _socket = await WebSocket.connect('ws://192.168.56.1:5235/ws');
      _isConnecting = false;
      _reconnectTimer?.cancel();

      _socket!.listen(
            (message) {
          if (!_isClosed) { // Değişiklik: _controller kapalıysa veri ekleme
            print("📩 Message from server: $message");
            _controller?.add(message);
            onMessageReceived?.call(message);
          }
        },
        onDone: () {
          if (!_isClosed) { // Değişiklik: _controller kapalıysa hata ekleme
            print("⚠️ WebSocket connection closed.");
            _controller?.addError('WebSocket connection closed');
            _scheduleReconnect(onMessageReceived);
          }
        },
        onError: (error) {
          if (!_isClosed) { // Değişiklik: _controller kapalıysa hata ekleme
            print("❌ WebSocket error: $error");
            _controller?.addError(error);
            _scheduleReconnect(onMessageReceived);
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (!_isClosed) { // Değişiklik: _controller kapalıysa hata ekleme
        print("🚨 Failed to connect WebSocket: $e");
        _controller?.addError(e);
      }
      _isConnecting = false;
      _scheduleReconnect(onMessageReceived);
    }
  }

  void _scheduleReconnect(void Function(String message)? onMessageReceived) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, () {
      if (!_isClosed) { // Değişiklik: Yeniden bağlanma sadece _controller açıkken
        print("🔄 Attempting to reconnect WebSocket...");
        // Yeni: Eğer _controller kapalıysa, yeni bir tane oluştur
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
      print("📤 Sent: $message");
    } else {
      print("⚠️ WebSocket not connected, cannot send: $message");
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.close();
    _socket = null;
    if (!_isClosed) { // Değişiklik: Tekrar kapatmayı önle
      _isClosed = true;
      _controller?.close();
      print("🔌 WebSocket disconnected.");
    }
  }

  Future<void> notifyTableMove(
      int sourceTableId,
      int targetTableId,
      int ticketId,
      ) async {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      print("⚠️ WebSocket bağlantısı yok, bildirim gönderilemedi.");
      return;
    }
    final message = jsonEncode({
      'type': 'ticket_updated',
      'data': {'tableId': targetTableId, 'ticketId': ticketId},
    });
    send(message);
  }
}