import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  final TextEditingController _openAIController = TextEditingController();
  final TextEditingController _ttsController = TextEditingController();
  final TextEditingController _generationModelController = TextEditingController();
  final TextEditingController _voiceController = TextEditingController();
  final TextEditingController _apiKeyGenerationController = TextEditingController();
  final TextEditingController _apiKeyTtsController = TextEditingController();
  bool _debugMode = false;
  bool _disableThinking = true; // Default to true (disabled)

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
      _generationModelController.text = prefs.getString('generation_model') ?? '';
      _voiceController.text = prefs.getString('voice') ?? '';
      _apiKeyGenerationController.text = prefs.getString('api_key_generation') ?? '';
      _apiKeyTtsController.text = prefs.getString('api_key_tts') ?? '';
      _debugMode = prefs.getBool('debug_mode') ?? false;
      _disableThinking = prefs.getBool('disable_thinking') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_address', _openAIController.text);
    await prefs.setString('tts_api_address', _ttsController.text);
    await prefs.setString('generation_model', _generationModelController.text);
    await prefs.setString('voice', _voiceController.text);
    await prefs.setString('api_key_generation', _apiKeyGenerationController.text);
    await prefs.setString('api_key_tts', _apiKeyTtsController.text);
    await prefs.setBool('debug_mode', _debugMode);
    await prefs.setBool('disable_thinking', _disableThinking);
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Generation Section
              Text(
                'Generation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'API Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _openAIController,
                decoration: InputDecoration(hintText: 'Enter generation API address'),
              ),
              SizedBox(height: 20),
              Text(
                'API Key',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _apiKeyGenerationController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter API key for generation service',
                  suffixIcon: Icon(Icons.key),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Model',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _generationModelController,
                decoration: InputDecoration(
                  hintText: 'Enter generation model (e.g., gpt-4, claude-3-sonnet)',
                ),
              ),
              SizedBox(height: 30),

              // TTS Section
              Text(
                'Text-to-Speech (TTS)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'API Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _ttsController,
                decoration: InputDecoration(hintText: 'Enter TTS API address'),
              ),
              SizedBox(height: 20),
              Text(
                'API Key',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _apiKeyTtsController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter API key for TTS service',
                  suffixIcon: Icon(Icons.key),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Voice',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _voiceController,
                decoration: InputDecoration(
                  hintText: 'Enter voice (e.g., alloy)',
                ),
              ),
              SizedBox(height: 30),

              // Miscellaneous Section
              Text(
                'Miscellaneous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              CheckboxListTile(
                title: Text('Disable Thinking'),
                subtitle: Text('Hide thinking process in AI responses'),
                value: _disableThinking,
                onChanged: (bool? value) {
                  setState(() {
                    _disableThinking = value ?? true;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _openAIController.dispose();
    _ttsController.dispose();
    _generationModelController.dispose();
    _voiceController.dispose();
    _apiKeyGenerationController.dispose();
    _apiKeyTtsController.dispose();
    super.dispose();
  }
}