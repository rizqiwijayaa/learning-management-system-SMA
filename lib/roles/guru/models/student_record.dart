class StudentRecord {
  final int? id;
  final String name;
  final String nis;
  final String className;
  final String major;
  final String status;

  const StudentRecord({
    this.id,
    required this.name,
    required this.nis,
    required this.className,
    required this.major,
    required this.status,
  });

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: '${json['name'] ?? ''}',
      nis: '${json['nis'] ?? ''}',
      className: '${json['class_name'] ?? json['className'] ?? ''}',
      major: '${json['major'] ?? ''}',
      status: '${json['status'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nis': nis,
      'class_name': className,
      'major': major,
      'status': status,
    };
  }

  StudentRecord copyWith({
    int? id,
    String? name,
    String? nis,
    String? className,
    String? major,
    String? status,
  }) {
    return StudentRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      nis: nis ?? this.nis,
      className: className ?? this.className,
      major: major ?? this.major,
      status: status ?? this.status,
    );
  }
}
