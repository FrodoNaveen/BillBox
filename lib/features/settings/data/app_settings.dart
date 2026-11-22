/// Everything the settings tab can change, as one immutable value.
///
/// Deliberately free of Flutter imports so it can be read and tested on its
/// own; the screens turn [reminderHour] / [reminderMinute] into a TimeOfDay.
class AppSettings {
  AppSettings({
    this.remindersEnabled = true,
    Set<int>? leadDays,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.handsFreeEnabled = false,
  }) : leadDays = _cleanLeadDays(leadDays ?? defaultLeadDays);

  /// Master switch for every nudge.
  final bool remindersEnabled;

  /// How many days before an expiry to be nudged, largest first.
  final Set<int> leadDays;

  /// When the day's nudges are sent, on a 24-hour clock.
  final int reminderHour;
  final int reminderMinute;

  /// Listen for "hey BillBox" while the app is open.
  ///
  /// Off by default, and deliberately so: it holds the microphone for as
  /// long as the app is on screen, which costs battery and is not something
  /// to switch on behind the user's back.
  final bool handsFreeEnabled;

  /// The lead times the screen offers.
  static const List<int> leadDayOptions = <int>[30, 14, 7, 3, 1];

  static const Set<int> defaultLeadDays = <int>{30, 7, 1};

  /// Drops anything the screen cannot show, then sorts largest first so the
  /// summary line reads "30, 7, 1 days before".
  static Set<int> _cleanLeadDays(Set<int> days) {
    final kept = days.where(leadDayOptions.contains).toList()
      ..sort((a, b) => b.compareTo(a));
    return Set<int>.unmodifiable(kept);
  }

  /// "09:00" — a stable, locale-free form for summaries in tests.
  String get reminderTimeLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:'
      '${reminderMinute.toString().padLeft(2, '0')}';

  AppSettings copyWith({
    bool? remindersEnabled,
    Set<int>? leadDays,
    int? reminderHour,
    int? reminderMinute,
    bool? handsFreeEnabled,
  }) {
    return AppSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      leadDays: leadDays ?? this.leadDays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      handsFreeEnabled: handsFreeEnabled ?? this.handsFreeEnabled,
    );
  }

  /// Adds the lead time if it is off, removes it if it is on.
  AppSettings toggleLeadDay(int days) {
    final next = leadDays.toSet();
    if (!next.remove(days)) next.add(days);
    return copyWith(leadDays: next);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'remindersEnabled': remindersEnabled,
    'leadDays': leadDays.toList(),
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'handsFreeEnabled': handsFreeEnabled,
  };

  /// Every field falls back to its default, so a key added in a later version
  /// can still read settings written by this one.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final days = json['leadDays'];
    return AppSettings(
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      leadDays: days is List
          ? days.whereType<num>().map((d) => d.toInt()).toSet()
          : null,
      reminderHour: _clamp(json['reminderHour'], 0, 23, 9),
      reminderMinute: _clamp(json['reminderMinute'], 0, 59, 0),
      handsFreeEnabled: json['handsFreeEnabled'] as bool? ?? false,
    );
  }

  static int _clamp(Object? value, int min, int max, int fallback) {
    final number = value is num ? value.toInt() : null;
    if (number == null || number < min || number > max) return fallback;
    return number;
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.remindersEnabled == remindersEnabled &&
        other.reminderHour == reminderHour &&
        other.reminderMinute == reminderMinute &&
        other.handsFreeEnabled == handsFreeEnabled &&
        other.leadDays.length == leadDays.length &&
        other.leadDays.containsAll(leadDays);
  }

  @override
  int get hashCode => Object.hash(
    remindersEnabled,
    reminderHour,
    reminderMinute,
    handsFreeEnabled,
    Object.hashAllUnordered(leadDays),
  );
}
