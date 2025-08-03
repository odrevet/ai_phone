import 'message.dart';

class Conversation {
  final List<Message> _messages;

  Conversation({
    List<Message>? initialMessages,
  }) : _messages = initialMessages ?? [];

  // Get all messages
  List<Message> get messages => List.unmodifiable(_messages);

  // Get messages as List<Map<String, String>> for API compatibility
  List<Map<String, String>> get messagesAsMap {
    return _messages.map((msg) => msg.toMap()).toList();
  }

  // Add a message
  void addMessage(Message message) {
    _messages.add(message);
  }

  // Add multiple messages
  void addMessages(List<Message> messages) {
    _messages.addAll(messages);
  }

  // Convenience methods for adding messages
  void addSystemMessage(String content) {
    addMessage(Message.system(content));
  }

  void addUserMessage(String content) {
    addMessage(Message.user(content));
  }

  void addAssistantMessage(String content) {
    addMessage(Message.assistant(content));
  }

  // Get last message
  Message? get lastMessage => _messages.isNotEmpty ? _messages.last : null;

  // Get messages by role
  List<Message> getMessagesByRole(String role) {
    return _messages.where((msg) => msg.role == role).toList();
  }

  // Clear conversation
  void clear() {
    _messages.clear();
  }

  // Get message count
  int get messageCount => _messages.length;

  // Check if conversation is empty
  bool get isEmpty => _messages.isEmpty;
}