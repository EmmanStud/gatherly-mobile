enum EventStatus {
  draft('Draft'),
  onSale('On sale'),
  finished('Finished'),
  cancelled('Cancelled');

  const EventStatus(this.label);
  final String label;

  static EventStatus fromApi(Object? value) => switch (value) {
    'On sale' => EventStatus.onSale,
    'Finished' => EventStatus.finished,
    'Cancelled' => EventStatus.cancelled,
    _ => EventStatus.draft,
  };
}

class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    required this.accountType,
  });

  final String name;
  final String email;
  final String accountType;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final email = json['email'];
    final accountType = json['accountType'];
    if (name is! String || email is! String || accountType is! String) {
      throw const FormatException('The server returned an invalid user.');
    }
    return AuthUser(name: name, email: email, accountType: accountType);
  }
}

class TicketType {
  const TicketType({required this.id, required this.name, required this.priceCents});

  final String id;
  final String name;
  final int priceCents;

  factory TicketType.fromJson(Map<String, dynamic> json) => TicketType(
    id: json['id']?.toString() ?? '',
    name: json['name'] is String ? json['name'] as String : '',
    priceCents: _asInt(json['priceCents']),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'priceCents': priceCents,
  };
}

class Event {
  const Event({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.multipleDay,
    required this.endDate,
    required this.venue,
    required this.description,
    required this.category,
    required this.headliner,
    required this.total,
    required this.sold,
    required this.eventCode,
    required this.registrationUrl,
    required this.pricingMode,
    required this.priceCents,
    required this.ticketTypes,
    required this.status,
  });

  final String id;
  final String name;
  final String date;
  final String time;
  final bool multipleDay;
  final String endDate;
  final String venue;
  final String description;
  final String category;
  final String headliner;
  final int total;
  final int sold;
  final String eventCode;
  final String registrationUrl;
  final String pricingMode;
  final int priceCents;
  final List<TicketType> ticketTypes;
  final EventStatus status;

  int get capacity => total;
  DateTime get startAt => DateTime.tryParse('${date}T$time:00') ?? DateTime(2000);
  double get fill => total <= 0 ? 0 : (sold / total).clamp(0.0, 1.0);
  int get percent => (fill * 100).round();

  factory Event.fromJson(Map<String, dynamic> json) {
    final ticketData = json['ticketTypes'];
    return Event(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: _asString(json['name']),
      date: _asString(json['date']),
      time: _asString(json['time']),
      multipleDay: json['multipleDay'] == true,
      endDate: _asString(json['endDate']),
      venue: _asString(json['venue']),
      description: _asString(json['description']),
      category: _asString(json['category']),
      headliner: _asString(json['headliner']),
      total: _asInt(json['total']),
      sold: _asInt(json['sold']),
      eventCode: _asString(json['eventCode']),
      registrationUrl: _asString(json['registrationUrl']),
      pricingMode: _asString(json['pricingMode'], fallback: 'free'),
      priceCents: _asInt(json['priceCents']),
      ticketTypes: ticketData is List
          ? ticketData.whereType<Map>().map((item) =>
                TicketType.fromJson(Map<String, dynamic>.from(item))).toList()
          : const [],
      status: EventStatus.fromApi(json['status']),
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'date': date,
    'time': time,
    'multipleDay': multipleDay,
    'endDate': multipleDay ? endDate : '',
    'venue': venue,
    'description': description,
    'category': category,
    'headliner': headliner,
    'total': total,
    'pricingMode': pricingMode,
    'priceCents': pricingMode == 'single' ? priceCents : 0,
    'ticketTypes': pricingMode == 'multiple'
        ? ticketTypes.map((ticket) => ticket.toJson()).toList()
        : const [],
  };
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.buyer,
    required this.email,
    required this.eventName,
    required this.eventId,
    required this.ticket,
    required this.amountCents,
    required this.status,
    required this.paidAt,
  });

  final String id;
  final String number;
  final String buyer;
  final String email;
  final String eventName;
  final String eventId;
  final String ticket;
  final int amountCents;
  final String status;
  final DateTime? paidAt;

  int get amountCentavos => amountCents;
  bool get refunded => status == 'Refunded';
  String get statusLabel => status;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    number: _asString(json['number']),
    buyer: _asString(json['buyer']),
    email: _asString(json['email']),
    eventName: _asString(json['event']),
    eventId: json['eventId']?.toString() ?? '',
    ticket: _asString(json['ticket']),
    amountCents: _asInt(json['amountCents']),
    status: _asString(json['status']),
    paidAt: DateTime.tryParse(_asString(json['paidAt'])),
  );
}

class Attendee {
  const Attendee({
    required this.id,
    required this.name,
    required this.email,
    required this.eventName,
    required this.eventId,
    required this.ticket,
    required this.orderNumber,
    required this.checkedIn,
    required this.date,
    required this.endDate,
  });

  final String id;
  final String name;
  final String email;
  final String eventName;
  final String eventId;
  final String ticket;
  final String orderNumber;
  final bool checkedIn;
  final String date;
  final String endDate;

  factory Attendee.fromJson(Map<String, dynamic> json) => Attendee(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    name: _asString(json['name']),
    email: _asString(json['email']),
    eventName: _asString(json['event']),
    eventId: json['eventId']?.toString() ?? '',
    ticket: _asString(json['ticket']),
    orderNumber: _asString(json['orderNumber']),
    checkedIn: json['checkedIn'] == true,
    date: _asString(json['date']),
    endDate: _asString(json['endDate']),
  );
}

class Profile {
  const Profile({
    required this.name,
    required this.email,
    required this.phone,
    required this.organization,
  });

  final String name;
  final String email;
  final String phone;
  final String organization;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

class Preferences {
  const Preferences({
    this.orderEmails = true,
    this.eventReminders = true,
    this.weeklySummary = false,
    this.twoFactor = false,
  });

  final bool orderEmails;
  final bool eventReminders;
  final bool weeklySummary;
  final bool twoFactor;

  Preferences copyWith({
    bool? orderEmails,
    bool? eventReminders,
    bool? weeklySummary,
    bool? twoFactor,
  }) => Preferences(
    orderEmails: orderEmails ?? this.orderEmails,
    eventReminders: eventReminders ?? this.eventReminders,
    weeklySummary: weeklySummary ?? this.weeklySummary,
    twoFactor: twoFactor ?? this.twoFactor,
  );
}

String _asString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

int _asInt(Object? value) => value is num ? value.toInt() : 0;
