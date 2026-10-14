enum EventStatus {
  onSale('On sale'),
  draft('Draft');

  const EventStatus(this.label);
  final String label;
}

class Event {
  const Event({
    required this.id,
    required this.name,
    required this.startAt,
    required this.venue,
    required this.sold,
    required this.capacity,
    this.status = EventStatus.draft,
  });

  final int id;
  final String name;
  final DateTime startAt;
  final String venue;
  final int sold;
  final int capacity;
  final EventStatus status;

  double get fill => capacity == 0 ? 0 : (sold / capacity).clamp(0.0, 1.0);
  int get percent => (fill * 100).round();

  Event copyWith({
    String? name,
    DateTime? startAt,
    String? venue,
    int? capacity,
    EventStatus? status,
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      startAt: startAt ?? this.startAt,
      venue: venue ?? this.venue,
      sold: sold,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.buyer,
    required this.eventName,
    required this.amountCentavos,
    this.refunded = false,
  });

  final String id;
  final String buyer;
  final String eventName;
  final int amountCentavos;
  final bool refunded;

  String get statusLabel => refunded ? 'Refunded' : 'Paid';

  Order copyWith({bool? refunded}) => Order(
        id: id,
        buyer: buyer,
        eventName: eventName,
        amountCentavos: amountCentavos,
        refunded: refunded ?? this.refunded,
      );
}

class Attendee {
  const Attendee({
    required this.id,
    required this.name,
    required this.eventName,
    required this.ticket,
    this.checkedIn = false,
  });

  final int id;
  final String name;
  final String eventName;
  final String ticket;
  final bool checkedIn;

  Attendee copyWith({bool? checkedIn}) => Attendee(
        id: id,
        name: name,
        eventName: eventName,
        ticket: ticket,
        checkedIn: checkedIn ?? this.checkedIn,
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
  }) {
    return Preferences(
      orderEmails: orderEmails ?? this.orderEmails,
      eventReminders: eventReminders ?? this.eventReminders,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      twoFactor: twoFactor ?? this.twoFactor,
    );
  }
}