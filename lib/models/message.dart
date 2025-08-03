class Message {
  final String role;
  final String content;
  final DateTime? timestamp;

  Message({
    required this.role,
    required this.content,
    this.timestamp,
  });

  // Convert to Map for API calls or serialization
  Map<String, String> toMap() {
    return {
      'role': role,
      'content': content,
    };
  }

  // Create Message from Map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      role: map['role'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : null,
    );
  }

  // Convenience constructors
  factory Message.system(String content) {
    return Message(role: 'system', content: content);
  }

  factory Message.user(String content) {
    return Message(role: 'user', content: content, timestamp: DateTime.now());
  }

  factory Message.assistant(String content) {
    return Message(role: 'assistant', content: content, timestamp: DateTime.now());
  }

  @override
  String toString() => 'Message(role: $role, content: $content)';
}


