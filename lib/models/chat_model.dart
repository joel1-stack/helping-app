import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String requestId;
  final String lastMessage;
  final DateTime lastMessageTime;

  Chat({
    required this.id,
    required this.participants,
    required this.requestId,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'requestId': requestId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id']?.toString() ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      requestId: map['requestId']?.toString() ?? '',
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}