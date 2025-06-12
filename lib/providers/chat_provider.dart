import 'package:flutter/material.dart';
import 'package:oneai/models/message_model.dart';
import 'package:oneai/services/chatbot_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final Map<String, List<MessageModel>> _chatHistory = {};
  List<MessageModel> _currentMessages = [];
  String _currentChatbotId = '';
  bool _isLoading = false;

  List<MessageModel> get messages => _currentMessages;
  bool get isLoading => _isLoading;

  void initChat(String chatbotId) {
    _currentChatbotId = chatbotId;
    if (_chatHistory.containsKey(chatbotId)) {
      _currentMessages = _chatHistory[chatbotId]!;
    } else {
      _currentMessages = [];
      _chatHistory[chatbotId] = _currentMessages;
    }
    notifyListeners();
  }

  void sendMessage(String text) async {
    if (text.isEmpty) return;

    final userMessage = MessageModel(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _currentMessages.add(userMessage);
    _chatHistory[_currentChatbotId] = _currentMessages;
    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Get response from the selected chatbot
      final response = await ChatbotService.getChatbotResponse(
        _currentChatbotId,
        text,
      );

      final botMessage = MessageModel(
        id: const Uuid().v4(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _currentMessages.add(botMessage);
      _chatHistory[_currentChatbotId] = _currentMessages;
    } catch (e) {
      // Handle error
      final errorMessage = MessageModel(
        id: const Uuid().v4(),
        text: 'Sorry, I encountered an error. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _currentMessages.add(errorMessage);
      _chatHistory[_currentChatbotId] = _currentMessages;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat(String chatbotId) {
    _currentMessages = [];
    _chatHistory[chatbotId] = _currentMessages;
    notifyListeners();
  }
}
