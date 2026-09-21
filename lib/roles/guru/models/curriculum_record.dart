class CurriculumRecord {
  final int id;
  final String subject;
  final String code;
  final String major;
  final String grade;
  final String teacher;
  final String status;
  final String schoolYear;

  const CurriculumRecord({
    required this.id,
    required this.subject,
    required this.code,
    required this.major,
    required this.grade,
    required this.teacher,
    required this.status,
    required this.schoolYear,
  });

  factory CurriculumRecord.fromJson(Map<String, dynamic> json) {
    return CurriculumRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      subject: '${json['subject'] ?? ''}',
      code: '${json['code'] ?? ''}',
      major: '${json['major'] ?? ''}',
      grade: '${json['grade'] ?? ''}',
      teacher: '${json['teacher'] ?? ''}',
      status: '${json['status'] ?? ''}',
      schoolYear: '${json['school_year'] ?? json['schoolYear'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'code': code,
      'major': major,
      'grade': grade,
      'teacher': teacher,
      'status': status,
      'school_year': schoolYear,
    };
  }

  CurriculumRecord copyWith({
    int? id,
    String? subject,
    String? code,
    String? major,
    String? grade,
    String? teacher,
    String? status,
    String? schoolYear,
  }) {
    return CurriculumRecord(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      code: code ?? this.code,
      major: major ?? this.major,
      grade: grade ?? this.grade,
      teacher: teacher ?? this.teacher,
      status: status ?? this.status,
      schoolYear: schoolYear ?? this.schoolYear,
    );
  }
}
