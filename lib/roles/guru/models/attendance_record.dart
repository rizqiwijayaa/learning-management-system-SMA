import 'package:flutter/material.dart';

class AttendanceRecord {
  final int? id;
  final int? teacherId;
  final String teacherNip;
  final String teacherName;
  final String studentName;
  final String className;
  final String monthLabel;
  final int presentDays;
  final int izinDays;
  final int alfaDays;
  final String accentColor;
  final String initial;

  const AttendanceRecord({
    this.id,
    this.teacherId,
    this.teacherNip = '',
    this.teacherName = '',
    required this.studentName,
    required this.className,
    required this.monthLabel,
    required this.presentDays,
    required this.izinDays,
    required this.alfaDays,
    required this.accentColor,
    required this.initial,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      teacherId: json['teacher_id'] is int
          ? json['teacher_id'] as int
          : int.tryParse('${json['teacher_id'] ?? json['teacherId']}'),
      teacherNip: '${json['teacher_nip'] ?? json['teacherNip'] ?? ''}',
      teacherName: '${json['teacher_name'] ?? json['teacherName'] ?? ''}',
      studentName: '${json['student_name'] ?? json['studentName'] ?? ''}',
      className: '${json['class_name'] ?? json['className'] ?? ''}',
      monthLabel: '${json['month_label'] ?? json['monthLabel'] ?? ''}',
      presentDays: json['present_days'] is int
          ? json['present_days'] as int
          : int.tryParse('${json['present_days']}') ?? 0,
      izinDays: json['izin_days'] is int
          ? json['izin_days'] as int
          : int.tryParse('${json['izin_days']}') ?? 0,
      alfaDays: json['alfa_days'] is int
          ? json['alfa_days'] as int
          : int.tryParse('${json['alfa_days']}') ?? 0,
      accentColor: '${json['accent_color'] ?? json['accentColor'] ?? '#D6E6FF'}',
      initial: '${json['initial'] ?? ''}',
    );
  }

  Color get accent {
    final hex = accentColor.replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFFD6E6FF);
  }

  AttendanceRecord copyWith({
    int? id,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
    String? studentName,
    String? className,
    String? monthLabel,
    int? presentDays,
    int? izinDays,
    int? alfaDays,
    String? accentColor,
    String? initial,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherNip: teacherNip ?? this.teacherNip,
      teacherName: teacherName ?? this.teacherName,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      monthLabel: monthLabel ?? this.monthLabel,
      presentDays: presentDays ?? this.presentDays,
      izinDays: izinDays ?? this.izinDays,
      alfaDays: alfaDays ?? this.alfaDays,
      accentColor: accentColor ?? this.accentColor,
      initial: initial ?? this.initial,
    );
  }
}
