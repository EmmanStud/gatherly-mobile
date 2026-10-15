
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class GatherlyApiException implements Exception {
  const GatherlyApiException(
    this.message, {
    this.statusCode,
    this.retryAfterSeconds,
  });

  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}

class EmailVerificationStatus {
  const EmailVerificationStatus({
    required this.verified,
    required this.registered,
  });

  final bool verified;
  final bool registered;
}

class AuthResult {
  const AuthResult({required this.user, required this.token});

  final AuthUser user;
  final String token;
}

class GatherlyApi {
  GatherlyApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _configuredBaseUrl;

  static const _tokenKey = 'gatherly_session_token';
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  final http.Client _client;
  final String _baseUrl;
  void Function()? onUnauthorized;

  Future<EmailVerificationStatus> emailStatus(String email) async {
    final response = await _request(
      'POST',
      '/auth/email-verification/status',
      body: {'email': email},
      authenticated: false,
    );
    return EmailVerificationStatus(
      verified: response['verified'] == true,
      registered: response['registered'] == true,
    );
  }

  Future<void> sendVerification({required String name, required String email}) async {
    await _request(
      'POST',
      '/auth/email-verification/send',
      body: {'name': name, 'email': email},
      authenticated: false,
    );
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    await _request(
      'POST',
      '/auth/email-verification/verify',
      body: {'email': email, 'code': code},
      authenticated: false,
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      authenticated: false,
    );
    return _saveAuthResult(response);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return _saveAuthResult(response);
  }

  Future<AuthUser?> currentUser() async {
    final token = await _readToken();
    if (token == null) return null;
    final response = await _request(
      'GET',
      '/auth/session',
      token: token,
      authenticated: true,
    );
    final data = response['user'];
    if (data == null) {
      await _removeToken();
      return null;
    }
    if (data is! Map) {
      throw const FormatException('The server returned an invalid session.');
    }
    return AuthUser.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> logout() async {
    final token = await _readToken();
    try {
      if (token != null) {
        await _request(
          'POST',
          '/auth/logout',
          token: token,
          allowEmpty: true,
          authenticated: true,
        );
      }
    } finally {
      await _removeToken();
    }
  }

  Future<String> sendPasswordReset(String email) async {
    final response = await _request(
      'POST',
      '/auth/password-reset/send',
      body: {'email': email},
      authenticated: false,
    );
    return _message(response);
  }

  Future<String> verifyPasswordReset({
    required String email,
    required String code,
  }) async {
    final response = await _request(
      'POST',
      '/auth/password-reset/verify',
      body: {'email': email, 'code': code},
      authenticated: false,
    );
    final token = response['resetToken'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('The server did not return a password reset token.');
    }
    return token;
  }

  Future<String> completePasswordReset({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final response = await _request(
      'POST',
      '/auth/password-reset/complete',
      body: {
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
      authenticated: false,
    );
    return _message(response);
  }

  Future<AuthUser> updateProfile({required String name}) async {
    final response = await _request(
      'PATCH',
      '/auth/profile',
      body: {'name': name},
      authenticated: true,
    );
    final data = response['user'];
    if (data is! Map) {
      throw const FormatException('The server returned an invalid profile.');
    }
    return AuthUser.fromJson(Map<String, dynamic>.from(data));
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final response = await _request(
      'POST',
      '/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
      authenticated: true,
    );
    return _message(response);
  }

  void close() => _client.close();

  Future<AuthResult> _saveAuthResult(Map<String, dynamic> response) async {
    final data = response['user'];
    final token = response['token'];
    if (data is! Map || token is! String || token.isEmpty) {
      throw const FormatException('The server returned an invalid sign-in response.');
    }
    final user = AuthUser.fromJson(Map<String, dynamic>.from(data));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    return AuthResult(user: user, token: token);
  }

  Future<String?> _readToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<void> _removeToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? token,
    bool allowEmpty = false,
    required bool authenticated,
  }) async {
    final baseUrl = _baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) {
      throw const GatherlyApiException(
        'API_BASE_URL is not configured. Run Flutter with --dart-define=API_BASE_URL=...',
      );
    }

    final uri = Uri.tryParse('$baseUrl$path');
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const GatherlyApiException('API_BASE_URL is not a valid URL.');
    }

    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    final authToken = token ?? (authenticated ? await _readToken() : null);
    if (authToken != null) headers['Authorization'] = 'Bearer $authToken';

    late http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException {
      throw const GatherlyApiException(
        'Unable to connect to Gatherly. Check your connection and try again.',
      );
    }

    if (allowEmpty && response.statusCode == 204) return {};

    if (response.statusCode == 401 && authenticated) {
      await _removeToken();
      onUnauthorized?.call();
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw const FormatException();
      data = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const GatherlyApiException('The server returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      throw GatherlyApiException(
        error is String && error.isNotEmpty ? error : 'Request failed. Please try again.',
        statusCode: response.statusCode,
        retryAfterSeconds: data['retryAfterSeconds'] is int
            ? data['retryAfterSeconds'] as int
            : null,
      );
    }
    return data;
  }

  String _message(Map<String, dynamic> response) {
    final message = response['message'];
    if (message is! String || message.isEmpty) {
      throw const FormatException('The server returned an invalid response.');
    }
    return message;
  }
}
