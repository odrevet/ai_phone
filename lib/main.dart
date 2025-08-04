import 'package:ai_phone/models/contact.dart';
import 'package:ai_phone/widgets/contact/contact_avatar.dart';
import 'package:ai_phone/widgets/contact/contacts_view.dart';
import 'package:ai_phone/widgets/phone_view.dart';
import 'package:ai_phone/widgets/settings.dart';
import 'package:ai_phone/widgets/sms_view.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/message.dart';

void main() => runApp(const AiPhone());

class AiPhone extends StatefulWidget {
  const AiPhone({super.key});

  @override
  State<AiPhone> createState() => _AiPhoneState();
}

class _AiPhoneState extends State<AiPhone> {
  Contact? _currentContact;
  int _selectedIndex = 0; // menu tab index

  @override
  void initState() {
    super.initState();
  }

  void _smsContact(Contact contact) {
    setCurrentContact(contact, isSms: true);
  }

  void _callContact(Contact contact) {
    setCurrentContact(contact, isCall: true);
  }

  // Set the current contact and switch to appropriate view
  void setCurrentContact(
    Contact contact, {
    bool isCall = false,
    bool isSms = false,
  }) {
    setState(() {
      _currentContact = contact;

      // Switch to the appropriate view - ensure only one is true
      if (isCall) {
        _selectedIndex = 0; // Phone view
      } else if (isSms) {
        _selectedIndex = 1; // SMS view
      }
      // If neither isCall nor isSms is true, stay on current view
    });
  }

  void addMessageToConversation(String role, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final disableThinking = prefs.getBool('disable_thinking') ?? true;

    setState(() {
      if (disableThinking) {
        content += ' /no_think';
      }

      if (_currentContact != null) {
        _currentContact!.conversation.addMessage(
          Message(role: role, content: content),
        );
      }
    });
  }

  void clearConversation() {}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetOptions = <Widget>[
      PhoneView(
        addMessageToConversation: addMessageToConversation,
        currentContact: _currentContact,
        clearConversation: clearConversation,
      ),
      SMSView(
        //addMessageToConversation: addMessageToConversation,
        currentContact: _currentContact,
        clearConversation: clearConversation,
      ),
      ContactsView(
        onContactCall: (contact) => _callContact(contact),
        onContactSms: (contact) => _smsContact(contact),
      ),
      Settings(),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: _currentContact != null
            ? AppBar(
                title: Row(
                  children: [
                    ContactAvatar(
                      contact: _currentContact!,
                      radius: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentContact!.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _currentContact!.phoneNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _currentContact = null;
                      });
                    },
                    tooltip: 'Clear current contact',
                  ),
                ],
              )
            : null,
        body: widgetOptions[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Phone'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'SMS'),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
