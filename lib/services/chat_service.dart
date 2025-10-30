import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chat for a help request
  Future<Chat?> getOrCreateChat(String requestId, List<String> participants) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('requestId', isEqualTo: requestId)
          .get();

      if (existingChat.docs.isNotEmpty) {
        final doc = existingChat.docs.first;
        return Chat.fromMap({...doc.data(), 'id': doc.id});
      }

      // Create new chat
      final docRef = _firestore.collection('chats').doc(requestId);

      final chat = Chat(
        id: docRef.id,
        participants: participants,
        requestId: requestId,
        lastMessage: 'Chat started',
        lastMessageTime: DateTime.now(),
      );

      await docRef.set(chat.toMap());
      return chat;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  // Send message
  Future<bool> sendMessage(String chatId, String senderId, String text) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = ChatMessage(
        id: messageRef.id,
        senderId: senderId,
        text: text,
        timestamp: DateTime.now(),
      );

      await messageRef.set(message.toMap());

      // Update last message in chat
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get messages for a chat
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final messages = <ChatMessage>[];
      for (final doc in snapshot.docs) {
        try {
          final message = ChatMessage.fromMap({...doc.data(), 'id': doc.id});
          messages.add(message);
        } catch (e) {
          print('Error parsing message ${doc.id}: $e');
        }
      }
      return messages;
    });
  }

  // Get user's chats
  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      final chats = <Chat>[];
      for (final doc in snapshot.docs) {
        try {
          final chat = Chat.fromMap({...doc.data(), 'id': doc.id});
          chats.add(chat);
        } catch (e) {
          print('Error parsing chat ${doc.id}: $e');
        }
      }
      return chats;
    });
  }
}