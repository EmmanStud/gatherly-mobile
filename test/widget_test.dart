import 'dart:convert';

import 'package:final_project/models/models.dart';
import 'package:final_project/services/gatherly_api.dart';
import 'package:final_project/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('passwordField', () {
    test('accepts a password meeting the server rule', () {
      expect(passwordField('Gatherly9!'), isNull);
    });

    test('rejects passwords missing any required character class', () {
      expect(passwordField('gatherly9!'), isNotNull);
      expect(passwordField('GATHERLY9!'), isNotNull);
      expect(passwordField('Gatherly!!'), isNotNull);
      expect(passwordField('Gatherly9'), isNotNull);
      expect(passwordField('Aa1!'), isNotNull);
    });
  });

  test('login saves the bearer token and logout removes it', () async {
    SharedPreferences.setMockInitialValues({});
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/auth/login') {
        return http.Response(
          jsonEncode({
            'user': {
              'name': 'Gatherly User',
              'email': 'user@example.com',
              'accountType': 'customer',
            },
            'token': 'jwt-for-test',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/auth/session') {
        return http.Response(
          jsonEncode({
            'user': {
              'name': 'Gatherly User',
              'email': 'user@example.com',
              'accountType': 'customer',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/auth/logout') {
        return http.Response('', 204);
      }
      return http.Response('{"error":"Unexpected request."}', 500);
    });
    final api = GatherlyApi(
      client: client,
      baseUrl: 'http://localhost:4000/api',
    );

    final signedIn = await api.login(
      email: 'user@example.com',
      password: 'Gatherly9!',
    );
    expect(signedIn.user, isA<AuthUser>());
    expect(signedIn.token, 'jwt-for-test');

    final currentUser = await api.currentUser();
    expect(currentUser?.email, 'user@example.com');
    expect(requests[1].headers['Authorization'], 'Bearer jwt-for-test');

    await api.logout();
    expect(requests[2].headers['Authorization'], 'Bearer jwt-for-test');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('gatherly_session_token'), isNull);
    api.close();
  });

  test('API errors preserve the server message and resend delay', () async {
    SharedPreferences.setMockInitialValues({});
    final api = GatherlyApi(
      client: MockClient(
        (_) async => http.Response(
          '{"error":"Please wait 37 seconds before requesting another code.","retryAfterSeconds":37}',
          429,
          headers: {'content-type': 'application/json'},
        ),
      ),
      baseUrl: 'http://localhost:4000/api',
    );

    await expectLater(
      api.sendVerification(name: 'Gatherly User', email: 'user@example.com'),
      throwsA(
        isA<GatherlyApiException>()
            .having((error) => error.message, 'message', contains('37 seconds'))
            .having(
              (error) => error.retryAfterSeconds,
              'retryAfterSeconds',
              37,
            ),
      ),
    );
    api.close();
  });
}
