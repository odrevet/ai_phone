import 'dart:async';
import 'dart:math';

import 'package:ai_phone/widgets/speech_to_text/session_option_widget.dart';
import 'package:ai_phone/widgets/speech_to_text/speech_control_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../api.dart';
import '../models/contact.dart';

class PhoneView extends StatefulWidget {
  final Function(String, String) addMessageToConversation;
  final Contact? currentContact;
  final VoidCallback? clearConversation;
  final SpeechToText speech;
  final bool hasSpeech;
  final String currentLocaleId;

  const PhoneView({
    super.key,
    required this.addMessageToConversation,
    this.currentContact,
    this.clearConversation,
    required this.speech,
    required this.hasSpeech,
    required this.currentLocaleId,
  });

  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> {
  // Debug variable - set to true to show debug controls
  bool debug = false;

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

  Future<void> _loadDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      debug = prefs.getBool('debug_mode') ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDebugMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Debug controls section
              if (debug) ...[
                SpeechControlWidget(
                  widget.hasSpeech,
                  widget.speech.isListening,
                  startListening,
                  stopListening,
                  cancelListening,
                ),
                const SizedBox(height: 16),
                SessionOptionsWidget(
                  widget.currentLocaleId,
                      (String? val) {}, // Language switching handled in main settings
                  [], // Empty list since handled in settings
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

              // Main phone button
              Expanded(
                child: Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.speech.isListening ? Colors.green : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          spreadRadius: level * 2,
                          color:
                          (widget.speech.isListening ? Colors.green : Colors.red)
                              .withValues(alpha: 0.3),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(80),
                        onTap: !widget.hasSpeech || widget.speech.isListening
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
    widget.speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: listenFor ?? 30),
      pauseFor: Duration(seconds: pauseFor ?? 3),
      localeId: widget.currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      listenOptions: options,
    );
    setState(() {});
  }

  void stopListening() {
    widget.speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    widget.speech.cancel();
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
      await widget.addMessageToConversation("user", result.recognizedWords);

      try {
        final response = await sendChatCompletion(
          widget.currentContact!.conversation.messagesAsMap,
        );

        String messageContent = response['choices'][0]['message']['content'];

        // Check debug mode for think tag removal
        if (!debug) {
          messageContent = messageContent.replaceAll(
            RegExp(r'<think>.*?</think>', dotAll: true),
            '',
          );
        }

        // Remove /no_think string
        messageContent = messageContent.replaceAll('/no_think', '');
        messageContent = messageContent.trim();

        await widget.addMessageToConversation("assistant", messageContent);

        setState(() {
          lastWords += messageContent;
        });

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

        // Check automatic listen setting
        final prefs = await SharedPreferences.getInstance();
        final automaticListen = prefs.getBool('automatic_listen') ?? true;

        try {
          final String? voice = widget.currentContact!.voice;
          final data = await sendTtsGenerateRequest(messageContent, voice);
          if (data != null) {
            final player = AudioPlayer();
            await player.play(BytesSource(data));

            // Wait for audio to complete, then start listening again if enabled
            if (automaticListen) {
              player.onPlayerComplete.listen((_) {
                if (mounted && widget.hasSpeech) {
                  // Small delay to ensure smooth transition
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && !widget.speech.isListening) {
                      startListening();
                    }
                  });
                }
              });
            }
          } else {
            // If no audio data, start listening immediately if enabled
            if (automaticListen &&
                mounted &&
                widget.hasSpeech &&
                !widget.speech.isListening) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && !widget.speech.isListening) {
                  startListening();
                }
              });
            }
          }
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('TTS error: $error')));
            // Start listening even if TTS fails, but only if enabled
            if (automaticListen && widget.hasSpeech && !widget.speech.isListening) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && !widget.speech.isListening) {
                  startListening();
                }
              });
            }
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat completion error: $error')),
          );
        }
      }
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

  void _switchOnDevice(bool? val) {
    setState(() {
      _onDevice = val ?? false;
    });
  }
}