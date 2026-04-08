import 'package:dio/dio.dart';

import 'api_paths.dart';
import 'sg_api_client.dart';

/// One turn for the LLM API (OpenAI-style chat messages).
class LlmChatTurn {
  const LlmChatTurn({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class LlmChatRepository {
  LlmChatRepository(this._api);

  final SgApiClient _api;

  /// Sends the conversation to your backend and returns the assistant reply text.
  ///
  /// Default request body: `{ "messages": [ { "role": "user"|"assistant", "content": "..." }, ... ] }`
  /// If your API expects a different shape, change [LlmChatRepository._buildBody] below.
  Future<String> sendChat(List<LlmChatTurn> messages) async {
    if (messages.isEmpty) {
      throw LlmChatException('No messages to send.');
    }
    try {
      final response = await _api.dio.post<dynamic>(
        ApiPaths.llmChat,
        data: _buildBody(messages),
      );
      return _parseReply(response.data);
    } on DioException catch (e) {
      throw LlmChatException(_dioMessage(e));
    }
  }

  Map<String, dynamic> _buildBody(List<LlmChatTurn> messages) {
    return {
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  String _parseReply(dynamic data) {
    if (data == null) {
      throw LlmChatException('Empty response from server.');
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      for (final k in ['reply', 'message', 'content', 'text', 'response', 'answer']) {
        final v = m[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      final nested = m['data'];
      if (nested is Map) {
        return _parseReply(nested);
      }
      final choices = m['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final msg = first['message'];
          if (msg is Map && msg['content'] is String) {
            return (msg['content'] as String).trim();
          }
        }
      }
    }
    throw LlmChatException('Could not read assistant reply from API.');
  }

  static String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      if (d is String) return d;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server.';
      default:
        break;
    }
    final code = e.response?.statusCode;
    if (code == 404) return 'Chat API not found. Check ApiPaths.llmChat matches your backend.';
    return e.message ?? 'Chat request failed.';
  }
}

class LlmChatException implements Exception {
  LlmChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
