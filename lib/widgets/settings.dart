import 'dart:async';

import 'package:ai_phone/api.dart';
import 'package:ai_phone/tts.dart';
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
  final TextEditingController _generationModelController =
      TextEditingController();
  final TextEditingController _voiceController = TextEditingController();
  final TextEditingController _apiKeyGenerationController =
      TextEditingController();
  final TextEditingController _apiKeyTtsController = TextEditingController();
  bool _debugMode = false;
  bool _disableThinking = true; // Default to true (disabled)
  bool _automaticListen = true; // Default to true (enabled)
  String _ttsEngine = ttsEngineDevice;
  List<String> _availableModels = [];
  bool _testingApi = false;
  String? _testError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _openAIController.text = prefs.getString('openai_api_address') ?? '';
      final ttsAddress = prefs.getString('tts_api_address') ?? '';
      _ttsController.text = ttsAddress;
      _ttsEngine = resolveTtsEngine(prefs.getString('tts_engine'), ttsAddress);
      _generationModelController.text =
          prefs.getString('generation_model') ?? '';
      _voiceController.text = prefs.getString('voice') ?? '';
      _apiKeyGenerationController.text =
          prefs.getString('api_key_generation') ?? '';
      _apiKeyTtsController.text = prefs.getString('api_key_tts') ?? '';
      _availableModels = prefs.getStringList('generation_models') ?? [];
      _debugMode = prefs.getBool('debug_mode') ?? false;
      _disableThinking = prefs.getBool('disable_thinking') ?? true;
      _automaticListen = prefs.getBool('automatic_listen') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_address', _openAIController.text.trim());
    await prefs.setString('tts_api_address', _ttsController.text.trim());
    await prefs.setString('tts_engine', _ttsEngine);
    await prefs.setString(
      'generation_model',
      _generationModelController.text.trim(),
    );
    await prefs.setString('voice', _voiceController.text.trim());
    await prefs.setString(
      'api_key_generation',
      _apiKeyGenerationController.text.trim(),
    );
    await prefs.setString('api_key_tts', _apiKeyTtsController.text.trim());
    await prefs.setStringList('generation_models', _availableModels);
    await prefs.setBool('debug_mode', _debugMode);
    await prefs.setBool('disable_thinking', _disableThinking);
    await prefs.setBool('automatic_listen', _automaticListen);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Settings saved')));
  }

  Future<void> _testApi() async {
    FocusScope.of(context).unfocus();
    final apiAddress = _openAIController.text.trim();
    if (apiAddress.isEmpty) {
      setState(() {
        _testError = 'Enter an API address first.';
        _availableModels = [];
      });
      return;
    }

    setState(() {
      _testingApi = true;
      _testError = null;
    });

    try {
      final models = await fetchModels(
        apiAddress: apiAddress,
        apiKey: _apiKeyGenerationController.text,
      );
      if (!mounted) return;
      setState(() {
        _availableModels = models;
        if (models.isEmpty) {
          _testError = 'Connection succeeded but no models were returned.';
        } else if (_generationModelController.text.trim().isEmpty) {
          _generationModelController.text = models.first;
        }
      });
      if (models.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection successful, ${models.length} model(s) found',
            ),
          ),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _availableModels = [];
        _testError = 'Connection timed out. Check the API address.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableModels = [];
        _testError = _describeError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _testingApi = false;
        });
      }
    }
  }

  String _describeError(Object error) {
    var message = error.toString();
    for (final prefix in const [
      'Exception: ',
      'ClientException: ',
      'SocketException: ',
    ]) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length);
        break;
      }
    }
    return message.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _openAIController,
                          keyboardType: TextInputType.url,
                          onChanged: (_) {
                            if (_testError != null) {
                              setState(() {
                                _testError = null;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter generation API address',
                            errorText: _testError,
                            errorMaxLines: 3,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _testingApi ? null : _testApi,
                          icon: _testingApi
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.wifi_tethering),
                          label: Text(_testingApi ? 'Testing...' : 'Test'),
                        ),
                      ),
                    ],
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
                  DropdownMenu<String>(
                    controller: _generationModelController,
                    expandedInsets: EdgeInsets.zero,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    menuHeight: 300,
                    hintText: _availableModels.isEmpty
                        ? 'Test the API address to load models'
                        : 'Select a model',
                    helperText: _availableModels.isEmpty
                        ? null
                        : '${_availableModels.length} model(s) available',
                    dropdownMenuEntries: _availableModels
                        .map(
                          (model) => DropdownMenuEntry<String>(
                            value: model,
                            label: model,
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 30),

                  // TTS Section
                  Text(
                    'Text-to-Speech (TTS)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Engine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: ttsEngineDevice,
                        icon: Icon(Icons.smartphone),
                        label: Text('Phone'),
                      ),
                      ButtonSegment(
                        value: ttsEngineApi,
                        icon: Icon(Icons.cloud_outlined),
                        label: Text('API endpoint'),
                      ),
                    ],
                    selected: {_ttsEngine},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _ttsEngine = selection.first;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  Text(
                    _ttsEngine == ttsEngineDevice
                        ? "Reads AI responses with your phone's built-in "
                              'text-to-speech engine.'
                        : 'Reads AI responses with an OpenAI-compatible '
                              '/v1/audio/speech endpoint.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_ttsEngine == ttsEngineApi) ...[
                    SizedBox(height: 20),
                    Text(
                      'API Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _ttsController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'Enter TTS API address',
                        helperText:
                            'Optional. Leave empty to use the phone engine.',
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'API Key',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _voiceController,
                      decoration: InputDecoration(
                        hintText: 'Enter a voice (e.g., alloy, nova)',
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text('Automatic Listen'),
                    subtitle: Text(
                      'Automatically start listening after TTS playback ends',
                    ),
                    value: _automaticListen,
                    onChanged: (bool? value) {
                      setState(() {
                        _automaticListen = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
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
                    subtitle: Text(
                      'Show additional controls and debug information',
                    ),
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
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Save Settings', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
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
