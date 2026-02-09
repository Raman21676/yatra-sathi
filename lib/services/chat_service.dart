import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/models.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Chat Service
/// Handles both REST API calls and Socket.io for real-time chat
class ChatService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  io.Socket? _socket;

  // Stream controllers for chat events
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  // ==================== SOCKET.IO METHODS ====================

  /// Connect to Socket.io server
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return; // Already connected
    }

    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(5)
          .build(),
    );

    // Connection events
    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
      _connectionController.add(false);
    });

    // Chat events
    _socket!.on(SocketEvents.newMessage, (data) {
      print('New message received: $data');
      final message = ChatMessage.fromJson(data);
      _messageController.add(message);
    });

    _socket!.on(SocketEvents.userTyping, (data) {
      print('User typing: $data');
      _typingController.add({
        'type': 'typing',
        'userId': data['userId'],
        'name': data['name'],
      });
    });

    _socket!.on(SocketEvents.userStopTyping, (data) {
      print('User stopped typing: $data');
      _typingController.add({
        'type': 'stop_typing',
        'userId': data['userId'],
      });
    });

    _socket!.on(SocketEvents.error, (error) {
      print('Socket error: $error');
    });

    _socket!.connect();
  }

  /// Disconnect from Socket.io server
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  /// Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;

  /// Join a chat room for an offer
  void joinChat(String offerId) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final request = JoinChatRequest(offerId: offerId);
    _socket!.emit(SocketEvents.joinChat, request.toJson());
    print('Joined chat room for offer: $offerId');
  }

  /// Leave a chat room
  void leaveChat(String offerId) {
    if (_socket == null || !_socket!.connected) return;

    final request = LeaveChatRequest(offerId: offerId);
    _socket!.emit(SocketEvents.leaveChat, request.toJson());
    print('Left chat room for offer: $offerId');
  }

  /// Send a message
  void sendMessage({
    required String offerId,
    required String receiverId,
    required String message,
  }) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Socket not connected');
    }

    final request = SendMessageRequest(
      offerId: offerId,
      receiverId: receiverId,
      message: message,
    );

    _socket!.emit(SocketEvents.sendMessage, request.toJson());
    print('Message sent to offer: $offerId');
  }

  /// Emit typing indicator
  void sendTyping(String offerId) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit(SocketEvents.typing, {'offerId': offerId});
  }

  /// Emit stop typing indicator
  void sendStopTyping(String offerId) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit(SocketEvents.stopTyping, {'offerId': offerId});
  }

  // ==================== REST API METHODS ====================

  /// Get chat history for an offer
  Future<List<ChatMessage>> getChatHistory(String offerId) async {
    final response = await _api.get(ApiConstants.chatHistory(offerId));

    if (response.data['success'] == true && response.data['data'] != null) {
      final List<dynamic> messagesJson = response.data['data'];
      return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Get user's conversations
  Future<List<ChatConversation>> getConversations() async {
    final response = await _api.get(ApiConstants.conversations);

    if (response.data['success'] == true && response.data['data'] != null) {
      final List<dynamic> conversationsJson = response.data['data'];
      return conversationsJson.map((json) => ChatConversation.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Mark messages as read
  Future<bool> markAsRead(String offerId) async {
    // This might be handled automatically by the socket
    // But we can also have an API endpoint for it
    try {
      // Implementation depends on backend API
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose streams
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
  }
}
