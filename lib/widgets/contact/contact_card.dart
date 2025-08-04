import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/contact.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onCall;
  final VoidCallback onSms;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onSms,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildAvatar() {
    if (contact.avatar.isNotEmpty) {
      // Check if it's a file path
      if (contact.avatar.startsWith('/') ||
          contact.avatar.startsWith('file://')) {
        return CircleAvatar(
          backgroundImage: FileImage(File(contact.avatar)),
          onBackgroundImageError: (exception, stackTrace) {
            // If image fails to load, fall back to initials
          },
          child: contact.avatar.isEmpty
              ? Text(
                  contact.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      }
      // Check if it's an asset path
      else if (contact.avatar.startsWith('assets/')) {
        return CircleAvatar(
          backgroundImage: AssetImage(contact.avatar),
          onBackgroundImageError: (exception, stackTrace) {
            // If image fails to load, fall back to initials
          },
          child: contact.avatar.isEmpty
              ? Text(
                  contact.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      }
    }

    // Default: show initials with blue background
    return CircleAvatar(
      backgroundColor: Colors.blue,
      child: Text(
        contact.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildAvatar(),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            const SizedBox(height: 2),
            if (contact.description.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  contact.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (contact.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: contact.tags
                    .take(3)
                    .map(
                      (tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 10)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'call':
                onCall();
                break;
              case 'sms':
                onSms();
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
            const PopupMenuItem(
              value: 'call',
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Call'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sms',
              child: Row(
                children: [
                  Icon(Icons.message, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('SMS'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
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
