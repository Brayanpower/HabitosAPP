import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/config/helpers/token_helper.dart';

void main() {
  group('TokenHelper', () {
    test('generateToken should return a valid JWT format', () {
      final token = TokenHelper.generateToken('user123');
      expect(token.split('.').length, 3);
    });

    test('decodeToken should extract payload correctly', () {
      final token = TokenHelper.generateToken('user123');
      final payload = TokenHelper.decodeToken(token);
      expect(payload, isNotNull);
      expect(payload!['sub'], 'user123');
      expect(payload.containsKey('iat'), true);
      expect(payload.containsKey('exp'), true);
    });

    test('isTokenValid should return true for a newly generated token', () {
      final token = TokenHelper.generateToken('user123');
      expect(TokenHelper.isTokenValid(token), true);
    });

    test('isTokenValid should return false for invalid token', () {
      expect(TokenHelper.isTokenValid('invalid.token.here'), false);
    });

    test('decodeToken should return null for malformed token', () {
      expect(TokenHelper.decodeToken('not-a-token'), null);
    });

    test('different userIds produce different tokens', () {
      final token1 = TokenHelper.generateToken('user1');
      final token2 = TokenHelper.generateToken('user2');
      expect(token1, isNot(token2));
    });
  });
}
