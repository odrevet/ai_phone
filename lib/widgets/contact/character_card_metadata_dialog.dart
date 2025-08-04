import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/contact.dart';

class CharacterCardMetadataDialog extends StatefulWidget {
  final Map<String, String> metadata;
  final String filename;
  final String? avatarPath; // Added avatar path parameter
  final Function(Contact) onImport;

  const CharacterCardMetadataDialog({
    super.key,
    required this.metadata,
    required this.filename,
    this.avatarPath, // Added avatar path parameter
    required this.onImport,
  });

  @override
  CharacterCardMetadataDialogState createState() =>
      CharacterCardMetadataDialogState();
}

class CharacterCardMetadataDialogState
    extends State<CharacterCardMetadataDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personalityController = TextEditingController();
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
        final charaDecoded = json.decode(characterData);
        final dataDecoded = charaDecoded['data'];
        characterName = dataDecoded['name'] ?? '';
        final description = dataDecoded['description'] ?? '';
        final personality = dataDecoded['personality'] ?? '';
        final scenario = dataDecoded['scenario'] ?? '';
        final firstMes = dataDecoded['first_mes'] ?? '';
        final mesExample = dataDecoded['mes_example'] ?? '';
        final creatorComment =
            dataDecoded['creatorcomment'] ?? dataDecoded['creator_notes'] ?? '';
        final avatar = dataDecoded['avatar'] ?? '';
        final chat = dataDecoded['chat'] ?? '';
        final tags = dataDecoded['tags'] ?? [];

        _nameController.text = characterName;
        _descriptionController.text = description.length > 100
            ? description.substring(0, 100) + '...'
            : description;
        _personalityController.text = personality; // Handle personality field
        _scenarioController.text = scenario;
        _firstMessageController.text = firstMes;
        _messageExampleController.text = mesExample;
        _creatorCommentController.text = creatorComment;
        _chatController.text = chat;

        if (tags is List) {
          _tagsController.text = tags.join(', ');
        }
      } catch (e) {
        developer.log("ERROR: $e");
      }
    }

    // If no name was found, use filename
    if (_nameController.text.isEmpty) {
      final nameFromFile = widget.filename
          .replaceAll('.png', '')
          .replaceAll('_', ' ');
      _nameController.text = nameFromFile;
    }

    // Set the avatar path from the copied file
    if (widget.avatarPath != null && widget.avatarPath!.isNotEmpty) {
      _avatarController.text = widget.avatarPath!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
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
        description: _descriptionController.text.trim(),
        personality: _personalityController.text.trim(),
        scenario: _scenarioController.text.trim(),
        firstMessage: _firstMessageController.text.trim(),
        messageExample: _messageExampleController.text.trim(),
        creatorComment: _creatorCommentController.text.trim(),
        avatar: _avatarController.text.trim(), // This will be the copied file path
        chat: _chatController.text.trim(),
        tags: tagsList,
      );
      widget.onImport(contact);
      Navigator.pop(context);
    }
  }

  Widget _buildAvatarPreview() {
    if (widget.avatarPath != null && widget.avatarPath!.isNotEmpty) {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: FileImage(File(widget.avatarPath!)),
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Error loading avatar preview: $exception');
              },
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avatar Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Image will be used as contact avatar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Import Character Card'),
      content: SizedBox(
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
              // Avatar preview section
              _buildAvatarPreview(),
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
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        hintText: 'Character description and background',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    // Added personality field
                    TextFormField(
                      controller: _personalityController,
                      decoration: InputDecoration(
                        labelText: 'Personality',
                        prefixIcon: Icon(Icons.mood),
                        border: OutlineInputBorder(),
                        hintText: 'Character personality traits',
                      ),
                      maxLines: 3,
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
                        labelText: 'Avatar Path',
                        prefixIcon: Icon(Icons.face),
                        border: OutlineInputBorder(),
                        hintText: 'Avatar file path (auto-filled)',
                      ),
                      readOnly: true, // Make it read-only since it's auto-filled
                      style: TextStyle(color: Colors.grey.shade600),
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