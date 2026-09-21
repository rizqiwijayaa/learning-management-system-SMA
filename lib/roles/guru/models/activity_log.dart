class ActivityLog {
  final int id;
  final String title;
  final String actor;
  final String type;
  final DateTime? createdAt;

  const ActivityLog({
    required this.id,
    required this.title,
    required this.actor,
    required this.type,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: '${json['title'] ?? ''}',
      actor: '${json['actor'] ?? ''}',
      type: '${json['type'] ?? ''}',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'actor': actor,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
