import 'dart:convert';
import 'dart:typed_data';

class UserProfile {
  final int id;
  final String name;
  final String role;
  final String nip;
  final String email;
  final String phone;
  final String? avatarBase64;

  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.nip,
    required this.email,
    required this.phone,
    this.avatarBase64,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 1,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      nip: json['nip']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarBase64: json['avatarBase64']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'nip': nip,
      'email': email,
      'phone': phone,
      'avatarBase64': avatarBase64,
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? role,
    String? nip,
    String? email,
    String? phone,
    String? avatarBase64,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      nip: nip ?? this.nip,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
    );
  }

  Uint8List? get avatarBytes {
    final raw = avatarBase64;
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'R';
    return trimmed.substring(0, 1).toUpperCase();
  }
}
