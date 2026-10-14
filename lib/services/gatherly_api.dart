
import 'dart:convert';
import 'package:http/http.dart' as http;

class GatherlyApi {
  // Existing deployed Gatherly backend.
  static const String baseUrl =
      'https://gatherly-eight-chi.vercel.app/api';

  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    final dynamic decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    final Map<String, dynamic> data =
        decoded is Map<String, dynamic> ? decoded : {};

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['error'] ?? 'Request failed. Please try again.',
      );
    }

    return data;
  }

  static Future<Map<String, dynamic>> sendVerification({
    required String name,
    required String email,
  }) {
    return _post(
      '/auth/email-verification/send',
      {
        'name': name.trim(),
        'email': email.trim(),
      },
    );
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _post(
      '/auth/email-verification/verify',
      {
        'email': email.trim(),
        'code': code.trim(),
      },
    );
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _post(
      '/auth/register',
      {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post(
      '/auth/login',
      {
        'email': email.trim(),
        'password': password,
      },
    );
  }
}
