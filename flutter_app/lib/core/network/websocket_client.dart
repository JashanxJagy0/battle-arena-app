import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_endpoints.dart';
import '../services/storage_service.dart';

enum WebSocketState { disconnected, connecting, connected, error }

class WebSocketClient {
  final StorageService _storageService;
  final Map<String, io.Socket> _sockets = {};
  final Map<String, WebSocketState> _states = {};

  WebSocketClient({required StorageService storageService})
      : _storageService = storageService;

  Future<io.Socket> connect(String namespace) async {
    if (_sockets.containsKey(namespace)) {
      return _sockets[namespace]!;
    }

    final token = await _storageService.getAccessToken();

    final socket = io.io(
      '${ApiEndpoints.wsBaseUrl}$namespace',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setAuth({'token': token})
          .build(),
    );

    _states[namespace] = WebSocketState.connecting;

    socket.onConnect((_) {
      _states[namespace] = WebSocketState.connected;
      if (kDebugMode) debugPrint('WebSocket connected: $namespace');
    });

    socket.onDisconnect((_) {
      _states[namespace] = WebSocketState.disconnected;
      if (kDebugMode) debugPrint('WebSocket disconnected: $namespace');
    });

    socket.onError((data) {
      _states[namespace] = WebSocketState.error;
      if (kDebugMode) debugPrint('WebSocket error [$namespace]: $data');
    });

    socket.onConnectError((data) {
      _states[namespace] = WebSocketState.error;
      if (kDebugMode) debugPrint('WebSocket connect error [$namespace]: $data');
    });

    _sockets[namespace] = socket;
    return socket;
  }

  void disconnect(String namespace) {
    _sockets[namespace]?.disconnect();
    _sockets.remove(namespace);
    _states.remove(namespace);
  }

  void disconnectAll() {
    for (final socket in _sockets.values) {
      socket.disconnect();
    }
    _sockets.clear();
    _states.clear();
  }

  WebSocketState getState(String namespace) {
    return _states[namespace] ?? WebSocketState.disconnected;
  }

  bool isConnected(String namespace) {
    return _states[namespace] == WebSocketState.connected;
  }

  void emit(String namespace, String event, dynamic data) {
    _sockets[namespace]?.emit(event, data);
  }

  void on(String namespace, String event, Function(dynamic) handler) {
    _sockets[namespace]?.on(event, handler);
  }

  void off(String namespace, String event) {
    _sockets[namespace]?.off(event);
  }
}
