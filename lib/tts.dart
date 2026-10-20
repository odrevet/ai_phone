import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

/// Reads AI responses with the phone's built-in text-to-speech engine.
const String ttsEngineDevice = 'device';

/// Reads AI responses through an OpenAI-compatible `/v1/audio/speech` API.
const String ttsEngineApi = 'api';

/// Returns the TTS engine to use, falling back to the device engine when the
/// API endpoint is not configured.
String resolveTtsEngine(String? savedEngine, String? apiAddress) {
  if (savedEngine == ttsEngineApi || savedEngine == ttsEngineDevice) {
    return savedEngine!;
  }
  return (apiAddress?.trim().isNotEmpty ?? false)
      ? ttsEngineApi
      : ttsEngineDevice;
}

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _deviceTts = FlutterTts();
  AudioPlayer? _player;
  Completer<void>? _playbackCompleter;

  /// Speaks [text] and completes once playback is finished.
  ///
  /// When the API endpoint is selected but unavailable or not configured, the
  /// phone's built-in engine is used as a fallback.
  Future<void> speak(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final apiAddress = prefs.getString('tts_api_address')?.trim() ?? '';
    final engine = resolveTtsEngine(prefs.getString('tts_engine'), apiAddress);

    await stop();

    if (engine == ttsEngineApi && apiAddress.isNotEmpty) {
      final data = await sendTtsGenerateRequest(trimmedText);
      if (data != null) {
        await _playBytes(data);
        return;
      }
    }

    await _speakOnDevice(trimmedText);
  }

  /// Stops any speech currently in progress.
  Future<void> stop() async {
    final completer = _playbackCompleter;
    _playbackCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }

    final player = _player;
    _player = null;
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {
        // The player may already be stopped.
      }
      try {
        await player.dispose();
      } catch (_) {
        // The player may already be disposed.
      }
    }
    try {
      await _deviceTts.stop();
    } catch (_) {
      // The device engine may not be initialised yet.
    }
  }

  Future<void> _speakOnDevice(String text) async {
    await _deviceTts.awaitSpeakCompletion(true);
    final result = await _deviceTts.speak(text);
    if (result == 0) {
      throw Exception(
        'The phone text-to-speech engine is not available on this device.',
      );
    }
  }

  Future<void> _playBytes(Uint8List data) async {
    final player = AudioPlayer();
    final completer = Completer<void>();
    _player = player;
    _playbackCompleter = completer;

    final subscription = player.onPlayerComplete.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });

    try {
      await player.play(BytesSource(data));
      await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {},
      );
    } finally {
      await subscription.cancel();
      if (identical(_playbackCompleter, completer)) {
        _playbackCompleter = null;
      }
      if (identical(_player, player)) {
        _player = null;
        await player.dispose();
      }
    }
  }
}
