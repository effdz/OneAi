import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oneai/models/user_model.dart';
import 'package:oneai/models/message_model.dart';
import 'package:oneai/models/conversation_model.dart';
import 'package:crypto/crypto.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Password hashing
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  // User operations
  Future<void> _saveUserToPrefs(UserModel user, String passwordHash) async {
    final prefs = await this.prefs;
    final userData = {
      'id': user.id,
      'username': user.username,
      'email': user.email.toLowerCase(),
      'password_hash': passwordHash,
      'avatar_url': user.avatarUrl,
      'created_at': DateTime.now().toIso8601String(),
      'last_login': user.lastLogin?.toIso8601String(),
      'is_active': true,
    };

    // Save user data
    await prefs.setString('user_${user.email.toLowerCase()}', jsonEncode(userData));

    // Save to users list
    final usersList = prefs.getStringList('users_list') ?? [];
    if (!usersList.contains(user.email.toLowerCase())) {
      usersList.add(user.email.toLowerCase());
      await prefs.setStringList('users_list', usersList);
    }

    print('User saved to SharedPreferences: ${user.email}');
  }

  Future<Map<String, dynamic>?> _getUserFromPrefs(String email) async {
    final prefs = await this.prefs;
    final userDataString = prefs.getString('user_${email.toLowerCase()}');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  Future<bool> registerUser(String username, String email, String password) async {
    try {
      print('Attempting to register user: $email');

      // Check if user already exists
      final existingUser = await _getUserFromPrefs(email);
      if (existingUser != null) {
        print('User already exists: $email');
        throw Exception('Email sudah terdaftar');
      }

      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final passwordHash = _hashPassword(password);

      final user = UserModel(
        id: userId,
        username: username,
        email: email,
      );

      await _saveUserToPrefs(user, passwordHash);
      print('User registered successfully: $email');
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<UserModel?> loginUser(String email, String password) async {
    try {
      print('Attempting to login user: $email');

      final userData = await _getUserFromPrefs(email);
      if (userData != null && _verifyPassword(password, userData['password_hash'])) {
        // Update last login
        userData['last_login'] = DateTime.now().toIso8601String();
        final prefs = await this.prefs;
        await prefs.setString('user_${email.toLowerCase()}', jsonEncode(userData));

        print('User logged in successfully: $email');
        return UserModel(
          id: userData['id'],
          username: userData['username'],
          email: userData['email'],
          lastLogin: DateTime.now(),
          avatarUrl: userData['avatar_url'],
        );
      }

      print('Login failed for user: $email');
      return null;
    } catch (e) {
      print('Error logging in user: $e');
      return null;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      print('Getting user by ID: $userId');

      final prefs = await this.prefs;
      final usersList = prefs.getStringList('users_list') ?? [];

      for (final email in usersList) {
        final userData = await _getUserFromPrefs(email);
        if (userData != null && userData['id'] == userId) {
          print('User found by ID: ${userData['username']}');
          return UserModel(
            id: userData['id'],
            username: userData['username'],
            email: userData['email'],
            lastLogin: userData['last_login'] != null
                ? DateTime.parse(userData['last_login'])
                : null,
            avatarUrl: userData['avatar_url'],
          );
        }
      }

      print('User not found by ID: $userId');
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<bool> emailExists(String email) async {
    try {
      final userData = await _getUserFromPrefs(email);
      final exists = userData != null;
      print('Email exists check for $email: $exists');
      return exists;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Conversation operations
  Future<String> createConversation(String userId, String chatbotId, String? title) async {
    try {
      print('Creating conversation for user: $userId, chatbot: $chatbotId');

      final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
      final prefs = await this.prefs;

      final conversation = {
        'id': conversationId,
        'user_id': userId,
        'chatbot_id': chatbotId,
        'title': title ?? 'New Conversation',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_archived': false,
      };

      await prefs.setString('conversation_$conversationId', jsonEncode(conversation));

      // Add to user's conversations list
      final userConversations = prefs.getStringList('conversations_$userId') ?? [];
      userConversations.add(conversationId);
      await prefs.setStringList('conversations_$userId', userConversations);

      print('Conversation created: $conversationId');
      return conversationId;
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  Future<List<ConversationModel>> getUserConversations(String userId) async {
    try {
      print('Getting conversations for user: $userId');

      final prefs = await this.prefs;
      final conversationIds = prefs.getStringList('conversations_$userId') ?? [];
      final conversations = <ConversationModel>[];

      print('Found ${conversationIds.length} conversation IDs');

      for (final id in conversationIds) {
        final conversationData = prefs.getString('conversation_$id');
        if (conversationData != null) {
          final data = jsonDecode(conversationData);
          if (!(data['is_archived'] ?? false)) {
            conversations.add(ConversationModel(
              id: data['id'],
              userId: data['user_id'],
              chatbotId: data['chatbot_id'],
              title: data['title'],
              createdAt: DateTime.parse(data['created_at']),
              updatedAt: DateTime.parse(data['updated_at']),
              isArchived: data['is_archived'] ?? false,
              messageCount: _getMessageCount(id),
            ));
          }
        }
      }

      // Sort by updated_at descending
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      print('Returning ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  int _getMessageCount(String conversationId) {
    try {
      final messageIds = _prefs?.getStringList('messages_$conversationId') ?? [];
      return messageIds.length;
    } catch (e) {
      return 0;
    }
  }

  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      print('Getting conversation: $conversationId');

      final prefs = await this.prefs;
      final conversationData = prefs.getString('conversation_$conversationId');
      if (conversationData != null) {
        final data = jsonDecode(conversationData);
        return ConversationModel(
          id: data['id'],
          userId: data['user_id'],
          chatbotId: data['chatbot_id'],
          title: data['title'],
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
          isArchived: data['is_archived'] ?? false,
          messageCount: _getMessageCount(conversationId),
        );
      }
      return null;
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }

  Future<void> updateConversationTitle(String conversationId, String title) async {
    try {
      print('Updating conversation title: $conversationId -> $title');

      final prefs = await this.prefs;
      final conversationData = prefs.getString('conversation_$conversationId');
      if (conversationData != null) {
        final data = jsonDecode(conversationData);
        data['title'] = title;
        data['updated_at'] = DateTime.now().toIso8601String();
        await prefs.setString('conversation_$conversationId', jsonEncode(data));
        print('Conversation title updated successfully');
      }
    } catch (e) {
      print('Error updating conversation title: $e');
    }
  }

  // Message operations
  Future<void> insertMessage(String conversationId, MessageModel message) async {
    try {
      print('Inserting message into conversation: $conversationId');

      final prefs = await this.prefs;

      // Save message
      final messageData = {
        'id': message.id,
        'conversation_id': conversationId,
        'content': message.text,
        'is_user': message.isUser,
        'timestamp': message.timestamp.toIso8601String(),
        'token_count': message.text.split(' ').length,
      };

      await prefs.setString('message_${message.id}', jsonEncode(messageData));

      // Add to conversation's messages list
      final conversationMessages = prefs.getStringList('messages_$conversationId') ?? [];
      conversationMessages.add(message.id);
      await prefs.setStringList('messages_$conversationId', conversationMessages);

      // Update conversation timestamp
      final conversationData = prefs.getString('conversation_$conversationId');
      if (conversationData != null) {
        final data = jsonDecode(conversationData);
        data['updated_at'] = DateTime.now().toIso8601String();
        await prefs.setString('conversation_$conversationId', jsonEncode(data));
      }

      print('Message inserted successfully');
    } catch (e) {
      print('Error inserting message: $e');
    }
  }

  Future<List<MessageModel>> getConversationMessages(String conversationId) async {
    try {
      print('Getting messages for conversation: $conversationId');

      final prefs = await this.prefs;
      final messageIds = prefs.getStringList('messages_$conversationId') ?? [];
      final messages = <MessageModel>[];

      print('Found ${messageIds.length} message IDs');

      for (final id in messageIds) {
        final messageData = prefs.getString('message_$id');
        if (messageData != null) {
          final data = jsonDecode(messageData);
          messages.add(MessageModel(
            id: data['id'],
            text: data['content'],
            isUser: data['is_user'],
            timestamp: DateTime.parse(data['timestamp']),
            tokenCount: data['token_count'],
          ));
        }
      }

      // Sort by timestamp ascending
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('Returning ${messages.length} messages');
      return messages;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      print('Deleting conversation: $conversationId');

      final prefs = await this.prefs;

      // Delete messages
      final messageIds = prefs.getStringList('messages_$conversationId') ?? [];
      for (final messageId in messageIds) {
        await prefs.remove('message_$messageId');
      }
      await prefs.remove('messages_$conversationId');

      // Delete conversation
      await prefs.remove('conversation_$conversationId');

      // Remove from user's conversations list
      final usersList = prefs.getStringList('users_list') ?? [];
      for (final email in usersList) {
        final userData = await _getUserFromPrefs(email);
        if (userData != null) {
          final userId = userData['id'];
          final userConversations = prefs.getStringList('conversations_$userId') ?? [];
          userConversations.remove(conversationId);
          await prefs.setStringList('conversations_$userId', userConversations);
        }
      }

      print('Conversation deleted successfully');
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      print('Archiving conversation: $conversationId');

      final prefs = await this.prefs;
      final conversationData = prefs.getString('conversation_$conversationId');
      if (conversationData != null) {
        final data = jsonDecode(conversationData);
        data['is_archived'] = true;
        await prefs.setString('conversation_$conversationId', jsonEncode(data));
        print('Conversation archived successfully');
      }
    } catch (e) {
      print('Error archiving conversation: $e');
    }
  }

  // Simplified methods for SharedPreferences
  Future<List<Map<String, dynamic>>> searchMessages(String userId, String query) async {
    // For SharedPreferences, we'll return empty list for now
    // This can be implemented later if needed
    return [];
  }

  Future<void> recordUsage(String userId, String chatbotId, int messageCount, int tokenUsage) async {
    // For SharedPreferences, we'll skip analytics for now
    // This can be implemented later if needed
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final prefs = await this.prefs;
      final conversationIds = prefs.getStringList('conversations_$userId') ?? [];

      int totalMessages = 0;
      for (final convId in conversationIds) {
        final messageIds = prefs.getStringList('messages_$convId') ?? [];
        totalMessages += messageIds.length;
      }

      return {
        'total_messages': totalMessages,
        'total_conversations': conversationIds.length,
        'favorite_bot': null,
        'weekly_messages': 0,
      };
    } catch (e) {
      return {
        'total_messages': 0,
        'total_conversations': 0,
        'favorite_bot': null,
        'weekly_messages': 0,
      };
    }
  }

  Future<void> cleanupOldData() async {
    // For SharedPreferences, we'll skip cleanup for now
  }

  Future<void> closeDatabase() async {
    // Nothing to close for SharedPreferences
  }

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'note': 'Export functionality using SharedPreferences',
    };
  }

  // Initialize database (for compatibility)
  Future<void> get database async {
    // Just ensure SharedPreferences is initialized
    await prefs;
  }
}
