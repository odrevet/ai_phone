import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/contact.dart';

class CharacterCardMetadataDialog extends StatefulWidget {
  final Map<String, String> metadata;
  final String filename;
  final Function(Contact) onImport;

  const CharacterCardMetadataDialog({
    super.key,
    required this.metadata,
    required this.filename,
    required this.onImport,
  });

  @override
  _CharacterCardMetadataDialogState createState() =>
      _CharacterCardMetadataDialogState();
}

class _CharacterCardMetadataDialogState
    extends State<CharacterCardMetadataDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _characterController = TextEditingController();
  final _scenarioController = TextEditingController();
  final _firstMessageController = TextEditingController();
  final _messageExampleController = TextEditingController();
  final _creatorCommentController = TextEditingController();
  final _avatarController = TextEditingController();
  final _chatController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _parseMetadata();
  }

  void _parseMetadata() {
    // Try to extract character information from common metadata fields
    String characterData = '';
    String characterName = '';

    characterData = widget.metadata['chara'] ?? '';

    // Try to parse JSON if the metadata contains character data
    if (characterData.isNotEmpty) {
      try {
        final decoded = json.decode(characterData);
        if (decoded is Map<String, dynamic>) {
          characterName = decoded['name'] ?? decoded['char_name'] ?? '';
          final description =
              decoded['description'] ?? decoded['personality'] ?? '';
          final scenario = decoded['scenario'] ?? '';
          final firstMes = decoded['first_mes'] ?? '';
          final mesExample = decoded['mes_example'] ?? '';
          final creatorComment =
              decoded['creatorcomment'] ?? decoded['creator_notes'] ?? '';
          final avatar = decoded['avatar'] ?? '';
          final chat = decoded['chat'] ?? '';
          final tags = decoded['tags'] ?? [];

          _nameController.text = characterName;
          _characterController.text = description.length > 100
              ? description.substring(0, 100) + '...'
              : description;
          _scenarioController.text = scenario;
          _firstMessageController.text = firstMes;
          _messageExampleController.text = mesExample;
          _creatorCommentController.text = creatorComment;
          _avatarController.text = avatar;
          _chatController.text = chat;

          if (tags is List) {
            _tagsController.text = tags.join(', ');
          }
        }
      } catch (e) {
        // If JSON parsing fails, try to extract name from plain text
        if (characterData.length > 10) {
          _characterController.text = characterData.length > 100
              ? characterData.substring(0, 100) + '...'
              : characterData;
        }
      }
    }

    // If no name was found, use filename
    if (_nameController.text.isEmpty) {
      final nameFromFile = widget.filename
          .replaceAll('.png', '')
          .replaceAll('_', ' ');
      _nameController.text = nameFromFile;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _characterController.dispose();
    _scenarioController.dispose();
    _firstMessageController.dispose();
    _messageExampleController.dispose();
    _creatorCommentController.dispose();
    _avatarController.dispose();
    _chatController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _import() {
    if (_formKey.currentState!.validate()) {
      final tagsText = _tagsController.text.trim();
      final tagsList = tagsText.isEmpty
          ? <String>[]
          : tagsText
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();

      final contact = Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        character: _characterController.text.trim(),
        scenario: _scenarioController.text.trim(),
        firstMessage: _firstMessageController.text.trim(),
        messageExample: _messageExampleController.text.trim(),
        creatorComment: _creatorCommentController.text.trim(),
        avatar: _avatarController.text.trim(),
        chat: _chatController.text.trim(),
        tags: tagsList,
        data: {},
      );
      widget.onImport(contact);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Import Character Card'),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${widget.filename}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              ExpansionTile(
                title: Text(
                  'Metadata (${widget.metadata.length} items)',
                  style: TextStyle(fontSize: 14),
                ),
                children: [
                  Container(
                    height: 150,
                    child: ListView.builder(
                      itemCount: widget.metadata.length,
                      itemBuilder: (context, index) {
                        final entry = widget.metadata.entries.elementAt(index);
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.length > 100
                                      ? '${entry.value.substring(0, 100)}...'
                                      : entry.value,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _characterController,
                      decoration: InputDecoration(
                        labelText: 'Character/Role',
                        prefixIcon: Icon(Icons.psychology),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Assistant, Doctor, Teacher',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a character/role';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _scenarioController,
                      decoration: InputDecoration(
                        labelText: 'Scenario',
                        prefixIcon: Icon(Icons.settings_applications),
                        border: OutlineInputBorder(),
                        hintText: 'Character scenario context',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _firstMessageController,
                      decoration: InputDecoration(
                        labelText: 'First Message',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                        border: OutlineInputBorder(),
                        hintText: 'Opening message from character',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _messageExampleController,
                      decoration: InputDecoration(
                        labelText: 'Message Example',
                        prefixIcon: Icon(Icons.format_quote),
                        border: OutlineInputBorder(),
                        hintText: 'Example conversation',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _creatorCommentController,
                      decoration: InputDecoration(
                        labelText: 'Creator Comment',
                        prefixIcon: Icon(Icons.comment),
                        border: OutlineInputBorder(),
                        hintText: 'Notes from creator',
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _avatarController,
                      decoration: InputDecoration(
                        labelText: 'Avatar',
                        prefixIcon: Icon(Icons.face),
                        border: OutlineInputBorder(),
                        hintText: 'Avatar description or URL',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Tags',
                        prefixIcon: Icon(Icons.local_offer),
                        border: OutlineInputBorder(),
                        hintText: 'Comma-separated tags',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(onPressed: _import, child: Text('Import')),
      ],
    );
  }
}
