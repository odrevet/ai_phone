import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> sendChatCompletion(
    List<Map<String, String>> conversationHistory) async {
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
    "character": "Operator"
  });

  final response = await http.post(url, headers: headers, body: body);

  return jsonDecode(utf8.decode(response.bodyBytes));
}

Future<String> sendTtsGenerateRequest(String messageContent) async {
  final prefs = await SharedPreferences.getInstance();
  final alltalkTtsApiAddress = prefs.getString('alltalk_tts_api_address');

  final url = Uri.parse('$alltalkTtsApiAddress/api/tts-generate');

  // The body contains the form data, similar to the -d flags in curl
  final body = {
    'text_input': messageContent,
    'text_filtering': 'standard',
    'character_voice_gen': 'female_01.wav',
    'narrator_enabled': 'false',
    'narrator_voice_gen': 'male_01.wav',
    'text_not_inside': 'character',
    'language': 'fr',
    'output_file_name': 'myoutputfile',
    'output_file_timestamp': 'true',
    'autoplay': 'false',
    'autoplay_volume': '0.8',
  };

  final response = await http.post(url, body: body);

  if (response.statusCode == 200) {
    // Parse the response
    final responseData = jsonDecode(response.body);
    String audioUrl = responseData['output_file_url'];
    return audioUrl;
  } else {
    return 'Error: ${response.statusCode}';
  }
}
