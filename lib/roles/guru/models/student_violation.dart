class StudentViolation {
  final int? id;
  final String studentName;
  final String className;
  final String violationType;
  final String description;
  final String actionTaken;
  final int points;
  final String violationDate;

  const StudentViolation({
    this.id,
    required this.studentName,
    required this.className,
    required this.violationType,
    required this.description,
    required this.actionTaken,
    required this.points,
    required this.violationDate,
  });

  factory StudentViolation.fromJson(Map<String, dynamic> json) {
    return StudentViolation(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      studentName: '${json['student_name'] ?? json['studentName'] ?? ''}',
      className: '${json['class_name'] ?? json['className'] ?? ''}',
      violationType: '${json['violation_type'] ?? json['violationType'] ?? ''}',
      description: '${json['description'] ?? ''}',
      actionTaken: '${json['action_taken'] ?? json['actionTaken'] ?? ''}',
      points: json['points'] is int
          ? json['points'] as int
          : int.tryParse('${json['points']}') ?? 0,
      violationDate: '${json['violation_date'] ?? json['violationDate'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': studentName,
      'class_name': className,
      'violation_type': violationType,
      'description': description,
      'action_taken': actionTaken,
      'points': points,
      'violation_date': violationDate,
    };
  }
}
