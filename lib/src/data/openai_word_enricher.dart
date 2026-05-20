import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'word_quality.dart';
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

  AiContentQuality get quality => evaluateAiContent(
    chineseMeaning: chineseMeaning,
    englishMeaning: englishMeaning,
    greFocus: greFocus,
    roots: roots,
    synonyms: synonyms,
    antonyms: antonyms,
    example: example,
    memoryTip: memoryTip,
    tags: tags,
  );

  factory AiWordData.fromJson(Map<String, dynamic> json) {
    return AiWordData(
      chineseMeaning: _firstString(json, [
        'chineseMeaning',
        'chinese',
        'meaningCn',
        'definitionCn',
      ]),
      englishMeaning: _firstString(json, [
        'englishMeaning',
        'english',
        'meaningEn',
        'definitionEn',
      ]),
      greFocus: _firstString(json, [
        'greFocus',
        'examFocus',
        'testFocus',
        'usageFocus',
      ]),
      roots: _rootParts(json['roots'] ?? json['rootAffixes']),
      synonyms: _stringList(json['synonyms'] ?? json['synonym']),
      antonyms: _stringList(json['antonyms'] ?? json['antonym']),
      example: _firstString(json, ['example', 'exampleSentence']),
      memoryTip: _firstString(json, ['memoryTip', 'mnemonic', 'memory']),
      tags: _stringList(json['tags']),
    );
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static List<RootPart> _rootParts(Object? value) {
    if (value is String) {
      return value
          .split(RegExp(r'[,，;；\n]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .map((item) {
            final parts = item.split(RegExp(r'[:：-]'));
            if (parts.length >= 2) {
              return RootPart(
                part: parts.first.trim(),
                meaning: parts.skip(1).join('-').trim(),
              );
            }
            return RootPart(part: item, meaning: '');
          })
          .toList();
    }
    return (value as List<dynamic>? ?? const [])
        .map((item) {
          if (item is Map<String, dynamic>) {
            return RootPart(
              part:
                  (item['part'] ?? item['root'] ?? item['affix'])
                      ?.toString()
                      .trim() ??
                  '',
              meaning:
                  (item['meaning'] ?? item['definition'])?.toString().trim() ??
                  '',
            );
          }
          final text = item.toString().trim();
          return RootPart(part: text, meaning: '');
        })
        .where((item) => item.part.isNotEmpty || item.meaning.isNotEmpty)
        .toList();
  }

  static List<String> _stringList(Object? value) {
    if (value is String) {
      return value
          .split(RegExp(r'[,，;；\n/]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
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
    required String apiBaseUrl,
    required String apiKey,
    required String model,
    required String word,
  }) async {
    final isWebProxy = kIsWeb;
    final endpoint = isWebProxy
        ? Uri.parse('/api/ai/enrich')
        : _buildChatCompletionsUri(apiBaseUrl);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (!isWebProxy) 'Authorization': 'Bearer $apiKey',
    };
    final payload = <String, dynamic>{
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You create complete GRE/IELTS vocabulary study cards. Return only valid JSON. Do not include markdown. Do not include copyrighted test questions. Every required field must be specific, useful, and non-empty. Never use placeholders such as N/A, none, TBD, unknown, or 暂无.',
        },
        {
          'role': 'user',
          'content':
              'Create a deep study card for "$word". Return JSON with exactly these keys: chineseMeaning, englishMeaning, greFocus, roots, synonyms, antonyms, example, memoryTip, tags. Requirements: chineseMeaning must include part of speech and Chinese definitions; englishMeaning must explain the core sense in English; greFocus must explain common GRE test angle, traps, collocations, and how it differs from near synonyms; roots must contain 1-4 objects with non-empty part and meaning; synonyms must contain at least 2 useful GRE-level words; antonyms should contain useful opposites when they exist; example must be one original sentence of at least 12 words; memoryTip must give a concrete mnemonic; tags should include 2-5 short Chinese tags.',
        },
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.2,
    };
    if (isWebProxy) {
      payload['apiBaseUrl'] = apiBaseUrl;
      payload['apiKey'] = apiKey;
    }
    final response = await _client.post(
      endpoint,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = _extractErrorDetail(response.body);
      throw OpenAiWordEnricherException(
        'AI 请求失败：HTTP ${response.statusCode}${detail.isEmpty ? '' : ' · $detail'}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = _extractOutputText(body);
    if (outputText == null || outputText.trim().isEmpty) {
      throw OpenAiWordEnricherException(
        'AI 返回为空：${_extractErrorDetail(response.body)}',
      );
    }

    return AiWordData.fromJson(_decodeJsonObject(outputText));
  }

  Uri _buildChatCompletionsUri(String apiBaseUrl) {
    final trimmed = apiBaseUrl.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Missing API base URL.');
    }
    final normalized = trimmed.endsWith('/') ? trimmed : '$trimmed/';
    final uri = Uri.parse(normalized);
    final path = uri.path;
    if (path.endsWith('/v1/chat/completions') ||
        path.endsWith('/chat/completions')) {
      return uri;
    }
    if (path.endsWith('/v1')) {
      return uri.resolve('chat/completions');
    }
    return uri.resolve('v1/chat/completions');
  }

  String _extractErrorDetail(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return '';
    }
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message']?.toString().trim() ?? '';
          final type = error['type']?.toString().trim() ?? '';
          if (message.isNotEmpty && type.isNotEmpty) {
            return '$type: $message';
          }
          if (message.isNotEmpty) {
            return message;
          }
        }
      }
    } on Object {
      // Fall back to a compact text excerpt below.
    }
    final singleLine = rawBody.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 120) {
      return singleLine;
    }
    return '${singleLine.substring(0, 117)}...';
  }

  String? _extractOutputText(Map<String, dynamic> body) {
    final choiceContent = _extractChoiceContent(body);
    if (choiceContent != null) {
      return choiceContent;
    }

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

  String? _extractChoiceContent(Map<String, dynamic> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      return null;
    }
    for (final choice in choices.whereType<Map<String, dynamic>>()) {
      final message = choice['message'];
      if (message is Map<String, dynamic>) {
        final content = message['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _decodeJsonObject(String raw) {
    final trimmed = raw.trim();
    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } on FormatException {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(trimmed);
      if (match == null) {
        rethrow;
      }
      return jsonDecode(match.group(0)!) as Map<String, dynamic>;
    }
  }
}

class OpenAiWordEnricherException implements Exception {
  const OpenAiWordEnricherException(this.message);

  final String message;

  @override
  String toString() => message;
}
