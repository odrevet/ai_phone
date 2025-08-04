import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/contact.dart';

class ContactAvatar extends StatelessWidget {
  final Contact contact;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;

  const ContactAvatar({
    super.key,
    required this.contact,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (contact.avatar.isNotEmpty) {
      // Check if it's a file path
      if (contact.avatar.startsWith('/') ||
          contact.avatar.startsWith('file://')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(File(contact.avatar)),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Failed to load file avatar: $exception');
          },
        );
      }
      // Check if it's a network URL
      else if (contact.avatar.startsWith('http://') ||
          contact.avatar.startsWith('https://')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(contact.avatar),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Failed to load network avatar: $exception');
          },
        );
      }
      // Check if it's an asset path
      else if (contact.avatar.startsWith('assets/')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: AssetImage(contact.avatar),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Failed to load asset avatar: $exception');
          },
        );
      }
      // Handle base64 encoded images
      else if (contact.avatar.startsWith('data:image/')) {
        try {
          final bytes = Uri.parse(contact.avatar).data!.contentAsBytes();
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Failed to load base64 avatar: $exception');
            },
          );
        } catch (e) {
          debugPrint('Failed to parse base64 avatar: $e');
          // Fall through to default initials
        }
      }
    }

    // Default: show initials with colored background
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.blue,
      child: Text(
        contact.initials,
        style: TextStyle(
          color: foregroundColor ?? Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize ?? (radius * 0.7),
        ),
      ),
    );
  }
}
