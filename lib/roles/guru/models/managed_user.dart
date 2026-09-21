class ManagedUser {
  final int id;
  final String name;
  final String username;
  final String email;
  final String role;
  final String status;

  const ManagedUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: '${json['name'] ?? ''}',
      username: '${json['username'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? ''}',
      status: '${json['status'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'status': status,
    };
  }

  ManagedUser copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? role,
    String? status,
  }) {
    return ManagedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }
}
