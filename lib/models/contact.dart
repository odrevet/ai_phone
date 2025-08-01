class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String character;
  final String scenario;
  final String firstMessage;
  final String messageExample;
  final String creatorComment;
  final String avatar;
  final String chat;
  final List<String> tags;
  final Map<String, dynamic> data;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.character,
    this.scenario = '',
    this.firstMessage = '',
    this.messageExample = '',
    this.creatorComment = '',
    this.avatar = '',
    this.chat = '',
    this.tags = const [],
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'character': character,
      'scenario': scenario,
      'first_mes': firstMessage,
      'mes_example': messageExample,
      'creatorcomment': creatorComment,
      'avatar': avatar,
      'chat': chat,
      'tags': tags,
      'data': data,
    };
  }

  static Contact fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      character: json['character'] ?? '',
      scenario: json['scenario'] ?? '',
      firstMessage: json['first_mes'] ?? '',
      messageExample: json['mes_example'] ?? '',
      creatorComment: json['creatorcomment'] ?? '',
      avatar: json['avatar'] ?? '',
      chat: json['chat'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
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
