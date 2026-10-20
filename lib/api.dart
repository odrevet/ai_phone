import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> sendChatCompletion(
  List<Map<String, String>> conversationHistory,
) async {
  final prefs = await SharedPreferences.getInstance();
  final apiAddress = prefs.getString('openai_api_address')?.trim() ?? '';
  if (apiAddress.isEmpty) {
    throw Exception('Generation API address is not configured.');
  }

  final model = prefs.getString('generation_model')?.trim() ?? '';
  final apiKey = prefs.getString('api_key_generation')?.trim() ?? '';

  // Construct the full URL for the chat completions endpoint
  final url = Uri.parse('${_normalizeBaseUrl(apiAddress)}/chat/completions');

  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
  };

  final body = jsonEncode({
    "messages": conversationHistory,
    "mode": "chat",
    if (model.isNotEmpty) "model": model,
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode != 200) {
    final responseBody = utf8.decode(response.bodyBytes).trim();
    throw Exception(
      'Request failed with status ${response.statusCode}'
      '${responseBody.isEmpty ? '' : ': $responseBody'}',
    );
  }

  return jsonDecode(utf8.decode(response.bodyBytes));
}

/// Fetches the model identifiers exposed by an OpenAI-compatible API.
///
/// [apiAddress] is the base address of the service, with or without a
/// trailing `/v1`. Throws an [Exception] when the service cannot be reached or
/// returns an unexpected response.
Future<List<String>> fetchModels({
  required String apiAddress,
  String? apiKey,
  http.Client? client,
}) async {
  final baseUrl = _normalizeBaseUrl(apiAddress);
  final url = Uri.parse('$baseUrl/models');

  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (apiKey != null && apiKey.trim().isNotEmpty)
      'Authorization': 'Bearer ${apiKey.trim()}',
  };

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = utf8.decode(response.bodyBytes).trim();
      throw Exception(
        'Request failed with status ${response.statusCode}'
        '${body.isEmpty ? '' : ': $body'}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final List<dynamic>? entries;
    if (decoded is List) {
      entries = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['models'];
      entries = data is List ? data : null;
    } else {
      entries = null;
    }

    if (entries == null) {
      throw Exception('Unexpected response from $url');
    }

    final models = <String>{};
    for (final entry in entries) {
      if (entry is String) {
        models.add(entry);
      } else if (entry is Map) {
        final id = entry['id'] ?? entry['name'] ?? entry['model'];
        if (id is String) models.add(id);
      }
    }

    return models.where((model) => model.trim().isNotEmpty).toList()..sort();
  } finally {
    if (client == null) httpClient.close();
  }
}

/// Returns the base URL (including its version segment) for an
/// OpenAI-compatible API address.
///
/// Accepts addresses with or without a scheme, a trailing slash, `/v1`,
/// `/models`, `/chat/completions`, or `/audio/speech`. When no path is
/// provided, `/v1` is assumed.
String _normalizeBaseUrl(String apiAddress) {
  var baseUrl = apiAddress.trim().replaceAll(RegExp(r'/+$'), '');
  for (final suffix in const [
    '/chat/completions',
    '/audio/speech',
    '/models',
  ]) {
    if (baseUrl.endsWith(suffix)) {
      baseUrl = baseUrl.substring(0, baseUrl.length - suffix.length);
    }
  }

  var uri = Uri.tryParse(baseUrl);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    baseUrl = 'http://$baseUrl';
    uri = Uri.tryParse(baseUrl);
  }
  if (uri != null && (uri.path.isEmpty || uri.path == '/')) {
    baseUrl = '$baseUrl/v1';
  }
  return baseUrl;
}

/// Generates speech using an OpenAI-compatible `/v1/audio/speech` endpoint.
///
/// Returns `null` when no endpoint is configured or when the request fails.
Future<Uint8List?> sendTtsGenerateRequest(String messageContent) async {
  final prefs = await SharedPreferences.getInstance();
  final ttsApiAddress = prefs.getString('tts_api_address')?.trim() ?? '';
  final voice = prefs.getString('voice')?.trim() ?? 'alloy';
  final ttsApiKey = prefs.getString('api_key_tts')?.trim() ?? '';

  if (ttsApiAddress.isEmpty) return null;

  final url = Uri.parse('${_normalizeBaseUrl(ttsApiAddress)}/audio/speech');

  // Request body matching the OpenAI TTS API format
  final body = {
    'model': 'tts-1',
    'input': messageContent,
    'response_format': 'mp3',
    if (voice.isNotEmpty) 'voice': voice,
  };
  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (ttsApiKey.isNotEmpty) 'Authorization': 'Bearer $ttsApiKey',
  };

  try {
    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    developer.log(
      'Error: TTS request failed with status ${response.statusCode}',
    );
    developer.log('Response body: ${response.body}');
    developer.log('Request was $body');
    return null;
  } catch (e) {
    developer.log('Error making TTS request: $e');
    return null;
  }
}
