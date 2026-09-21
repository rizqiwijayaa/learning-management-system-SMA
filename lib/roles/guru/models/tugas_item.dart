class TugasItem {
  final int? id;
  final int? teacherId;
  final String teacherNip;
  final String teacherName;
  final String title;
  final String subject;
  final String date;
  final String type;
  final String description;
  final String attachmentName;
  final String attachmentData;
  final String attachmentMimeType;
  final int? durationMinutes;

  const TugasItem({
    this.id,
    this.teacherId,
    this.teacherNip = '',
    this.teacherName = '',
    required this.title,
    required this.subject,
    required this.date,
    required this.type,
    this.description = '',
    this.attachmentName = '',
    this.attachmentData = '',
    this.attachmentMimeType = '',
    this.durationMinutes,
  });

  factory TugasItem.fromJson(Map<String, dynamic> json) {
    return TugasItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      teacherId: json['teacher_id'] is int
          ? json['teacher_id'] as int
          : int.tryParse('${json['teacher_id'] ?? json['teacherId']}'),
      teacherNip: '${json['teacher_nip'] ?? json['teacherNip'] ?? ''}',
      teacherName: '${json['teacher_name'] ?? json['teacherName'] ?? ''}',
      title: '${json['title'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      date: '${json['date'] ?? ''}',
      type: '${json['type'] ?? 'tugas'}',
      description: '${json['description'] ?? ''}',
      attachmentName: '${json['attachment_name'] ?? ''}',
      attachmentData: '${json['attachment_data'] ?? ''}',
      attachmentMimeType: '${json['attachment_mime'] ?? ''}',
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes'] as int
          : int.tryParse('${json['duration_minutes']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'teacher_nip': teacherNip,
      'teacher_name': teacherName,
      'title': title,
      'subject': subject,
      'date': date,
      'type': type,
      'description': description,
      'attachment_name': attachmentName,
      'attachment_data': attachmentData,
      'attachment_mime': attachmentMimeType,
      'duration_minutes': durationMinutes,
    };
  }

  bool get hasAttachment =>
      attachmentName.trim().isNotEmpty && attachmentData.trim().isNotEmpty;

  TugasItem copyWith({
    int? id,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
    String? title,
    String? subject,
    String? date,
    String? type,
    String? description,
    String? attachmentName,
    String? attachmentData,
    String? attachmentMimeType,
    int? durationMinutes,
  }) {
    return TugasItem(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherNip: teacherNip ?? this.teacherNip,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentData: attachmentData ?? this.attachmentData,
      attachmentMimeType: attachmentMimeType ?? this.attachmentMimeType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
