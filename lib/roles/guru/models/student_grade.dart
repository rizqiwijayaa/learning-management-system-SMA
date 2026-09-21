class StudentGrade {
  final int? id;
  final int? teacherId;
  final String teacherNip;
  final String teacherName;
  final String studentName;
  final String subject;
  final String className;
  final int score;

  const StudentGrade({
    this.id,
    this.teacherId,
    this.teacherNip = '',
    this.teacherName = '',
    required this.studentName,
    required this.subject,
    required this.className,
    required this.score,
  });

  factory StudentGrade.fromJson(Map<String, dynamic> json) {
    return StudentGrade(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      teacherId: json['teacher_id'] is int
          ? json['teacher_id'] as int
          : int.tryParse('${json['teacher_id'] ?? json['teacherId']}'),
      teacherNip: '${json['teacher_nip'] ?? json['teacherNip'] ?? ''}',
      teacherName: '${json['teacher_name'] ?? json['teacherName'] ?? ''}',
      studentName: '${json['student_name'] ?? json['studentName'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      className: '${json['class_name'] ?? json['className'] ?? ''}',
      score: json['score'] is int ? json['score'] as int : int.tryParse('${json['score']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'teacher_nip': teacherNip,
      'teacher_name': teacherName,
      'student_name': studentName,
      'subject': subject,
      'class_name': className,
      'score': score,
    };
  }

  StudentGrade copyWith({
    int? id,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
    String? studentName,
    String? subject,
    String? className,
    int? score,
  }) {
    return StudentGrade(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherNip: teacherNip ?? this.teacherNip,
      teacherName: teacherName ?? this.teacherName,
      studentName: studentName ?? this.studentName,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      score: score ?? this.score,
    );
  }
}
