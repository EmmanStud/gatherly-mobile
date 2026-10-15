import 'package:flutter/widgets.dart';

import '../models/models.dart';
import '../services/gatherly_api.dart';

class AppState extends ChangeNotifier {
  AppState({GatherlyApi? api}) : _api = api ?? GatherlyApi() {
    _api.onUnauthorized = _handleUnauthorized;
  }

  final GatherlyApi _api;
  AuthUser? _user;
  bool _isRestoringSession = true;
  bool _isLoadingData = false;
  String? _sessionRestoreError;
  String? _dataError;
  void Function()? onSessionExpired;
  List<Event> _events = [];
  List<Order> _orders = [];
  List<Attendee> _attendees = [];
  Profile _profile = const Profile(name: '', email: '', phone: '', organization: '');
  Preferences _preferences = const Preferences();

  List<Event> get events => List.unmodifiable(_events);
  List<Order> get orders => List.unmodifiable(_orders);
  List<Attendee> get attendees => List.unmodifiable(_attendees);
  Profile get profile => _profile;
  Preferences get preferences => _preferences;
  AuthUser? get user => _user;
  GatherlyApi get api => _api;
  bool get isAuthenticated => _user != null;
  bool get isRestoringSession => _isRestoringSession;
  bool get isLoadingData => _isLoadingData;
  String? get sessionRestoreError => _sessionRestoreError;
  String? get dataError => _dataError;

  Future<void> restoreSession() async {
    _isRestoringSession = true;
    _sessionRestoreError = null;
    notifyListeners();
    try {
      final user = await _api.currentUser();
      if (user != null) {
        _setUser(user);
        await loadOrganizerData();
      }
    } catch (error) {
      if (error is! GatherlyApiException || error.statusCode != 401) {
        _sessionRestoreError = error.toString();
      }
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
    _setUser(user);
    loadOrganizerData();
  }

  void _setUser(AuthUser user) {
    _user = user;
    _profile = Profile(
      name: user.name,
      email: user.email,
      phone: _profile.phone,
      organization: _profile.organization,
    );
    notifyListeners();
  }

  Future<void> loadOrganizerData() async {
    if (_user == null) return;
    _isLoadingData = true;
    _dataError = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _api.getEvents(),
        _api.getOrders(),
        _api.getAttendees(),
      ]);
      _events = results[0] as List<Event>;
      _orders = results[1] as List<Order>;
      _attendees = results[2] as List<Attendee>;
    } catch (error) {
      if (error is! GatherlyApiException || error.statusCode != 401) {
        _dataError = error is GatherlyApiException
            ? error.message
            : 'Unable to load organizer data. Please try again.';
      }
    } finally {
      _isLoadingData = false;
      notifyListeners();
    }
  }

  void _handleUnauthorized() {
    _user = null;
    _events = [];
    _orders = [];
    _attendees = [];
    _profile = Profile(
      name: '',
      email: '',
      phone: _profile.phone,
      organization: _profile.organization,
    );
    _sessionRestoreError = null;
    _dataError = null;
    notifyListeners();
    onSessionExpired?.call();
  }

  Future<void> signOut() async {
    _user = null;
    _events = [];
    _orders = [];
    _attendees = [];
    _profile = const Profile(name: '', email: '', phone: '', organization: '');
    notifyListeners();
    await _api.logout();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  int get ticketsSold => _events.fold(0, (sum, event) => sum + event.sold);
  int get activeEvents =>
      _events.where((event) => event.status == EventStatus.onSale).length;
  int get draftEvents =>
      _events.where((event) => event.status == EventStatus.draft).length;
  int get checkedInCount => _attendees.where((person) => person.checkedIn).length;
  int get paidOrderCount => _orders.where((order) => order.status == 'Paid').length;
  int get revenueCents => _orders
      .where((order) => order.status == 'Paid')
      .fold(0, (sum, order) => sum + order.amountCents);

  Event? get nextEvent {
    final now = DateTime.now();
    final upcoming = _events
        .where((event) =>
            event.status == EventStatus.onSale && event.startAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Event? eventById(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  Future<void> saveEvent(Event event) async {
    final saved = event.id.isEmpty
        ? await _api.createEvent(event)
        : await _api.updateEvent(event);
    _replaceEvent(saved);
  }

  Future<void> publishEvent(String id) async => _replaceEvent(await _api.publishEvent(id));
  Future<void> finishEvent(String id) async => _replaceEvent(await _api.finishEvent(id));
  Future<void> cancelEvent(String id) async => _replaceEvent(await _api.cancelEvent(id));

  Future<void> deleteEvent(String id) async {
    await _api.deleteEvent(id);
    _events = _events.where((event) => event.id != id).toList();
    notifyListeners();
  }

  Future<void> refundOrder(String id) async {
    final updated = await _api.refundOrder(id);
    _orders = _orders.map((order) => order.id == id ? updated : order).toList();
    notifyListeners();
  }

  Future<void> setCheckedIn(String id, bool checkedIn) async {
    final updated = await _api.setCheckedIn(id, checkedIn);
    _attendees = _attendees.map((person) => person.id == id ? updated : person).toList();
    notifyListeners();
  }

  void _replaceEvent(Event updated) {
    final index = _events.indexWhere((event) => event.id == updated.id);
    if (index < 0) {
      _events = [updated, ..._events];
    } else {
      _events = [..._events]..[index] = updated;
    }
    notifyListeners();
  }

  Future<void> updateProfile(Profile profile) async {
    final user = await _api.updateProfile(name: profile.name);
    _user = user;
    _profile = Profile(
      name: user.name,
      email: user.email,
      phone: profile.phone,
      organization: profile.organization,
    );
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
