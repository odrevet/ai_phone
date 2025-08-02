import 'package:flutter/material.dart';

import '../../models/contact.dart';

class ContactDialog extends StatefulWidget {
  final Contact? contact;
  final Function(Contact) onSave;

  const ContactDialog({super.key, this.contact, required this.onSave});

  @override
  _ContactDialogState createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog>
    with SingleTickerProviderStateMixin {
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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
      _characterController.text = widget.contact!.character;
      _scenarioController.text = widget.contact!.scenario;
      _firstMessageController.text = widget.contact!.firstMessage;
      _messageExampleController.text = widget.contact!.messageExample;
      _creatorCommentController.text = widget.contact!.creatorComment;
      _avatarController.text = widget.contact!.avatar;
      _chatController.text = widget.contact!.chat;
      _tagsController.text = widget.contact!.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _save() {
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
        id:
            widget.contact?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
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
        data: widget.contact?.data ?? {},
      );
      widget.onSave(contact);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Basic Info'),
                Tab(text: 'Character Details'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildBasicInfoTab(), _buildCharacterDetailsTab()],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: Text('Save')),
      ],
    );
  }

  Widget _buildBasicInfoTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }
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
    );
  }

  Widget _buildCharacterDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: _scenarioController,
            decoration: InputDecoration(
              labelText: 'Scenario',
              prefixIcon: Icon(Icons.settings_applications),
              border: OutlineInputBorder(),
              hintText: 'Character scenario context',
            ),
            maxLines: 3,
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
            maxLines: 3,
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
            maxLines: 3,
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
            controller: _chatController,
            decoration: InputDecoration(
              labelText: 'Chat',
              prefixIcon: Icon(Icons.chat),
              border: OutlineInputBorder(),
              hintText: 'Chat information',
            ),
          ),
        ],
      ),
    );
  }
}
