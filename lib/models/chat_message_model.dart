import 'user_model.dart';

/// Chat Message Model
/// Represents individual messages in the real-time chat system
class ChatMessage {
  final String id;
  final String offerId;
  final String senderId;
  final User? sender;
  final String receiverId;
  final User? receiver;
  final String message;
  final bool read;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.offerId,
    required this.senderId,
    this.sender,
    required this.receiverId,
    this.receiver,
    required this.message,
    this.read = false,
    required this.timestamp,
  });

  /// Create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      offerId: json['offerId'] ?? '',
      senderId: json['senderId'] is Map 
          ? json['senderId']['_id'] ?? '' 
          : json['senderId'] ?? '',
      sender: json['senderId'] is Map 
          ? User.fromJson(json['senderId']) 
          : (json['sender'] != null ? User.fromJson(json['sender']) : null),
      receiverId: json['receiverId'] is Map 
          ? json['receiverId']['_id'] ?? '' 
          : json['receiverId'] ?? '',
      receiver: json['receiverId'] is Map 
          ? User.fromJson(json['receiverId']) 
          : (json['receiver'] != null ? User.fromJson(json['receiver']) : null),
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  /// Convert ChatMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'offerId': offerId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'read': read,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy of ChatMessage with updated fields
  ChatMessage copyWith({
    String? id,
    String? offerId,
    String? senderId,
    User? sender,
    String? receiverId,
    User? receiver,
    String? message,
    bool? read,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      receiverId: receiverId ?? this.receiverId,
      receiver: receiver ?? this.receiver,
      message: message ?? this.message,
      read: read ?? this.read,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, sender: $senderId, message: ${message.substring(0, message.length > 20 ? 20 : message.length)}...)';
  }
}

/// Send Message Request Model (Socket.io)
class SendMessageRequest {
  final String offerId;
  final String receiverId;
  final String message;

  SendMessageRequest({
    required this.offerId,
    required this.receiverId,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'receiverId': receiverId,
      'message': message,
    };
  }
}

/// Chat Room Model
/// Represents a conversation between users for a specific offer
class ChatConversation {
  final String offerId;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;
  final VehicleOfferSummary? offer;
  final UserSummary? otherUser;

  ChatConversation({
    required this.offerId,
    required this.lastMessage,
    required this.lastTimestamp,
    this.unreadCount = 0,
    this.offer,
    this.otherUser,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      offerId: json['offerId'] ?? json['_id'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastTimestamp: json['lastTimestamp'] != null 
          ? DateTime.parse(json['lastTimestamp']) 
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      offer: json['offer'] != null 
          ? VehicleOfferSummary.fromJson(json['offer']) 
          : null,
      otherUser: json['otherUser'] != null 
          ? UserSummary.fromJson(json['otherUser']) 
          : null,
    );
  }
}

/// Simplified Vehicle Offer for Chat
class VehicleOfferSummary {
  final String id;
  final String fromLocation;
  final String toLocation;
  final DateTime leaveTime;

  VehicleOfferSummary({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.leaveTime,
  });

  factory VehicleOfferSummary.fromJson(Map<String, dynamic> json) {
    return VehicleOfferSummary(
      id: json['_id'] ?? json['id'] ?? '',
      fromLocation: json['fromLocation'] ?? '',
      toLocation: json['toLocation'] ?? '',
      leaveTime: json['leaveTime'] != null 
          ? DateTime.parse(json['leaveTime']) 
          : DateTime.now(),
    );
  }
}

/// Simplified User for Chat
class UserSummary {
  final String id;
  final String name;
  final String photo;

  UserSummary({
    required this.id,
    required this.name,
    required this.photo,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      photo: json['photo'] ?? '',
    );
  }
}

/// Socket Events Models
class JoinChatRequest {
  final String offerId;

  JoinChatRequest({required this.offerId});

  Map<String, dynamic> toJson() {
    return {'offerId': offerId};
  }
}

class LeaveChatRequest {
  final String offerId;

  LeaveChatRequest({required this.offerId});

  Map<String, dynamic> toJson() {
    return {'offerId': offerId};
  }
}

class TypingRequest {
  final String offerId;

  TypingRequest({required this.offerId});

  Map<String, dynamic> toJson() {
    return {'offerId': offerId};
  }
}
