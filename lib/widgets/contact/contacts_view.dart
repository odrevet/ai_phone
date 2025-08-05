import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/contact.dart';
import 'character_card_metadata_dialog.dart';
import 'contact_card.dart';
import 'contact_dialog.dart';

class ContactsView extends StatefulWidget {
  final Function(Contact)? onContactCall;
  final Function(Contact)? onContactSms;

  const ContactsView({super.key, this.onContactCall, this.onContactSms});

  @override
  State<ContactsView> createState() => _ContactsViewState();
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

  Future<String?> _copyImageToAppDirectory(
    File sourceFile,
    String contactId,
  ) async {
    try {
      // Get the app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      // Create avatars subdirectory if it doesn't exist
      final Directory avatarsDir = Directory(
        path.join(appDocDir.path, 'avatars'),
      );
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      // Generate a unique filename using contact ID and timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(sourceFile.path);
      final String fileName = '${contactId}_$timestamp$extension';
      final String destinationPath = path.join(avatarsDir.path, fileName);

      // Copy the file
      final File destinationFile = await sourceFile.copy(destinationPath);

      return destinationFile.path;
    } catch (e) {
      developer.log('Error copying image to app directory: $e');
      return null;
    }
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

        if (!mounted) return;

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

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (metadata.isNotEmpty) {
          // Generate a temporary contact ID for the avatar file
          final String tempContactId = DateTime.now().millisecondsSinceEpoch
              .toString();

          // Copy the PNG file to app directory
          final String? avatarPath = await _copyImageToAppDirectory(
            file,
            tempContactId,
          );

          _showMetadataDialog(metadata, result.files.single.name, avatarPath);
        } else {
          _showErrorDialog('No metadata found in the PNG file.');
        }
      }
    } catch (e) {
      if (!mounted) return;
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
          final decoded = utf8.decode(base64.decode(value));
          metadata[chunk.key] = decoded;
        }
      }
    } catch (e) {
      developer.log('Error decoding PNG: $e');
    }

    return metadata;
  }

  void _showMetadataDialog(
    Map<String, String> metadata,
    String filename,
    String? avatarPath,
  ) {
    showDialog(
      context: context,
      builder: (context) => CharacterCardMetadataDialog(
        metadata: metadata,
        filename: filename,
        avatarPath: avatarPath, // Pass the avatar path to the dialog
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
    final contact = contacts[index];

    showDialog(
      context: context,
      builder: (contextDialog) => AlertDialog(
        title: Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialog),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Delete the avatar file if it exists and is in app directory
              if (contact.avatar.isNotEmpty &&
                  (contact.avatar.contains('/avatars/') ||
                      contact.avatar.startsWith('/'))) {
                try {
                  final file = File(contact.avatar);
                  if (await file.exists()) {
                    await file.delete();
                  }
                } catch (e) {
                  developer.log('Error deleting avatar file: $e');
                }
              }

              setState(() {
                contacts.removeAt(index);
              });
              _saveContacts();

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
                  onCall: () {
                    if (widget.onContactCall != null) {
                      widget.onContactCall!(contact);
                    }
                  },
                  onSms: () {
                    if (widget.onContactSms != null) {
                      widget.onContactSms!(contact);
                    }
                  },
                  onEdit: () => _editContact(contact, index),
                  onDelete: () => _deleteContact(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        tooltip: 'Add Contact',
        child: Icon(Icons.add),
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
