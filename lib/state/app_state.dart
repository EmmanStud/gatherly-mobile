import 'package:flutter/widgets.dart';

import '../models/models.dart';
import '../services/gatherly_api.dart';

/// In-memory app state seeded with the Figma sample data.
/// Replace the methods with repository/API calls when the backend is ready.
class AppState extends ChangeNotifier {
  AppState({GatherlyApi? api}) : _api = api ?? GatherlyApi();

  final GatherlyApi _api;
  AuthUser? _user;
  bool _isRestoringSession = true;
  String? _sessionRestoreError;

  final List<Event> _events = [
    Event(
      id: 1,
      name: 'Manila Creatives Summit 2026',
      startAt: DateTime(2026, 10, 18, 9, 0),
      venue: 'SMX Convention Center, Pasay',
      sold: 342,
      capacity: 500,
      status: EventStatus.onSale,
    ),
    Event(
      id: 2,
      name: 'Makati Founders Night',
      startAt: DateTime(2026, 10, 24, 19, 30),
      venue: 'The Astbury, Makati',
      sold: 186,
      capacity: 250,
      status: EventStatus.onSale,
    ),
    Event(
      id: 3,
      name: 'Philippine Product Summit',
      startAt: DateTime(2026, 11, 6, 10, 0),
      venue: 'Online event · Philippines',
      sold: 920,
      capacity: 1200,
      status: EventStatus.draft,
    ),
    Event(
      id: 4,
      name: 'Cebu Creatives Morning',
      startAt: DateTime(2026, 11, 15, 8, 30),
      venue: 'Ayala Center Cebu',
      sold: 98,
      capacity: 150,
      status: EventStatus.onSale,
    ),
  ];

  List<Order> _orders = const [
    Order(id: 'PH1048', buyer: 'Nicole Macalalad', eventName: 'Manila Creatives Summit 2026', amountCentavos: 250000),
    Order(id: 'PH1047', buyer: 'Emman Agazon', eventName: 'Makati Founders Night', amountCentavos: 180000),
    Order(id: 'PH1046', buyer: 'Jamie Anne Brizal', eventName: 'Cebu Creatives Morning', amountCentavos: 95000),
  ];

  List<Attendee> _attendees = const [
    Attendee(id: 1, name: 'Emman Agazon', eventName: 'Manila Creatives Summit 2026', ticket: 'VIP Pass', checkedIn: true),
    Attendee(id: 2, name: 'Nicole Macalalad', eventName: 'Manila Creatives Summit 2026', ticket: 'Regular'),
    Attendee(id: 3, name: 'Jamie Anne Brizal', eventName: 'Makati Founders Night', ticket: 'Early Bird'),
    Attendee(id: 4, name: 'Diomella Agustin', eventName: 'Cebu Creatives Morning', ticket: 'Regular', checkedIn: true),
  ];

  Profile _profile = const Profile(
    name: 'Chrysdale Soltes',
    email: 'chrysdale@gatherly.ph',
    phone: '+63 917 123 4567',
    organization: 'Gatherly Events PH',
  );

  Preferences _preferences = const Preferences();
  int _nextEventId = 5;

  // Demo figures from the design. They cannot be derived until ticket
  // prices and an attendee registry exist in the backend.
  final int demoRevenueCentavos = 279545000;
  final int demoAttendeeCount = 1204;

  // ---- read ----
  List<Event> get events => List.unmodifiable(_events);
  List<Order> get orders => List.unmodifiable(_orders);
  List<Attendee> get attendees => List.unmodifiable(_attendees);
  Profile get profile => _profile;
  Preferences get preferences => _preferences;
  AuthUser? get user => _user;
  GatherlyApi get api => _api;
  bool get isAuthenticated => _user != null;
  bool get isRestoringSession => _isRestoringSession;
  String? get sessionRestoreError => _sessionRestoreError;

  Future<void> restoreSession() async {
    _isRestoringSession = true;
    _sessionRestoreError = null;
    notifyListeners();
    try {
      final user = await _api.currentUser();
      if (user != null) signIn(user);
    } catch (error) {
      _sessionRestoreError = error.toString();
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  void continueWithoutSession() {
    _sessionRestoreError = null;
    notifyListeners();
  }

  void signIn(AuthUser user) {
    _user = user;
    _profile = Profile(
      name: user.name,
      email: user.email,
      phone: _profile.phone,
      organization: _profile.organization,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    notifyListeners();
    await _api.logout();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  int get ticketsSold => _events.fold(0, (sum, e) => sum + e.sold);
  int get activeEvents =>
      _events.where((e) => e.status == EventStatus.onSale).length;
  int get draftEvents =>
      _events.where((e) => e.status == EventStatus.draft).length;
  int get checkedInCount => _attendees.where((a) => a.checkedIn).length;
  int get paidOrderCount => _orders.where((o) => !o.refunded).length;

  /// The soonest on-sale event that has not started yet.
  Event? get nextEvent {
    final now = DateTime.now();
    final upcoming = _events
        .where((e) => e.status == EventStatus.onSale && e.startAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Event? eventById(int id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---- events ----
  void addEvent({
    required String name,
    required DateTime startAt,
    required String venue,
    required int capacity,
  }) {
    _events.insert(
      0,
      Event(
        id: _nextEventId++,
        name: name,
        startAt: startAt,
        venue: venue,
        sold: 0,
        capacity: capacity,
      ),
    );
    notifyListeners();
  }

  void updateEvent(
    int id, {
    required String name,
    required DateTime startAt,
    required String venue,
    required int capacity,
  }) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _events[index] = _events[index].copyWith(
      name: name,
      startAt: startAt,
      venue: venue,
      capacity: capacity,
    );
    notifyListeners();
  }

  void setEventStatus(int id, EventStatus status) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _events[index] = _events[index].copyWith(status: status);
    notifyListeners();
  }

  void deleteEvent(int id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---- orders / attendees ----
  void refundOrder(String id) {
    _orders = [
      for (final o in _orders) o.id == id ? o.copyWith(refunded: true) : o,
    ];
    notifyListeners();
  }

  void toggleCheckIn(int id) {
    _attendees = [
      for (final a in _attendees)
        a.id == id ? a.copyWith(checkedIn: !a.checkedIn) : a,
    ];
    notifyListeners();
  }

  // ---- profile / settings ----
  void updateProfile(Profile profile) {
    _profile = profile;
    notifyListeners();
  }

  void updatePreferences(Preferences preferences) {
    _preferences = preferences;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!.notifier!;
  }
}