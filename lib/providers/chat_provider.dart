import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Chat Provider
/// Manages real-time chat state
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  // State
  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  ChatConversation? _selectedConversation;
  bool _isLoading = false;
  String? _error;
  bool _isConnected = false;
  bool _isTyping = false;
  Map<String, bool> _otherUserTyping = {};

  // Stream subscriptions
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // Getters
  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  ChatConversation? get selectedConversation => _selectedConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;
  bool get isTyping => _isTyping;
  Map<String, bool> get otherUserTyping => _otherUserTyping;

  /// Initialize chat - connect to socket
  Future<void> initialize() async {
    try {
      await _chatService.connect();
      _setupListeners();
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Setup socket event listeners
  void _setupListeners() {
    // Listen for new messages
    _messageSubscription = _chatService.messageStream.listen((message) {
      _handleNewMessage(message);
    });

    // Listen for typing indicators
    _typingSubscription = _chatService.typingStream.listen((data) {
      _handleTypingEvent(data);
    });

    // Listen for connection state
    _connectionSubscription = _chatService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });
  }

  /// Handle incoming message
  void _handleNewMessage(ChatMessage message) {
    // Add to messages if in current chat
    if (_selectedConversation?.offerId == message.offerId) {
      _messages.add(message);
      notifyListeners();
    }

    // Update conversation list
    _updateConversationFromMessage(message);
  }

  /// Handle typing event
  void _handleTypingEvent(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final type = data['type'] as String?;

    if (userId != null) {
      _otherUserTyping[userId] = type == 'typing';
      notifyListeners();
    }
  }

  /// Update conversation with new message
  void _updateConversationFromMessage(ChatMessage message) {
    final index = _conversations.indexWhere((c) => c.offerId == message.offerId);
    
    if (index != -1) {
      // Update existing conversation
      final conversation = _conversations[index];
      _conversations[index] = ChatConversation(
        offerId: conversation.offerId,
        lastMessage: message.message,
        lastTimestamp: message.timestamp,
        unreadCount: conversation.unreadCount + 1,
        offer: conversation.offer,
        otherUser: conversation.otherUser,
      );
    }
    
    // Sort by last message time
    _conversations.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    notifyListeners();
  }

  /// Load user's conversations
  Future<void> loadConversations() async {
    _setLoading(true);
    _error = null;

    try {
      final conversations = await _chatService.getConversations();
      _conversations = conversations;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Load chat history for an offer
  Future<void> loadChatHistory(String offerId) async {
    _setLoading(true);
    _error = null;

    try {
      final messages = await _chatService.getChatHistory(offerId);
      _messages = messages;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Join a chat room
  void joinChat(String offerId) {
    try {
      _chatService.joinChat(offerId);
      // Clear previous messages when joining new chat
      _messages = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Leave a chat room
  void leaveChat(String offerId) {
    try {
      _chatService.leaveChat(offerId);
      _otherUserTyping = {};
      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving chat: $e');
    }
  }

  /// Send a message
  void sendMessage({
    required String offerId,
    required String receiverId,
    required String message,
  }) {
    try {
      _chatService.sendMessage(
        offerId: offerId,
        receiverId: receiverId,
        message: message,
      );
      
      // Optimistically add message to local list
      // The actual message will be confirmed via socket
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send typing indicator
  void sendTyping(String offerId) {
    if (!_isTyping) {
      _isTyping = true;
      _chatService.sendTyping(offerId);
      
      // Stop typing after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        sendStopTyping(offerId);
      });
    }
  }

  /// Send stop typing indicator
  void sendStopTyping(String offerId) {
    _isTyping = false;
    _chatService.sendStopTyping(offerId);
  }

  /// Mark messages as read
  Future<void> markAsRead(String offerId) async {
    try {
      await _chatService.markAsRead(offerId);
      
      // Update local unread count
      final index = _conversations.indexWhere((c) => c.offerId == offerId);
      if (index != -1) {
        final conversation = _conversations[index];
        _conversations[index] = ChatConversation(
          offerId: conversation.offerId,
          lastMessage: conversation.lastMessage,
          lastTimestamp: conversation.lastTimestamp,
          unreadCount: 0,
          offer: conversation.offer,
          otherUser: conversation.otherUser,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  /// Get unread message count
  int getUnreadCount() {
    return _conversations.fold(0, (sum, c) => sum + c.unreadCount);
  }

  /// Set selected conversation
  void setSelectedConversation(ChatConversation conversation) {
    _selectedConversation = conversation;
    notifyListeners();
  }

  /// Clear selected conversation
  void clearSelectedConversation() {
    if (_selectedConversation != null) {
      leaveChat(_selectedConversation!.offerId);
    }
    _selectedConversation = null;
    _messages = [];
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reconnect socket
  Future<void> reconnect() async {
    await _chatService.connect();
  }

  /// Dispose provider
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
