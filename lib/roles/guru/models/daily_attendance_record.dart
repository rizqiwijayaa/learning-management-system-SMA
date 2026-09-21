import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/attendance_record.dart';

enum DailyAttendanceStatus {
  hadir('hadir', 'Hadir', Color(0xFF2FBE86), Icons.check_circle_rounded),
  izin('izin', 'Izin', Color(0xFFF5C84B), Icons.error_rounded),
  alfa('alfa', 'Alfa', Color(0xFFE25666), Icons.cancel_rounded);

  final String key;
  final String label;
  final Color color;
  final IconData icon;

  const DailyAttendanceStatus(this.key, this.label, this.color, this.icon);

  static DailyAttendanceStatus fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return DailyAttendanceStatus.values.firstWhere(
      (item) => item.key == normalized,
      orElse: () => DailyAttendanceStatus.hadir,
    );
  }
}

class DailyAttendanceRecord {
  final int? id;
  final int? attendanceRecordId;
  final int? teacherId;
  final String teacherNip;
  final String teacherName;
  final String studentName;
  final String className;
  final String monthLabel;
  final String dateLabel;
  final int dayOrder;
  final DailyAttendanceStatus status;
  final String note;
  final String accentColor;
  final String initial;

  const DailyAttendanceRecord({
    this.id,
    this.attendanceRecordId,
    this.teacherId,
    this.teacherNip = '',
    this.teacherName = '',
    required this.studentName,
    required this.className,
    required this.monthLabel,
    required this.dateLabel,
    required this.dayOrder,
    required this.status,
    this.note = '',
    this.accentColor = '#D6E6FF',
    this.initial = '',
  });

  factory DailyAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceRecord(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      attendanceRecordId: json['attendance_record_id'] is int
          ? json['attendance_record_id'] as int
          : int.tryParse(
              '${json['attendance_record_id'] ?? json['attendanceRecordId']}',
            ),
      teacherId: json['teacher_id'] is int
          ? json['teacher_id'] as int
          : int.tryParse('${json['teacher_id'] ?? json['teacherId']}'),
      teacherNip: '${json['teacher_nip'] ?? json['teacherNip'] ?? ''}',
      teacherName: '${json['teacher_name'] ?? json['teacherName'] ?? ''}',
      studentName: '${json['student_name'] ?? json['studentName'] ?? ''}',
      className: '${json['class_name'] ?? json['className'] ?? ''}',
      monthLabel: '${json['month_label'] ?? json['monthLabel'] ?? ''}',
      dateLabel: '${json['date_label'] ?? json['dateLabel'] ?? ''}',
      dayOrder: json['day_order'] is int
          ? json['day_order'] as int
          : int.tryParse('${json['day_order'] ?? json['dayOrder']}') ?? 0,
      status: DailyAttendanceStatus.fromValue(
        '${json['status'] ?? json['status_key'] ?? json['statusKey']}',
      ),
      note: '${json['note'] ?? ''}',
      accentColor: '${json['accent_color'] ?? json['accentColor'] ?? '#D6E6FF'}',
      initial: '${json['initial'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendanceRecordId': attendanceRecordId,
      'teacherId': teacherId,
      'teacherNip': teacherNip,
      'teacherName': teacherName,
      'studentName': studentName,
      'className': className,
      'monthLabel': monthLabel,
      'dateLabel': dateLabel,
      'dayOrder': dayOrder,
      'status': status.key,
      'note': note,
      'accentColor': accentColor,
      'initial': initial,
    };
  }

  DailyAttendanceRecord copyWith({
    int? id,
    int? attendanceRecordId,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
    String? studentName,
    String? className,
    String? monthLabel,
    String? dateLabel,
    int? dayOrder,
    DailyAttendanceStatus? status,
    String? note,
    String? accentColor,
    String? initial,
  }) {
    return DailyAttendanceRecord(
      id: id ?? this.id,
      attendanceRecordId: attendanceRecordId ?? this.attendanceRecordId,
      teacherId: teacherId ?? this.teacherId,
      teacherNip: teacherNip ?? this.teacherNip,
      teacherName: teacherName ?? this.teacherName,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      monthLabel: monthLabel ?? this.monthLabel,
      dateLabel: dateLabel ?? this.dateLabel,
      dayOrder: dayOrder ?? this.dayOrder,
      status: status ?? this.status,
      note: note ?? this.note,
      accentColor: accentColor ?? this.accentColor,
      initial: initial ?? this.initial,
    );
  }
}

class DailyAttendanceMutation {
  final DailyAttendanceRecord? record;
  final AttendanceRecord summary;

  const DailyAttendanceMutation({
    required this.record,
    required this.summary,
  });

  factory DailyAttendanceMutation.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceMutation(
      record: json['record'] is Map<String, dynamic>
          ? DailyAttendanceRecord.fromJson(json['record'] as Map<String, dynamic>)
          : null,
      summary: AttendanceRecord.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}

class DailyAttendanceEditResult {
  final DailyAttendanceRecord record;
  final bool delete;

  const DailyAttendanceEditResult._({
    required this.record,
    required this.delete,
  });

  factory DailyAttendanceEditResult.save(DailyAttendanceRecord record) {
    return DailyAttendanceEditResult._(record: record, delete: false);
  }

  factory DailyAttendanceEditResult.delete(DailyAttendanceRecord record) {
    return DailyAttendanceEditResult._(record: record, delete: true);
  }
}
