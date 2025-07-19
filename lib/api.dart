import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> sendChatCompletion(
    List<Map<String, String>> conversationHistory, String character) async {
  final prefs = await SharedPreferences.getInstance();
  final apiAddress = prefs.getString('openai_api_address');

  // Construct the full URL for the chat completions endpoint
  final url = Uri.parse('$apiAddress/v1/chat/completions');

  final headers = {
    'Content-Type': 'application/json',
  };

  final body = jsonEncode({
    "messages": conversationHistory,
    "mode": "chat",
    "character": character
  });

  final response = await http.post(url, headers: headers, body: body);

  return jsonDecode(utf8.decode(response.bodyBytes));
}

Future<dynamic> sendTtsGenerateRequest(String messageContent) async {
  final prefs = await SharedPreferences.getInstance();
  final alltalkTtsApiAddress = prefs.getString('alltalk_tts_api_address');

  if (alltalkTtsApiAddress == null) {
    print('Error: TTS API address not found in preferences');
    return null;
  }

  final url = Uri.parse('$alltalkTtsApiAddress/v1/audio/speech');

  // Request body matching the OpenAI TTS API format
  final body = {
    'model': 'tts-1',
    'input': messageContent,
    'voice': 'fr-FR-DeniseNeural',
    'response_format': 'mp3',
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer your_api_key_here',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Convert the response body bytes to Uint8List
      return response.bodyBytes;
    } else {
      print('Error: TTS request failed with status ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error making TTS request: $e');
    return null;
  }
}