import 'package:ai_phone/models/conversation.dart';

class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final String messageExample;
  final String creatorComment;
  final String avatar;
  final String chat;
  final String voice;
  final List<String> tags;

  late final Conversation conversation;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.description,
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.messageExample = '',
    this.creatorComment = '',
    this.avatar = '',
    this.chat = '',
    this.voice = '',
    this.tags = const [],
  }) {
    // Initialize conversation with contact-specific messages
    conversation = Conversation();

    conversation.addSystemMessage("You are using a phone to communicate. give short answers. No ");

    if (description.isNotEmpty) {
      conversation.addSystemMessage(description);
    }

    if (personality.isNotEmpty) {
      conversation.addSystemMessage(personality);
    }

    if (firstMessage.isNotEmpty) {
      conversation.addSystemMessage(firstMessage);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'description': description,
      'personality': personality,
      'scenario': scenario,
      'first_mes': firstMessage,
      'mes_example': messageExample,
      'creatorcomment': creatorComment,
      'avatar': avatar,
      'chat': chat,
      'voice': voice,
      'tags': tags,
    };
  }

  static Contact fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      description: json['description'] ?? '',
      personality: json['personality'] ?? '',
      scenario: json['scenario'] ?? '',
      firstMessage: json['first_mes'] ?? '',
      messageExample: json['mes_example'] ?? '',
      creatorComment: json['creatorcomment'] ?? '',
      avatar: json['avatar'] ?? '',
      chat: json['chat'] ?? '',
      voice: json['voice'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  String get initials {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'
        .toUpperCase();
  }
}