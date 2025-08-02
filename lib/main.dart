import 'package:ai_phone/models/contact.dart';
import 'package:ai_phone/widgets/contact/contacts_view.dart';
import 'package:ai_phone/widgets/phone_view.dart';
import 'package:ai_phone/widgets/settings.dart';
import 'package:ai_phone/widgets/sms_view.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AiPhone());

class AiPhone extends StatefulWidget {
  const AiPhone({super.key});

  @override
  State<AiPhone> createState() => _AiPhoneState();
}

class _AiPhoneState extends State<AiPhone> {
  final List<Map<String, String>> conversationHistory = [
    {"role": "system", "content": "give short answers"},
  ];

  // Current selected contact and contact-specific conversation histories
  Contact? _currentContact;
  final Map<String, List<Map<String, String>>> _contactConversations = {};

  int _selectedIndex = 0;

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

      // Initialize conversation history for this contact if it doesn't exist
      if (!_contactConversations.containsKey(contact.id)) {
        _contactConversations[contact.id] = [
          {"role": "system", "content": "give short answers"},
          if (contact.description.isNotEmpty)
            {"role": "assistant", "content": contact.description},
          if (contact.personality.isNotEmpty)
            {"role": "assistant", "content": contact.personality},
          if (contact.firstMessage.isNotEmpty)
            {"role": "assistant", "content": contact.firstMessage},
        ];
      }

      // Switch to the appropriate view - ensure only one is true
      if (isCall) {
        _selectedIndex = 0; // Phone view
      } else if (isSms) {
        _selectedIndex = 1; // SMS view
      }
      // If neither isCall nor isSms is true, stay on current view
    });
  }

  // Get conversation history for current contact
  List<Map<String, String>> getCurrentContactConversation() {
    if (_currentContact == null) return conversationHistory;
    return _contactConversations[_currentContact!.id] ?? conversationHistory;
  }

  void addConversation(String role, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final disableThinking = prefs.getBool('disable_thinking') ?? true;

    setState(() {
      if (disableThinking) {
        content += ' /no_think';
      }

      if (_currentContact != null) {
        // Add to current contact's conversation
        if (!_contactConversations.containsKey(_currentContact!.id)) {
          _contactConversations[_currentContact!.id] = [
            {"role": "system", "content": "give short answers"},
          ];
        }
        _contactConversations[_currentContact!.id]!.add({
          "role": role,
          "content": content,
        });
      } else {
        // Add to general conversation history
        conversationHistory.add({"role": role, "content": content});
      }
    });
  }

  void clearConversation() {
    setState(() {
      if (_currentContact != null) {
        _contactConversations[_currentContact!.id] = [
          {"role": "system", "content": "give short answers"},
          if (_currentContact!.firstMessage.isNotEmpty)
            {"role": "assistant", "content": _currentContact!.firstMessage},
        ];
      } else {
        conversationHistory.clear();
        conversationHistory.add({
          "role": "system",
          "content": "give short answers",
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetOptions = <Widget>[
      PhoneView(
        conversationHistory: getCurrentContactConversation(),
        addConversation: addConversation,
        currentContact: _currentContact,
        clearConversation: clearConversation,
      ),
      SMSView(
        conversationHistory: getCurrentContactConversation(),
        addConversation: addConversation,
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
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 16,
                      child: Text(
                        _currentContact!.initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
