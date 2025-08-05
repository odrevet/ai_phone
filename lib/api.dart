import 'dart:convert';

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

// Updated TTS function that throws exceptions instead of logging
Future<dynamic> sendTtsGenerateRequest(
  String messageContent,
  String? voice,
) async {
  final prefs = await SharedPreferences.getInstance();
  final ttsApiAddress = prefs.getString('tts_api_address');
  final selectedVoice = (voice != null && voice.trim().isNotEmpty)
      ? voice
      : prefs.getString('voice');

  final ttsApiKey = prefs.getString('api_key_tts');

  if (ttsApiAddress == null) {
    throw Exception('TTS API address not found in preferences');
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

  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    // Convert the response body bytes to Uint8List
    return response.bodyBytes;
  } else {
    // Throw detailed error information
    throw Exception(
      'TTS request failed with status ${response.statusCode}. '
      'Response: ${response.body}. '
      'Request body: $body. '
      'Headers: $headers',
    );
  }
}
