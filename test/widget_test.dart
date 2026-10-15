import 'dart:convert';

import 'package:final_project/models/models.dart';
import 'package:final_project/core/analytics.dart';
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

  test('profile and password API calls use authenticated routes', () async {
    SharedPreferences.setMockInitialValues({
      'gatherly_session_token': 'profile-test-token',
    });
    final requests = <http.Request>[];
    final api = GatherlyApi(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/auth/profile') {
          return http.Response(
            jsonEncode({
              'user': {
                'name': 'Updated Name',
                'email': 'user@example.com',
                'accountType': 'customer',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"message":"Password changed successfully."}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'http://localhost:4000/api',
    );

    final user = await api.updateProfile(name: 'Updated Name');
    expect(user.name, 'Updated Name');
    expect(requests[0].method, 'PATCH');
    expect(requests[0].headers['Authorization'], startsWith('Bearer '));
    expect(jsonDecode(requests[0].body), {'name': 'Updated Name'});

    final message = await api.changePassword(
      currentPassword: 'OldPassword9!',
      newPassword: 'NewPassword9!',
      confirmNewPassword: 'NewPassword9!',
    );
    expect(message, 'Password changed successfully.');
    expect(requests[1].method, 'POST');
    expect(requests[1].headers['Authorization'], startsWith('Bearer '));
    expect(jsonDecode(requests[1].body), {
      'currentPassword': 'OldPassword9!',
      'newPassword': 'NewPassword9!',
      'confirmNewPassword': 'NewPassword9!',
    });
    api.close();
  });

  test('organizer list endpoints decode top-level arrays', () async {
    SharedPreferences.setMockInitialValues({
      'gatherly_session_token': 'organizer-test-token',
    });
    late http.Request request;
    final api = GatherlyApi(
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode([
            {
              'id': 'event-1',
              'name': 'Gatherly Meetup',
              'date': '2026-10-20',
              'time': '18:30',
              'multipleDay': false,
              'endDate': '',
              'venue': 'Manila',
              'description': 'A meetup',
              'category': 'Community',
              'headliner': 'Gatherly',
              'total': 100,
              'sold': 12,
              'eventCode': 'ABC1234',
              'registrationUrl': 'https://example.com/events/ABC1234',
              'pricingMode': 'free',
              'priceCents': 0,
              'ticketTypes': [],
              'status': 'On sale',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: 'http://localhost:4000/api',
    );

    final events = await api.getEvents();
    expect(events, hasLength(1));
    expect(events.single.id, 'event-1');
    expect(events.single.status, EventStatus.onSale);
    expect(request.url.path, '/api/events');
    expect(request.headers['Authorization'], startsWith('Bearer '));
    api.close();
  });

  test('revenue buckets use Paid orders and Asia/Manila time', () {
    final orders = [
      Order(
        id: 'paid-today',
        number: 'A-1',
        buyer: 'Buyer One',
        email: 'one@example.com',
        eventName: 'Event',
        eventId: 'event-1',
        eventCode: 'EVT1234',
        ticket: 'General',
        amountCents: 12500,
        status: 'Paid',
        paidAt: DateTime.parse('2026-10-14T16:30:00Z'),
      ),
      Order(
        id: 'paid-yesterday',
        number: 'A-2',
        buyer: 'Buyer Two',
        email: 'two@example.com',
        eventName: 'Event',
        eventId: 'event-1',
        eventCode: 'EVT1234',
        ticket: 'General',
        amountCents: 5000,
        status: 'Paid',
        paidAt: DateTime.parse('2026-10-14T15:00:00Z'),
      ),
      Order(
        id: 'refunded',
        number: 'A-3',
        buyer: 'Buyer Three',
        email: 'three@example.com',
        eventName: 'Event',
        eventId: 'event-1',
        eventCode: 'EVT1234',
        ticket: 'General',
        amountCents: 9000,
        status: 'Refunded',
        paidAt: DateTime.parse('2026-10-14T16:30:00Z'),
      ),
      Order(
        id: 'prior-month',
        number: 'A-4',
        buyer: 'Buyer Four',
        email: 'four@example.com',
        eventName: 'Event',
        eventId: 'event-1',
        eventCode: 'EVT1234',
        ticket: 'General',
        amountCents: 3000,
        status: 'Paid',
        paidAt: DateTime.parse('2026-09-30T15:30:00Z'),
      ),
    ];
    final now = DateTime.parse('2026-10-15T12:00:00Z');

    final day = buildRevenueBuckets(
      orders: orders,
      period: RevenuePeriod.day,
      now: now,
    );
    expect(day, hasLength(24));
    expect(day[0].amountCents, 12500);
    expect(day.fold<int>(0, (sum, bucket) => sum + bucket.amountCents), 12500);

    final week = buildRevenueBuckets(
      orders: orders,
      period: RevenuePeriod.week,
      now: now,
    );
    expect(week, hasLength(7));
    expect(week.fold<int>(0, (sum, bucket) => sum + bucket.amountCents), 17500);

    final month = buildRevenueBuckets(
      orders: orders,
      period: RevenuePeriod.month,
      now: now,
    );
    expect(month.length, greaterThanOrEqualTo(4));
    expect(
      month.fold<int>(0, (sum, bucket) => sum + bucket.amountCents),
      17500,
    );
  });

  test('authenticated 401 clears the token and notifies the app', () async {
    SharedPreferences.setMockInitialValues({
      'gatherly_session_token': 'expired-token',
    });
    var notified = false;
    final api = GatherlyApi(
      client: MockClient(
        (_) async => http.Response('{"error":"Session expired."}', 401),
      ),
      baseUrl: 'http://localhost:4000/api',
    )..onUnauthorized = () => notified = true;

    await expectLater(
      api.updateProfile(name: 'Updated Name'),
      throwsA(isA<GatherlyApiException>()),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('gatherly_session_token'), isNull);
    expect(notified, isTrue);
    api.close();
  });
}
