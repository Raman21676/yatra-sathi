import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ChatScreen extends StatefulWidget {
  final VehicleOffer offer;
  final User? receiver;

  const ChatScreen({
    super.key,
    required this.offer,
    this.receiver,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;

  User? get _currentUser =>
      Provider.of<AuthProvider>(context, listen: false).user;

  String get _receiverId {
    if (widget.receiver != null) return widget.receiver!.id;
    // If receiver is not provided, determine from offer
    if (_currentUser?.id == widget.offer.ownerId) {
      // Current user is owner, need to find passenger
      // This should come from conversation data
      return '';
    } else {
      // Current user is passenger, receiver is owner
      return widget.offer.ownerId;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Ensure connection
    if (!chatProvider.isConnected) {
      await chatProvider.initialize();
    }

    // Join chat room
    chatProvider.joinChat(widget.offer.id);

    // Load message history
    await _loadMessages();

    // Setup listeners
    _setupListeners();

    // Mark as read
    chatProvider.markAsRead(widget.offer.id);
  }

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    setState(() => _isLoading = true);
    
    await chatProvider.loadChatHistory(widget.offer.id);
    
    if (mounted) {
      setState(() {
        _messages = chatProvider.messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _setupListeners() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Listen for new messages
    _messageSubscription = chatProvider.messageStream.listen((message) {
      if (mounted && message.offerId == widget.offer.id) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });

    // Listen for typing indicators
    _typingSubscription = chatProvider.typingStream.listen((data) {
      if (mounted) {
        final userId = data['userId'] as String?;
        final type = data['type'] as String?;

        if (userId != null && userId != _currentUser?.id) {
          setState(() {
            _isTyping = type == 'typing';
          });
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleTyping() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    chatProvider.sendTyping(widget.offer.id);

    // Reset typing after delay
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      chatProvider.sendStopTyping(widget.offer.id);
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Send via socket
    chatProvider.sendMessage(
      offerId: widget.offer.id,
      receiverId: _receiverId,
      message: message,
    );

    // Clear input
    _messageController.clear();

    // Stop typing indicator
    chatProvider.sendStopTyping(widget.offer.id);
    _typingTimer?.cancel();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    
    // Leave chat room
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.leaveChat(widget.offer.id);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            // Show user profile
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.receiver?.photo != null
                    ? NetworkImage(widget.receiver!.photo)
                    : null,
                child: widget.receiver?.photo == null
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receiver?.name ?? 'Chat',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_isTyping)
                      const Text(
                        'typing...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        '${widget.offer.fromLocation} → ${widget.offer.toLocation}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ride Info Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.all(UIConstants.smallPadding),
            decoration: BoxDecoration(
              color: const Color(UIConstants.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(UIConstants.smallRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Helpers.getVehicleIcon(widget.offer.vehicleType),
                  size: 20,
                  color: const Color(UIConstants.primaryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.offer.fromLocation} → ${widget.offer.toLocation}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  Helpers.formatCurrency(widget.offer.fare),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(UIConstants.primaryColor),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyMessages()
                    : _buildMessagesList(),
          ),
          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discuss ride details with ${widget.receiver?.name ?? 'the driver'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUser?.id;
        final showAvatar = index == 0 ||
            _messages[index - 1].senderId != message.senderId;

        return _buildMessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage message,
    required bool isMe,
    required bool showAvatar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.sender?.photo != null
                  ? NetworkImage(message.sender!.photo)
                  : null,
              child: message.sender?.photo == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe)
            const SizedBox(width: 40),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(UIConstants.primaryColor)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: Radius.circular(!isMe ? 4 : 20),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helpers.formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _handleTyping(),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(UIConstants.primaryColor),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('View Ride Details'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to offer detail
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Block user
              },
            ),
          ],
        ),
      ),
    );
  }
}
