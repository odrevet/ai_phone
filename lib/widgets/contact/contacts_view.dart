import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/contact.dart';
import 'character_card_metadata_dialog.dart';
import 'contact_card.dart';
import 'contact_dialog.dart';

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
          final decoded = utf8.decode(base64.decode(value));
          metadata[chunk.key] = decoded;
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
