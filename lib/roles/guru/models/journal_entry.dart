import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';

class JournalEntry {
  final int? id;
  final int? teacherId;
  final String teacherNip;
  final String teacherName;
  final String dateLabel;
  final String subject;
  final String title;
  final String materialSummary;
  final String className;
  final int attendanceCount;
  final Color accentColor;
  final List<String> learningPoints;
  final List<String> summaryParagraphs;
  final String progressTitle;
  final String progressNote;
  final String taskTitle;
  final String taskDeadline;
  final Uint8List? imageBytes;

  const JournalEntry({
    this.id,
    this.teacherId,
    this.teacherNip = '',
    this.teacherName = '',
    required this.dateLabel,
    required this.subject,
    required this.title,
    required this.materialSummary,
    required this.className,
    required this.attendanceCount,
    required this.accentColor,
    required this.learningPoints,
    required this.summaryParagraphs,
    required this.progressTitle,
    required this.progressNote,
    required this.taskTitle,
    required this.taskDeadline,
    this.imageBytes,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    final imageBase64 = json['image_base64'] ?? json['imageBase64'];
    if (imageBase64 is String && imageBase64.isNotEmpty) {
      try {
        bytes = base64Decode(imageBase64);
      } catch (_) {}
    }

    List<String> parseStringList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
      }
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) => '$e').where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    return JournalEntry(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      teacherId: json['teacher_id'] is int
          ? json['teacher_id'] as int
          : int.tryParse('${json['teacher_id'] ?? json['teacherId']}'),
      teacherNip: '${json['teacher_nip'] ?? json['teacherNip'] ?? ''}',
      teacherName: '${json['teacher_name'] ?? json['teacherName'] ?? ''}',
      dateLabel: '${json['date_label'] ?? json['dateLabel'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      title: '${json['title'] ?? ''}',
      materialSummary:
          '${json['material_summary'] ?? json['materialSummary'] ?? ''}',
      className: '${json['class_name'] ?? json['className'] ?? ''}',
      attendanceCount: json['attendance_count'] is int
          ? json['attendance_count'] as int
          : int.tryParse('${json['attendance_count'] ?? json['attendanceCount']}') ?? 0,
      accentColor: _parseColor(
        '${json['accent_color'] ?? json['accentColor'] ?? '#4D7CFF'}',
      ),
      learningPoints: parseStringList(
        json['learning_points'] ?? json['learningPoints'],
      ),
      summaryParagraphs: parseStringList(
        json['summary_paragraphs'] ?? json['summaryParagraphs'],
      ),
      progressTitle:
          '${json['progress_title'] ?? json['progressTitle'] ?? 'Progress Pembelajaran'}',
      progressNote:
          '${json['progress_note'] ?? json['progressNote'] ?? ''}',
      taskTitle: '${json['task_title'] ?? json['taskTitle'] ?? ''}',
      taskDeadline: '${json['task_deadline'] ?? json['taskDeadline'] ?? ''}',
      imageBytes: bytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'teacher_nip': teacherNip,
      'teacher_name': teacherName,
      'date_label': dateLabel,
      'subject': subject,
      'title': title,
      'material_summary': materialSummary,
      'class_name': className,
      'attendance_count': attendanceCount,
      'accent_color': _colorToHex(accentColor),
      'learning_points': learningPoints,
      'summary_paragraphs': summaryParagraphs,
      'progress_title': progressTitle,
      'progress_note': progressNote,
      'task_title': taskTitle,
      'task_deadline': taskDeadline,
      'image_base64': imageBytes == null ? null : base64Encode(imageBytes!),
    };
  }

  JournalEntry copyWith({
    int? id,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
    String? dateLabel,
    String? subject,
    String? title,
    String? materialSummary,
    String? className,
    int? attendanceCount,
    Color? accentColor,
    List<String>? learningPoints,
    List<String>? summaryParagraphs,
    String? progressTitle,
    String? progressNote,
    String? taskTitle,
    String? taskDeadline,
    Uint8List? imageBytes,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherNip: teacherNip ?? this.teacherNip,
      teacherName: teacherName ?? this.teacherName,
      dateLabel: dateLabel ?? this.dateLabel,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      materialSummary: materialSummary ?? this.materialSummary,
      className: className ?? this.className,
      attendanceCount: attendanceCount ?? this.attendanceCount,
      accentColor: accentColor ?? this.accentColor,
      learningPoints: learningPoints ?? this.learningPoints,
      summaryParagraphs: summaryParagraphs ?? this.summaryParagraphs,
      progressTitle: progressTitle ?? this.progressTitle,
      progressNote: progressNote ?? this.progressNote,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDeadline: taskDeadline ?? this.taskDeadline,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  static Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFF4D7CFF);
  }

  static String _colorToHex(Color color) {
    final rgb = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    return '#$rgb'.toUpperCase();
  }
}
