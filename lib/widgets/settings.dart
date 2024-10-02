import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _openAIController = TextEditingController();
  final TextEditingController _allTalkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _openAIController.text = prefs.getString('openai_api_address') ?? '';
      _allTalkController.text =
          prefs.getString('alltalk_tts_api_address') ?? '';
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_address', _openAIController.text);
    await prefs.setString('alltalk_tts_api_address', _allTalkController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OpenAI API Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _openAIController,
              decoration: InputDecoration(
                hintText: 'Enter OpenAI API address',
              ),
            ),
            SizedBox(height: 20),
            Text('AllTalk TTS API Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _allTalkController,
              decoration: InputDecoration(
                hintText: 'Enter AllTalk TTS API address',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _openAIController.dispose();
    _allTalkController.dispose();
    super.dispose();
  }
}
