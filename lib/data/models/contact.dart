import 'call_item.dart';

class Contact {
  final String phone; // normalized or raw dialable number
  final String? name; // optional display name

  const Contact({required this.phone, this.name});

  // Factory from backend JSON: { "name": "...", "phone": "..." }
  factory Contact.fromJson(Map<String, dynamic> j) {
    final rawName = (j['name'] ?? '').toString().trim();
    final rawPhone = (j['phone'] ?? '').toString().trim();

    return Contact(phone: rawPhone, name: rawName.isEmpty ? null : rawName);
  }

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  // Create a CallItem used by the dialer queue
  CallItem toCallItem() => CallItem(displayNumber: phone, displayName: name);

  // Value semantics
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          phone == other.phone &&
          name == other.name;

  @override
  int get hashCode => Object.hash(phone, name);

  Contact copyWith({
    String? phone,
    String? name,
    bool clearName = false, // helper to explicitly clear name
  }) {
    return Contact(
      phone: phone ?? this.phone,
      name: clearName ? null : (name ?? this.name),
    );
  }

  // Optional: normalize phone for dialing (very simple; customize as needed)
  Contact normalized({String allowed = r'0-9+\-() '}) {
    final exp = RegExp('[^$allowed]');
    final cleaned = phone.replaceAll(exp, '');
    return copyWith(phone: cleaned);
  }
}
