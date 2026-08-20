import 'dart:convert';
import 'dart:math';

class TokenHelper {
  TokenHelper._();

  static String generateToken(String userId) {
    final header = base64Url.encode(utf8.encode(jsonEncode({
      'alg': 'HS256',
      'typ': 'JWT',
    })));

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': userId,
      'iat': now,
      'exp': now + (7 * 24 * 60 * 60),
    })));

    final signature = _generateSignature('$header.$payload');
    return '$header.$payload.$signature';
  }

  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(parts[1]));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool isTokenValid(String token) {
    final payload = decodeToken(token);
    if (payload == null) return false;
    final exp = payload['exp'] as int?;
    if (exp == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now < exp;
  }

  static String _generateSignature(String data) {
    final random = Random();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
