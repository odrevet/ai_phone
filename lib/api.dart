import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> sendChatCompletion(
  List<Map<String, String>> conversationHistory,
) async {
  final prefs = await SharedPreferences.getInstance();
  final apiAddress = prefs.getString('openai_api_address');

  // Construct the full URL for the chat completions endpoint
  final url = Uri.parse('$apiAddress/v1/chat/completions');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({"messages": conversationHistory, "mode": "chat"});
  final response = await http.post(url, headers: headers, body: body);

  return jsonDecode(utf8.decode(response.bodyBytes));
}

Future<dynamic> sendTtsGenerateRequest(String messageContent, String? voice) async {
  final prefs = await SharedPreferences.getInstance();
  final ttsApiAddress = prefs.getString('tts_api_address');
  final selectedVoice = (voice != null && voice.trim().isNotEmpty)
      ? voice
      : prefs.getString('voice');

  final ttsApiKey = prefs.getString('api_key_tts');

  if (ttsApiAddress == null) {
    developer.log('Error: TTS API address not found in preferences');
    return null;
  }

  final url = Uri.parse('$ttsApiAddress/v1/audio/speech');

  // Request body matching the OpenAI TTS API format
  final body = {
    'model': 'tts-1',
    'input': messageContent,
    'response_format': 'mp3',
    if (selectedVoice != null) 'voice': selectedVoice,
  };
  final headers = {
    'Authorization':
        'Bearer ${ttsApiKey?.trim().isNotEmpty == true ? ttsApiKey : 'your_api_key_here'}',
    'Content-Type': 'application/json',
  };

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Convert the response body bytes to Uint8List
      return response.bodyBytes;
    } else {
      developer.log(
        'Error: TTS request failed with status ${response.statusCode}',
      );
      developer.log('Response body: ${response.body}');

      developer.log("request was $body");
      developer.log("header was $headers");

      return null;
    }
  } catch (e) {
    developer.log('Error making TTS request: $e');
    return null;
  }
}
