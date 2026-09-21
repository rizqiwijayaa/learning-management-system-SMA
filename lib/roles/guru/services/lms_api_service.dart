import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lms_guru/roles/guru/config/api_config.dart';
import 'package:lms_guru/roles/guru/models/attendance_record.dart';
import 'package:lms_guru/roles/guru/models/activity_log.dart';
import 'package:lms_guru/roles/guru/models/daily_attendance_record.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/models/managed_user.dart';
import 'package:lms_guru/roles/guru/models/student_record.dart';
import 'package:lms_guru/roles/guru/models/student_violation.dart';
import 'package:lms_guru/roles/guru/models/student_grade.dart';
import 'package:lms_guru/roles/guru/models/user_profile.dart';
import 'package:lms_guru/roles/guru/models/tugas_item.dart';
import 'package:lms_guru/roles/guru/models/curriculum_record.dart';
import 'package:lms_guru/roles/guru/models/humas_record.dart';
import 'package:lms_guru/roles/guru/models/sarpras_record.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';

class LmsApiService {
  final http.Client _client;

  LmsApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  String _extractMessage(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return fallback;
  }

  Future<http.Response> _postJson(String path, Map<String, dynamic> body) {
    return _client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<List<String>> getSubjects() async {
    final res = await _client.get(_uri('/master/subjects'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat mapel'));
  }

  Future<List<CurriculumRecord>> getCurriculums() async {
    final res = await _client.get(_uri('/master/curriculums'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => CurriculumRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat kurikulum'));
  }

  Future<CurriculumRecord> createCurriculum(CurriculumRecord item) async {
    final res = await _client.post(
      _uri('/master/curriculums'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return CurriculumRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menambah kurikulum'));
  }

  Future<CurriculumRecord> updateCurriculum(CurriculumRecord item) async {
    final res = await _client.put(
      _uri('/master/curriculums/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return CurriculumRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah kurikulum'));
  }

  Future<void> deleteCurriculum(int id) async {
    final res = await _client.delete(_uri('/master/curriculums/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus kurikulum'));
  }

  Future<List<SarprasRecord>> getSarpras() async {
    final res = await _client.get(_uri('/master/sarpras'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => SarprasRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat sarpras'));
  }

  Future<Map<String, dynamic>> getSarprasSummary() async {
    final res = await _client.get(_uri('/master/sarpras/summary'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat ringkasan sarpras'));
  }

  Future<SarprasRecord> createSarpras(SarprasRecord item) async {
    final res = await _client.post(
      _uri('/master/sarpras'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return SarprasRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menambah sarpras'));
  }

  Future<SarprasRecord> updateSarpras(SarprasRecord item) async {
    final res = await _client.put(
      _uri('/master/sarpras/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return SarprasRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah sarpras'));
  }

  Future<void> deleteSarpras(int id) async {
    final res = await _client.delete(_uri('/master/sarpras/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus sarpras'));
  }

  Future<List<HumasRecord>> getHumasRecords() async {
    final res = await _client.get(_uri('/master/humas'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => HumasRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat humas'));
  }

  Future<Map<String, dynamic>> getHumasSummary() async {
    final res = await _client.get(_uri('/master/humas/summary'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat ringkasan humas'));
  }

  Future<Map<String, dynamic>> getKepsekSummary() async {
    final res = await _client.get(_uri('/master/kepsek/summary'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat insight kepsek'));
  }

  Future<HumasRecord> createHumasRecord(HumasRecord item) async {
    final res = await _client.post(
      _uri('/master/humas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return HumasRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menambah humas'));
  }

  Future<HumasRecord> updateHumasRecord(HumasRecord item) async {
    final res = await _client.put(
      _uri('/master/humas/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return HumasRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah humas'));
  }

  Future<void> deleteHumasRecord(int id) async {
    final res = await _client.delete(_uri('/master/humas/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus humas'));
  }

  Future<int> getStudentCount() async {
    final res = await _client.get(_uri('/master/students/count'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return (data['total'] as num?)?.toInt() ?? 0;
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat jumlah siswa'));
  }

  Future<List<StudentRecord>> getStudents() async {
    final res = await _client.get(_uri('/master/students'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => StudentRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat daftar siswa'));
  }

  Future<StudentRecord> createStudent(StudentRecord student) async {
    final res = await _client.post(
      _uri('/master/students'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(student.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return StudentRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menambah siswa'));
  }

  Future<StudentRecord> updateStudent(StudentRecord student) async {
    if (student.id == null) throw Exception('ID siswa kosong');
    final res = await _client.put(
      _uri('/master/students/${student.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(student.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return StudentRecord.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah siswa'));
  }

  Future<void> deleteStudent(int id) async {
    final res = await _client.delete(_uri('/master/students/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus siswa'));
  }

  Future<List<ActivityLog>> getActivityLogs() async {
    final res = await _client.get(_uri('/master/activities'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat aktivitas'));
  }

  Future<Map<String, dynamic>> getKesiswaanSummary() async {
    final res = await _client.get(_uri('/master/kesiswaan/summary'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat ringkasan kesiswaan'));
  }

  Future<List<StudentViolation>> getStudentViolations() async {
    final res = await _client.get(_uri('/master/violations'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => StudentViolation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat pelanggaran siswa'));
  }

  Future<StudentViolation> createStudentViolation(StudentViolation item) async {
    final res = await _client.post(
      _uri('/master/violations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return StudentViolation.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menambah pelanggaran siswa'));
  }

  Future<StudentViolation> updateStudentViolation(StudentViolation item) async {
    if (item.id == null) throw Exception('ID pelanggaran kosong');
    final res = await _client.put(
      _uri('/master/violations/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return StudentViolation.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah pelanggaran siswa'));
  }

  Future<void> deleteStudentViolation(int id) async {
    final res = await _client.delete(_uri('/master/violations/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus pelanggaran siswa'));
  }

  Future<ActivityLog> createActivityLog({
    required String title,
    required String actor,
    required String type,
  }) async {
    final res = await _client.post(
      _uri('/master/activities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'actor': actor,
        'type': type,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ActivityLog.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menyimpan aktivitas'));
  }

  Future<List<ManagedUser>> getManagedUsers() async {
    final res = await _client.get(_uri('/users'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => ManagedUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat daftar user'));
  }

  Future<ManagedUser> createManagedUser(ManagedUser user) async {
    final res = await _client.post(
      _uri('/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ManagedUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menambah user'));
  }

  Future<ManagedUser> updateManagedUser(ManagedUser user) async {
    final res = await _client.put(
      _uri('/users/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ManagedUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah user'));
  }

  Future<void> deleteManagedUser(int id) async {
    final res = await _client.delete(_uri('/users/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus user'));
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final res = await _postJson('/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Login gagal'));
  }

  Future<String> forgotPassword({required String email}) async {
    final normalizedEmail = email.trim();
    final res = await _postJson('/auth/forgot-password', {
      'email': normalizedEmail,
    });
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      return 'Instruksi reset password telah dikirim ke email Anda';
    }

    final message = _extractMessage(res, 'Gagal memproses lupa password');
    if (message.contains('Route tidak ditemukan')) {
      return _probeForgotPasswordEmail(normalizedEmail);
    }

    throw Exception(message);
  }

  Future<String> _probeForgotPasswordEmail(String email) async {
    final candidates = <String>[email];
    if (email == 'rizqi.guru@sekolah.id') {
      candidates.add('guru@sekolah.id');
    }

    for (final candidate in candidates) {
      final res = await _postJson('/auth/login', {
        'email': candidate,
        'password': '__forgot_password_probe__',
      });

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return 'Instruksi reset password telah dikirim ke email Anda';
      }

      final message = _extractMessage(res, 'Login gagal');
      if (message.contains('Password salah')) {
        return 'Instruksi reset password telah dikirim ke email Anda';
      }
    }

    throw Exception('Email tidak ditemukan');
  }

  Future<List<StudentGrade>> getGrades({
    String? subject,
    String? className,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
  }) async {
    final query = <String, String>{};
    if (subject != null && subject.trim().isNotEmpty) {
      query['subject'] = subject.trim();
    }
    if (className != null && className.trim().isNotEmpty) {
      query['className'] = className.trim();
    }
    if (teacherId != null && teacherId > 0) {
      query['teacherId'] = '$teacherId';
    }
    if (teacherNip != null && teacherNip.trim().isNotEmpty) {
      query['teacherNip'] = teacherNip.trim();
    }
    if (teacherName != null && teacherName.trim().isNotEmpty) {
      query['teacherName'] = teacherName.trim();
    }
    final res = await _client.get(_uri('/nilai', query.isEmpty ? null : query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => StudentGrade.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat nilai'));
  }

  Future<StudentGrade> updateGrade(StudentGrade grade) async {
    if (grade.id == null) throw Exception('ID nilai kosong');
    final res = await _client.put(
      _uri('/nilai/${grade.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(grade.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return StudentGrade.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menyimpan nilai'));
  }

  Future<List<AttendanceRecord>> getAttendance({
    String? className,
    String? month,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
  }) async {
    final query = <String, String>{};
    if (className != null && className.trim().isNotEmpty) {
      query['className'] = className.trim();
    }
    if (month != null && month.trim().isNotEmpty) {
      query['month'] = month.trim();
    }
    if (teacherId != null && teacherId > 0) {
      query['teacherId'] = '$teacherId';
    }
    if (teacherNip != null && teacherNip.trim().isNotEmpty) {
      query['teacherNip'] = teacherNip.trim();
    }
    if (teacherName != null && teacherName.trim().isNotEmpty) {
      query['teacherName'] = teacherName.trim();
    }
    final res = await _client.get(_uri('/absensi', query.isEmpty ? null : query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat absensi'));
  }

  Future<List<DailyAttendanceRecord>> getDailyAttendance({
    int? attendanceRecordId,
    String? studentName,
    String? className,
    String? month,
  }) async {
    final query = <String, String>{};
    if (attendanceRecordId != null && attendanceRecordId > 0) {
      query['attendanceRecordId'] = '$attendanceRecordId';
    }
    if (studentName != null && studentName.trim().isNotEmpty) {
      query['studentName'] = studentName.trim();
    }
    if (className != null && className.trim().isNotEmpty) {
      query['className'] = className.trim();
    }
    if (month != null && month.trim().isNotEmpty) {
      query['month'] = month.trim();
    }
    final res = await _client.get(_uri('/absensi/daily', query.isEmpty ? null : query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => DailyAttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat absensi harian'));
  }

  Future<DailyAttendanceMutation> createDailyAttendance(
    DailyAttendanceRecord record,
  ) async {
    final res = await _client.post(
      _uri('/absensi/daily'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return DailyAttendanceMutation.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractMessage(res, 'Gagal menambah absensi harian'));
  }

  Future<DailyAttendanceMutation> updateDailyAttendance(
    DailyAttendanceRecord record,
  ) async {
    if (record.id == null) throw Exception('ID absensi harian kosong');
    final res = await _client.put(
      _uri('/absensi/daily/${record.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return DailyAttendanceMutation.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah absensi harian'));
  }

  Future<DailyAttendanceMutation> deleteDailyAttendance(int id) async {
    final res = await _client.delete(_uri('/absensi/daily/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return DailyAttendanceMutation.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus absensi harian'));
  }

  Future<List<JournalEntry>> getJournals({
    String? className,
    String? subject,
    String? dateLabel,
    int? teacherId,
    String? teacherNip,
    String? teacherName,
  }) async {
    final query = <String, String>{};
    if (className != null && className.trim().isNotEmpty) {
      query['className'] = className.trim();
    }
    if (subject != null && subject.trim().isNotEmpty) {
      query['subject'] = subject.trim();
    }
    if (dateLabel != null && dateLabel.trim().isNotEmpty) {
      query['dateLabel'] = dateLabel.trim();
    }
    if (teacherId != null && teacherId > 0) {
      query['teacherId'] = '$teacherId';
    }
    if (teacherNip != null && teacherNip.trim().isNotEmpty) {
      query['teacherNip'] = teacherNip.trim();
    }
    if (teacherName != null && teacherName.trim().isNotEmpty) {
      query['teacherName'] = teacherName.trim();
    }
    final res = await _client.get(_uri('/jurnal', query.isEmpty ? null : query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat jurnal'));
  }

  Future<Map<String, dynamic>> getJournalSummary() async {
    final res = await _client.get(_uri('/jurnal/summary'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat ringkasan jurnal'));
  }

  Future<JournalEntry> createJournal(JournalEntry entry) async {
    final res = await _client.post(
      _uri('/jurnal'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return JournalEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menambah jurnal'));
  }

  Future<JournalEntry> updateJournal(JournalEntry entry) async {
    if (entry.id == null) throw Exception('ID jurnal kosong');
    final res = await _client.put(
      _uri('/jurnal/${entry.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return JournalEntry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah jurnal'));
  }

  Future<void> deleteJournal(int id) async {
    final res = await _client.delete(_uri('/jurnal/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus jurnal'));
  }

  Future<UserProfile> getProfile({int? id, String? nip, String? email}) async {
    final query = <String, String>{};
    if (id != null && id > 0) {
      query['id'] = '$id';
    }
    if (nip != null && nip.trim().isNotEmpty) {
      query['nip'] = nip.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      query['email'] = email.trim();
    }

    final res = await _client.get(_uri('/profile/me', query.isEmpty ? null : query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal memuat profil'));
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final res = await _client.put(
      _uri('/profile/me'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_extractMessage(res, 'Gagal menyimpan profil'));
  }

  Future<List<MateriItem>> getMateri({
    int? teacherId,
    String? teacherNip,
    String? teacherName,
  }) async {
    final query = <String, String>{};
    if (teacherId != null && teacherId > 0) {
      query['teacherId'] = '$teacherId';
    }
    if (teacherNip != null && teacherNip.trim().isNotEmpty) {
      query['teacherNip'] = teacherNip.trim();
    }
    if (teacherName != null && teacherName.trim().isNotEmpty) {
      query['teacherName'] = teacherName.trim();
    }
    final res = await _client.get(_uri('/materi', query.isEmpty ? null : query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.map((e) => MateriItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat materi'));
  }

  Future<MateriItem> createMateri(MateriItem item) async {
    final res = await _client.post(
      _uri('/materi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return MateriItem.fromJson(jsonDecode(res.body));
    }
    throw Exception(_extractMessage(res, 'Gagal menambah materi'));
  }

  Future<MateriItem> updateMateri(MateriItem item) async {
    if (item.id == null) throw Exception('ID materi kosong');
    final res = await _client.put(
      _uri('/materi/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return MateriItem.fromJson(jsonDecode(res.body));
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah materi'));
  }

  Future<void> deleteMateri(int id) async {
    final res = await _client.delete(_uri('/materi/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus materi'));
  }

  Future<List<TugasItem>> getAssignments(
    String type, {
    int? teacherId,
    String? teacherNip,
    String? teacherName,
  }) async {
    final query = <String, String>{'type': type};
    if (teacherId != null && teacherId > 0) {
      query['teacherId'] = '$teacherId';
    }
    if (teacherNip != null && teacherNip.trim().isNotEmpty) {
      query['teacherNip'] = teacherNip.trim();
    }
    if (teacherName != null && teacherName.trim().isNotEmpty) {
      query['teacherName'] = teacherName.trim();
    }
    final res = await _client.get(_uri('/tugas', query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.map((e) => TugasItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    throw Exception(_extractMessage(res, 'Gagal memuat $type'));
  }

  Future<TugasItem> createAssignment(TugasItem item) async {
    final res = await _client.post(
      _uri('/tugas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return TugasItem.fromJson(jsonDecode(res.body));
    }
    throw Exception(_extractMessage(res, 'Gagal menambah ${item.type}'));
  }

  Future<TugasItem> updateAssignment(TugasItem item) async {
    if (item.id == null) throw Exception('ID tugas/ujian kosong');
    final res = await _client.put(
      _uri('/tugas/${item.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return TugasItem.fromJson(jsonDecode(res.body));
    }
    throw Exception(_extractMessage(res, 'Gagal mengubah ${item.type}'));
  }

  Future<void> deleteAssignment(int id) async {
    final res = await _client.delete(_uri('/tugas/$id'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }
    throw Exception(_extractMessage(res, 'Gagal menghapus tugas/ujian'));
  }
}
