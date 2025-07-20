import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _openAIController = TextEditingController();
  final TextEditingController _ttsController = TextEditingController();
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _openAIController.text = prefs.getString('openai_api_address') ?? '';
      _ttsController.text = prefs.getString('tts_api_address') ?? '';
      _debugMode = prefs.getBool('debug_mode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_address', _openAIController.text);
    await prefs.setString('tts_api_address', _ttsController.text);
    await prefs.setBool('debug_mode', _debugMode);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OpenAI API Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _openAIController,
              decoration: InputDecoration(hintText: 'Enter OpenAI API address'),
            ),
            SizedBox(height: 20),
            Text(
              'TTS API Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _ttsController,
              decoration: InputDecoration(hintText: 'Enter TTS API address'),
            ),
            SizedBox(height: 20),
            Text(
              'Debug Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CheckboxListTile(
              title: Text('Enable Debug Mode'),
              subtitle: Text('Show additional controls and debug information'),
              value: _debugMode,
              onChanged: (bool? value) {
                setState(() {
                  _debugMode = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
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
    _ttsController.dispose();
    super.dispose();
  }
}
