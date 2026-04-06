import 'dart:convert';

/// Decodes the payload segment of a JWT (no signature verification).
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    var segment = parts[1];
    final mod = segment.length % 4;
    if (mod == 2) {
      segment += '==';
    } else if (mod == 3) {
      segment += '=';
    }
    final bytes = base64Url.decode(segment);
    final json = utf8.decode(bytes);
    final data = jsonDecode(json);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  } catch (_) {
    return null;
  }
}
