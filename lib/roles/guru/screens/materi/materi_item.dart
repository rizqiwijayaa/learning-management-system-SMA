import 'dart:convert';

class MateriItem {
  final int? id;
  final int? teacherId;
  final String teacherNip;
  final String teacherName;
  final String title;
  final String subject;
  final String uploadDate;
  final String description;
  final String content;
  final List<MateriAttachment> attachments;

  const MateriItem({
    this.id,
    this.teacherId,
    this.teacherNip = '',
    this.teacherName = '',
    required this.title,
    required this.subject,
    required this.uploadDate,
    this.description = '',
    this.content = '',
    this.attachments = const [],
  });

  factory MateriItem.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments_json'] ?? json['attachments'];
    final attachments = _parseAttachments(rawAttachments);
    return MateriItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      teacherId: json['teacher_id'] is int
          ? json['teacher_id'] as int
          : int.tryParse('${json['teacher_id'] ?? json['teacherId']}'),
      teacherNip: '${json['teacher_nip'] ?? json['teacherNip'] ?? ''}',
      teacherName: '${json['teacher_name'] ?? json['teacherName'] ?? ''}',
      title: '${json['title'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      uploadDate: '${json['upload_date'] ?? json['uploadDate'] ?? ''}',
      description: '${json['description'] ?? ''}',
      content: '${json['content'] ?? ''}',
      attachments: attachments,
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
      'upload_date': uploadDate,
      'description': description,
      'content': content,
      'attachments_json': attachments.map((item) => item.toJson()).toList(growable: false),
    };
  }

  MateriItem copyWith({
    int? id,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
    String? title,
    String? subject,
    String? uploadDate,
    String? description,
    String? content,
    List<MateriAttachment>? attachments,
  }) {
    return MateriItem(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherNip: teacherNip ?? this.teacherNip,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      uploadDate: uploadDate ?? this.uploadDate,
      description: description ?? this.description,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
    );
  }

  static List<MateriAttachment> _parseAttachments(dynamic raw) {
    if (raw == null) return const [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => MateriAttachment.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }

    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((item) => MateriAttachment.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false);
        }
      } catch (_) {}
    }

    return const [];
  }
}

class MateriAttachment {
  final String name;
  final String mimeType;
  final String base64Data;
  final int sizeBytes;

  const MateriAttachment({
    required this.name,
    required this.mimeType,
    required this.base64Data,
    required this.sizeBytes,
  });

  factory MateriAttachment.fromJson(Map<String, dynamic> json) {
    return MateriAttachment(
      name: '${json['name'] ?? ''}',
      mimeType: '${json['mime_type'] ?? json['mimeType'] ?? ''}',
      base64Data: '${json['base64_data'] ?? json['base64Data'] ?? ''}',
      sizeBytes: json['size_bytes'] is int
          ? json['size_bytes'] as int
          : int.tryParse('${json['size_bytes'] ?? json['sizeBytes'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mime_type': mimeType,
      'base64_data': base64Data,
      'size_bytes': sizeBytes,
    };
  }

  bool get hasData => name.trim().isNotEmpty && base64Data.trim().isNotEmpty;
}
