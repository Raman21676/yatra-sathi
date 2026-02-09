import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiver?.name ?? 'Chat'),
            Text(
              '${widget.offer.fromLocation} → ${widget.offer.toLocation}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Ride Info Card
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(UIConstants.defaultPadding),
            decoration: BoxDecoration(
              color: const Color(UIConstants.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.offer.fromLocation} → ${widget.offer.toLocation}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Messages Area - Placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chat feature coming soon!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Input Area
          Container(
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
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      // Send message
                      _messageController.clear();
                    },
                    icon: const Icon(Icons.send),
                    color: const Color(UIConstants.primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
