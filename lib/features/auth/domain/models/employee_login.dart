import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Local credentials for the UI demo; production authentication belongs on
/// the server. Revealable values exist solely for the requested UI demo.
class EmployeeLogin {
  final String email;
  final String salt;
  final String digest;
  final String? initialPassword;
  final String? currentPassword;
  const EmployeeLogin(
      {required this.email,
      required this.salt,
      required this.digest,
      this.initialPassword,
      this.currentPassword});

  static String? passwordError(String password) =>
      password.trim().isEmpty || password.length < 8
          ? 'Use at least 8 characters for the password.'
          : password.length > 128
              ? 'Use no more than 128 characters.'
              : null;

  factory EmployeeLogin.create(String email, String password,
      {bool revealInitial = false, bool revealCurrent = false}) {
    final random = Random.secure();
    final salt = base64Encode(List.generate(24, (_) => random.nextInt(256)));
    return EmployeeLogin(
        email: email.trim().toLowerCase(),
        salt: salt,
        digest: sha256.convert(utf8.encode('$salt:$password')).toString(),
        initialPassword: revealInitial ? password : null,
        currentPassword: revealInitial || revealCurrent ? password : null);
  }

  bool matches(String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString() == digest;

  EmployeeLogin withEmail(String email) => EmployeeLogin(
      email: email.trim().toLowerCase(),
      salt: salt,
      digest: digest,
      initialPassword: initialPassword,
      currentPassword: currentPassword);

  Map<String, dynamic> toJson() => {
        'email': email,
        'salt': salt,
        'digest': digest,
        'initialPassword': initialPassword,
        'currentPassword': currentPassword,
      };
  factory EmployeeLogin.fromJson(Map<String, dynamic> json) => EmployeeLogin(
      email: json['email'] as String,
      salt: json['salt'] as String,
      digest: json['digest'] as String,
      initialPassword: json['initialPassword'] as String?,
      currentPassword: json['currentPassword'] as String? ??
          json['initialPassword'] as String?);
}
