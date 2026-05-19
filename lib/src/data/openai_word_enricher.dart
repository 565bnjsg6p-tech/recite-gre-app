import 'dart:convert';

import 'package:http/http.dart' as http;

import 'word_entry.dart';

class AiWordData {
  const AiWordData({
    required this.chineseMeaning,
    required this.englishMeaning,
    required this.greFocus,
    required this.roots,
    required this.synonyms,
    required this.antonyms,
    required this.example,
    required this.memoryTip,
    required this.tags,
  });

  final String chineseMeaning;
  final String englishMeaning;
  final String greFocus;
  final List<RootPart> roots;
  final List<String> synonyms;
  final List<String> antonyms;
  final String example;
  final String memoryTip;
  final List<String> tags;

  factory AiWordData.fromJson(Map<String, dynamic> json) {
    return AiWordData(
      chineseMeaning: json['chineseMeaning']?.toString() ?? '',
      englishMeaning: json['englishMeaning']?.toString() ?? '',
      greFocus: json['greFocus']?.toString() ?? '',
      roots: (json['roots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => RootPart(
              part: item['part']?.toString() ?? '',
              meaning: item['meaning']?.toString() ?? '',
            ),
          )
          .where((item) => item.part.isNotEmpty || item.meaning.isNotEmpty)
          .toList(),
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      example: json['example']?.toString() ?? '',
      memoryTip: json['memoryTip']?.toString() ?? '',
      tags: _stringList(json['tags']),
    );
  }

  static List<String> _stringList(Object? value) {
    return (value as List<dynamic>? ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class OpenAiWordEnricher {
  OpenAiWordEnricher({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AiWordData> enrich({
    required String apiKey,
    required String model,
    required String word,
  }) async {
    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'input': [
          {
            'role': 'system',
            'content':
                'You create concise GRE/IELTS vocabulary study cards. Return accurate Chinese definitions and exam-focused memory help. Do not include copyrighted test questions.',
          },
          {
            'role': 'user',
            'content':
                'Create a study card for the word "$word". Focus on GRE usage, but keep IELTS/TOEFL learners in mind when useful.',
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'word_card',
            'schema': {
              'type': 'object',
              'additionalProperties': false,
              'required': [
                'chineseMeaning',
                'englishMeaning',
                'greFocus',
                'roots',
                'synonyms',
                'antonyms',
                'example',
                'memoryTip',
                'tags',
              ],
              'properties': {
                'chineseMeaning': {'type': 'string'},
                'englishMeaning': {'type': 'string'},
                'greFocus': {'type': 'string'},
                'roots': {
                  'type': 'array',
                  'items': {
                    'type': 'object',
                    'additionalProperties': false,
                    'required': ['part', 'meaning'],
                    'properties': {
                      'part': {'type': 'string'},
                      'meaning': {'type': 'string'},
                    },
                  },
                },
                'synonyms': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
                'antonyms': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
                'example': {'type': 'string'},
                'memoryTip': {'type': 'string'},
                'tags': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
              },
            },
            'strict': true,
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenAiWordEnricherException(
        'OpenAI 请求失败：HTTP ${response.statusCode}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = _extractOutputText(body);
    if (outputText == null || outputText.trim().isEmpty) {
      throw const OpenAiWordEnricherException('OpenAI 返回为空。');
    }

    return AiWordData.fromJson(jsonDecode(outputText) as Map<String, dynamic>);
  }

  String? _extractOutputText(Map<String, dynamic> body) {
    final direct = body['output_text'];
    if (direct is String) {
      return direct;
    }

    final output = body['output'];
    if (output is! List) {
      return null;
    }

    for (final item in output.whereType<Map<String, dynamic>>()) {
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final part in content.whereType<Map<String, dynamic>>()) {
        final text = part['text'];
        if (text is String) {
          return text;
        }
      }
    }
    return null;
  }
}

class OpenAiWordEnricherException implements Exception {
  const OpenAiWordEnricherException(this.message);

  final String message;

  @override
  String toString() => message;
}
