//import 'package:ai_phone/widgets/contacts_view.dart';
import 'package:ai_phone/widgets/phone_view.dart';
import 'package:ai_phone/widgets/settings.dart';
import 'package:ai_phone/widgets/sms_view.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SpeechSampleApp());

class SpeechSampleApp extends StatefulWidget {
  const SpeechSampleApp({super.key});

  @override
  State<SpeechSampleApp> createState() => _SpeechSampleAppState();
}

class _SpeechSampleAppState extends State<SpeechSampleApp> {
  //List<Map<String, String>> conversationHistory = [];
  final List<Map<String, String>> conversationHistory = [
    {"role": "system", "content": "give short answers"},
  ];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void addConversation(String role, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final disableThinking = prefs.getBool('disable_thinking') ?? true;

    setState(() {
      if (disableThinking) {
        content += ' /no_think';
      }
      conversationHistory.add({"role": role, "content": content});
    });
  }

  void clearConversation() {
    setState(() {
      conversationHistory.clear();
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
        conversationHistory: conversationHistory,
        addConversation: addConversation,
      ),
      SMSView(
        conversationHistory: conversationHistory,
        addConversation: addConversation,
      ),
      //ContactsView(),
      Settings(),
    ];

    return MaterialApp(
      home: Scaffold(
        body: widgetOptions[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Phone'),
            BottomNavigationBarItem(icon: Icon(Icons.message), label: 'SMS'),
            /*BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Contacts',
            ),*/
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'settings',
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
