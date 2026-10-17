import 'auth_user.dart';

class AuthSessionData {
  const AuthSessionData({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final AuthUser user;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  factory AuthSessionData.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final expiresAt = DateTime.tryParse(json['expires_at'] as String? ?? '');
    if (token is! String ||
        token.isEmpty ||
        expiresAt == null ||
        json['user'] is! Map) {
      throw const FormatException('The server returned an invalid session.');
    }
    return AuthSessionData(
        token: token,
        expiresAt: expiresAt,
        user:
            AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)));
  }

  AuthSessionData withUser(AuthUser user) =>
      AuthSessionData(token: token, expiresAt: expiresAt, user: user);

  Map<String, dynamic> toJson() => {
        'token': token,
        'expires_at': expiresAt.toIso8601String(),
        'user': user.toJson(),
      };
}
