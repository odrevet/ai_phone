import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../api.dart';

class PhoneView extends StatefulWidget {
  final List<Map<String, String>> conversationHistory;
  final Function addConversation;

  const PhoneView({
    super.key,
    required this.conversationHistory,
    required this.addConversation,
  });

  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> {
  // Debug variable - set to true to show debug controls
  bool debug = false;

  bool _hasSpeech = false;
  final bool _logEvents = false;
  bool _onDevice = false;
  final TextEditingController _pauseForController = TextEditingController(
    text: '3',
  );
  final TextEditingController _listenForController = TextEditingController(
    text: '30',
  );
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  Future<void> _loadDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      debug = prefs.getBool('debug_mode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              //const HeaderWidget(),
              const SizedBox(height: 20),

              // Debug controls section
              if (debug) ...[
                SpeechControlWidget(
                  _hasSpeech,
                  speech.isListening,
                  startListening,
                  stopListening,
                  cancelListening,
                ),
                const SizedBox(height: 16),
                SessionOptionsWidget(
                  _currentLocaleId,
                  _switchLang,
                  _localeNames,
                  _logEvents,
                  _pauseForController,
                  _listenForController,
                  _onDevice,
                  _switchOnDevice,
                ),
                const SizedBox(height: 16),
              ],

              // Debug container - show only when debug is true
              if (debug) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lastWords.isEmpty ? 'No speech detected yet...' : lastWords,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Main phone button - centered and expandable
              Expanded(
                child: Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: speech.isListening ? Colors.green : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          spreadRadius: level * 2,
                          color:
                              (speech.isListening ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.3),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(80),
                        onTap: !_hasSpeech || speech.isListening
                            ? null
                            : startListening,
                        child: const Icon(
                          Icons.phone,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Error display at bottom
              if (lastError.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SelectableText(
                    lastError,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> initSpeechState() async {
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: _logEvents,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initSpeechState();
    _loadDebugMode();
  }

  // This is called each time the users wants to start a new speech
  void startListening() {
    lastWords = '';
    lastError = '';
    final pauseFor = int.tryParse(_pauseForController.text);
    final listenFor = int.tryParse(_listenForController.text);
    final options = SpeechListenOptions(
      onDevice: _onDevice,
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
      partialResults: true,
      autoPunctuation: true,
      enableHapticFeedback: true,
    );
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: listenFor ?? 30),
      pauseFor: Duration(seconds: pauseFor ?? 3),
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      listenOptions: options,
    );
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  void playAudio(dynamic data) async {
    final player = AudioPlayer();
    await player.play(BytesSource(data));
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  Future<void> resultListener(SpeechRecognitionResult result) async {
    setState(() {
      lastWords = result.recognizedWords;
    });

    if (result.finalResult) {
      await widget.addConversation("user", result.recognizedWords);

      sendChatCompletion(widget.conversationHistory)
          .then((response) async {
            String messageContent =
                response['choices'][0]['message']['content'];

            await widget.addConversation("assistant", messageContent);

            setState(() {
              lastWords += messageContent;
            });

            // Remove <think></think> blocks with their content
            messageContent = messageContent.replaceAll(
              RegExp(r'<think>.*?</think>', dotAll: true),
              '',
            );

            // Remove emoticons (basic emoji characters)
            // This regex matches most common Unicode emoji ranges
            messageContent = messageContent.replaceAll(
              RegExp(
                r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
                unicode: true,
              ),
              '',
            );

            // Remove text-based emoticons like :), :D, :(, etc.
            messageContent = messageContent.replaceAll(
              RegExp(r'[:;=]-?[)(\]\[dDoOpP\/\\|*$@]'),
              '',
            );

            // dynamic data supposed to be Uint8List but import error
            sendTtsGenerateRequest(messageContent)
                .then((dynamic data) {
                  if (data != null) {
                    playAudio(data);
                  }
                })
                .catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $error')),
                  );
                });
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('An error occurred: $error')),
            );
          });
    }
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = status;
    });
  }

  void _switchLang(String? selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal!;
    });
  }

  void _switchOnDevice(bool? val) {
    setState(() {
      _onDevice = val ?? false;
    });
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Speech recognition available',
        style: TextStyle(fontSize: 22.0),
      ),
    );
  }
}

/// Display the current error status from the speech
/// recognizer
class ErrorWidget extends StatelessWidget {
  const ErrorWidget({super.key, required this.lastError});

  final String lastError;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Empty widget since errors are now handled in main build
  }
}

/// Controls to start and stop speech recognition
class SpeechControlWidget extends StatelessWidget {
  const SpeechControlWidget(
    this.hasSpeech,
    this.isListening,
    this.startListening,
    this.stopListening,
    this.cancelListening, {
    //this.clearConversation,
    super.key,
  });

  final bool hasSpeech;
  final bool isListening;
  final void Function() startListening;
  final void Function() stopListening;
  final void Function() cancelListening;

  //final void Function() clearConversation;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: !hasSpeech || isListening ? null : startListening,
          child: const Text('Start'),
        ),
        TextButton(
          onPressed: isListening ? stopListening : null,
          child: const Text('Stop'),
        ),
        TextButton(
          onPressed: isListening ? cancelListening : null,
          child: const Text('Cancel'),
        ),
        /*TextButton(
          onPressed: clearConversation,
          child: const Text('Clear'),
        )*/
      ],
    );
  }
}

class SessionOptionsWidget extends StatelessWidget {
  const SessionOptionsWidget(
    this.currentLocaleId,
    this.switchLang,
    this.localeNames,
    this.logEvents,
    this.pauseForController,
    this.listenForController,
    this.onDevice,
    this.switchOnDevice, {
    super.key,
  });

  final String currentLocaleId;
  final void Function(String?) switchLang;
  final void Function(bool?) switchOnDevice;
  final TextEditingController pauseForController;
  final TextEditingController listenForController;
  final List<LocaleName> localeNames;
  final bool logEvents;
  final bool onDevice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              const Text('Language: '),
              DropdownButton<String>(
                onChanged: (selectedVal) => switchLang(selectedVal),
                value: currentLocaleId,
                items: localeNames
                    .map(
                      (localeName) => DropdownMenuItem(
                        value: localeName.localeId,
                        child: Text(localeName.name),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Row(
            children: [
              const Text('pauseFor: '),
              Container(
                padding: const EdgeInsets.only(left: 8),
                width: 80,
                child: TextFormField(controller: pauseForController),
              ),
              Container(
                padding: const EdgeInsets.only(left: 16),
                child: const Text('listenFor: '),
              ),
              Container(
                padding: const EdgeInsets.only(left: 8),
                width: 80,
                child: TextFormField(controller: listenForController),
              ),
            ],
          ),
          Row(
            children: [
              const Text('On device: '),
              Checkbox(value: onDevice, onChanged: switchOnDevice),
            ],
          ),
        ],
      ),
    );
  }
}

class InitSpeechWidget extends StatelessWidget {
  const InitSpeechWidget(this.hasSpeech, this.initSpeechState, {super.key});

  final bool hasSpeech;
  final Future<void> Function() initSpeechState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: hasSpeech ? null : initSpeechState,
          child: const Text('Initialize'),
        ),
      ],
    );
  }
}
