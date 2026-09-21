class AttendanceSummary {
  final String studentName;
  final int presentDays;
  final int izinDays;
  final int alfaDays;

  const AttendanceSummary({
    required this.studentName,
    required this.presentDays,
    required this.izinDays,
    required this.alfaDays,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      studentName: json['studentName'] ?? '',
      presentDays: json['presentDays'] ?? 0,
      izinDays: json['izinDays'] ?? 0,
      alfaDays: json['alfaDays'] ?? 0,
    );
  }
}
