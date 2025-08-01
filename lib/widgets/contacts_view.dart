import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String character;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.character,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'character': character,
    };
  }

  static Contact fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      character: json['character'],
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

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  _ContactsViewState createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  List<Contact> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList('contacts') ?? [];

    setState(() {
      contacts = contactsJson
          .map((jsonString) => Contact.fromJson(json.decode(jsonString)))
          .toList();
      isLoading = false;
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = contacts
        .map((contact) => json.encode(contact.toJson()))
        .toList();
    await prefs.setStringList('contacts', contactsJson);
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => ContactDialog(
        onSave: (contact) {
          setState(() {
            contacts.add(contact);
          });
          _saveContacts();
        },
      ),
    );
  }

  Future<void> _importCharacterCard() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Reading character card...'),
              ],
            ),
          ),
        );

        final metadata = await _extractPngMetadata(bytes);
        Navigator.pop(context); // Close loading dialog

        if (metadata.isNotEmpty) {
          _showMetadataDialog(metadata, result.files.single.name);
        } else {
          _showErrorDialog('No metadata found in the PNG file.');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      _showErrorDialog('Error reading file: $e');
    }
  }

  Future<Map<String, String>> _extractPngMetadata(Uint8List bytes) async {
    final metadata = <String, String>{};

    try {
      final image = img.decodePng(bytes);
      if (image != null) {
        for (final chunk in image.textData!.entries) {
          String value = chunk.value;
          try {
            final decoded = utf8.decode(base64.decode(value));
            metadata[chunk.key] = decoded;
          } catch (e) {
            // If base64 decoding fails, use original value
            metadata[chunk.key] = value;
          }
        }
      }
    } catch (e) {
      print('Error decoding PNG: $e');
    }

    return metadata;
  }

  void _showMetadataDialog(Map<String, String> metadata, String filename) {
    showDialog(
      context: context,
      builder: (context) => CharacterCardMetadataDialog(
        metadata: metadata,
        filename: filename,
        onImport: (contact) {
          setState(() {
            contacts.add(contact);
          });
          _saveContacts();
        },
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editContact(Contact contact, int index) {
    showDialog(
      context: context,
      builder: (context) => ContactDialog(
        contact: contact,
        onSave: (updatedContact) {
          setState(() {
            contacts[index] = updatedContact;
          });
          _saveContacts();
        },
      ),
    );
  }

  void _deleteContact(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Contact'),
        content: Text(
          'Are you sure you want to delete ${contacts[index].name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                contacts.removeAt(index);
              });
              _saveContacts();
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _callContact(Contact contact) {
    // Here you would integrate with your phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${contact.name} (${contact.character})...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add':
                  _addContact();
                  break;
                case 'import':
                  _importCharacterCard();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add Contact'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.image),
                    SizedBox(width: 8),
                    Text('Import Character Card'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: contacts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ContactCard(
            contact: contact,
            onCall: () => _callContact(contact),
            onEdit: () => _editContact(contact, index),
            onDelete: () => _deleteContact(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: Icon(Icons.add),
        tooltip: 'Add Contact',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No contacts yet',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first AI contact',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _addContact,
                icon: Icon(Icons.add),
                label: Text('Add Contact'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _importCharacterCard,
                icon: Icon(Icons.image),
                label: Text('Import Card'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _parseMetadata();
  }

  void _parseMetadata() {
    // Try to extract character information from common metadata fields
    String characterData = '';
    String characterName = '';

    // Common character card metadata keys
    final possibleKeys = [
      'chara', 'character', 'Character', 'CHARA',
      'Description', 'description', 'DESC',
      'tEXt', 'Comment', 'comment'
    ];

    for (final key in possibleKeys) {
      if (widget.metadata.containsKey(key)) {
        characterData = widget.metadata[key] ?? '';
        break;
      }
    }

    // Try to parse JSON if the metadata contains character data
    if (characterData.isNotEmpty) {
      try {
        final decoded = json.decode(characterData);
        if (decoded is Map<String, dynamic>) {
          characterName = decoded['name'] ?? decoded['char_name'] ?? '';
          final description = decoded['description'] ?? decoded['personality'] ?? '';

          _nameController.text = characterName;
          _characterController.text = description.length > 100
              ? description.substring(0, 100) + '...'
              : description;
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
      final nameFromFile = widget.filename.replaceAll('.png', '').replaceAll('_', ' ');
      _nameController.text = nameFromFile;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  void _import() {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        character: _characterController.text.trim(),
      );
      widget.onImport(contact);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Import Character Card'),
      content: SingleChildScrollView(
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
                ],
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
        ElevatedButton(
          onPressed: _import,
          child: Text('Import'),
        ),
      ],
    );
  }
}

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            contact.initials,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                contact.character,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'call':
                onCall();
                break;
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'call',
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Call'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: onCall,
      ),
    );
  }
}

class ContactDialog extends StatefulWidget {
  final Contact? contact;
  final Function(Contact) onSave;

  const ContactDialog({super.key, this.contact, required this.onSave});

  @override
  _ContactDialogState createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _characterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
      _characterController.text = widget.contact!.character;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id:
        widget.contact?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        character: _characterController.text.trim(),
      );
      widget.onSave(contact);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a character/role';
                }
                return null;
              },
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
}