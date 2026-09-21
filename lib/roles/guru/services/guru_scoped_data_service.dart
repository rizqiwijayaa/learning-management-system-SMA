import 'package:lms_guru/roles/guru/models/attendance_record.dart';
import 'package:lms_guru/roles/guru/models/curriculum_record.dart';
import 'package:lms_guru/roles/guru/models/daily_attendance_record.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/models/student_grade.dart';
import 'package:lms_guru/roles/guru/models/student_record.dart';
import 'package:lms_guru/roles/guru/models/tugas_item.dart';
import 'package:lms_guru/roles/guru/models/user_profile.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';

class GuruScopedDataService {
  GuruScopedDataService({LmsApiService? api}) : _api = api ?? LmsApiService();

  final LmsApiService _api;

  Future<List<MateriItem>> getMateri() async {
    final scope = await _resolveScope();
    final items = await _api.getMateri();
    return items.where((item) {
      if (_matchesTeacher(
        teacherId: item.teacherId,
        teacherNip: item.teacherNip,
        teacherName: item.teacherName,
        scope: scope,
      )) {
        return true;
      }
      return _matchesSubject(item.subject, scope);
    }).toList();
  }

  Future<List<TugasItem>> getAssignments(String type) async {
    final scope = await _resolveScope();
    final items = await _api.getAssignments(type);
    return items.where((item) {
      if (_matchesTeacher(
        teacherId: item.teacherId,
        teacherNip: item.teacherNip,
        teacherName: item.teacherName,
        scope: scope,
      )) {
        return true;
      }
      return _matchesSubject(item.subject, scope);
    }).toList();
  }

  Future<List<StudentGrade>> getGrades() async {
    final scope = await _resolveScope();
    final items = await _api.getGrades();
    return items.where((item) {
      if (_matchesTeacher(
        teacherId: item.teacherId,
        teacherNip: item.teacherNip,
        teacherName: item.teacherName,
        scope: scope,
      )) {
        return true;
      }
      return _matchesSubject(item.subject, scope);
    }).toList();
  }

  Future<List<JournalEntry>> getJournals() async {
    final scope = await _resolveScope();
    final items = await _api.getJournals();
    return items.where((item) {
      if (_matchesTeacher(
        teacherId: item.teacherId,
        teacherNip: item.teacherNip,
        teacherName: item.teacherName,
        scope: scope,
      )) {
        return true;
      }
      if (!_matchesSubject(item.subject, scope)) return false;
      return _matchesClass(item.className, scope);
    }).toList();
  }

  Future<List<AttendanceRecord>> getAttendance() async {
    final scope = await _resolveScope();
    final items = await _api.getAttendance();
    return items.where((item) {
      if (_matchesTeacher(
        teacherId: item.teacherId,
        teacherNip: item.teacherNip,
        teacherName: item.teacherName,
        scope: scope,
      )) {
        return true;
      }
      return _matchesClass(item.className, scope);
    }).toList();
  }

  Future<List<DailyAttendanceRecord>> getDailyAttendance(
    AttendanceRecord student,
  ) async {
    return _api.getDailyAttendance(
      attendanceRecordId: student.id,
      studentName: student.studentName,
      className: student.className,
      month: student.monthLabel,
    );
  }

  Future<List<StudentRecord>> getStudents() async {
    final scope = await _resolveScope();
    final items = await _api.getStudents();
    return items.where((item) => _matchesClass(item.className, scope)).toList();
  }

  Future<int> getStudentCount() async {
    final students = await getStudents();
    return students.length;
  }

  Future<_TeacherScope?> _resolveScope() async {
    await ProfileStore.instance.ensureLoaded();
    final profile = ProfileStore.instance.profile;
    if (profile == null || profile.name.trim().isEmpty) return null;

    final curriculums = await _api.getCurriculums();
    return _TeacherScope.fromProfile(profile, curriculums);
  }

  bool _matchesSubject(String subject, _TeacherScope? scope) {
    if (scope == null || scope.subjects.isEmpty) return true;
    return scope.subjects.contains(_normalize(subject));
  }

  bool _matchesTeacher({
    required int? teacherId,
    required String teacherNip,
    required String teacherName,
    required _TeacherScope? scope,
  }) {
    if (scope == null) return false;

    if (teacherId != null && scope.teacherId != null && teacherId == scope.teacherId) {
      return true;
    }

    final normalizedNip = _normalize(teacherNip);
    if (normalizedNip.isNotEmpty &&
        scope.teacherNip.isNotEmpty &&
        normalizedNip == scope.teacherNip) {
      return true;
    }

    final normalizedName = _normalize(teacherName);
    if (normalizedName.isNotEmpty &&
        scope.teacherName.isNotEmpty &&
        normalizedName == scope.teacherName) {
      return true;
    }

    return false;
  }

  bool _matchesClass(String className, _TeacherScope? scope) {
    if (scope == null || scope.classPrefixes.isEmpty) return true;
    final normalized = _normalize(className);
    return scope.classPrefixes.any(normalized.startsWith);
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _TeacherScope {
  const _TeacherScope({
    required this.teacherId,
    required this.teacherNip,
    required this.teacherName,
    required this.subjects,
    required this.classPrefixes,
  });

  final int? teacherId;
  final String teacherNip;
  final String teacherName;
  final Set<String> subjects;
  final Set<String> classPrefixes;

  static _TeacherScope? fromProfile(
    UserProfile profile,
    List<CurriculumRecord> curriculums,
  ) {
    final teacherName = profile.name.trim().toLowerCase();
    if (teacherName.isEmpty) return null;

    final relevant = curriculums.where((item) {
      final teacher = item.teacher.trim().toLowerCase();
      return teacher.isNotEmpty && teacher == teacherName;
    }).toList();

    if (relevant.isEmpty) return null;

    final subjects = relevant
        .map((item) => item.subject.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    final classPrefixes = relevant
        .map((item) => '${item.grade} ${item.major}'.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    return _TeacherScope(
      teacherId: profile.id,
      teacherNip: profile.nip.trim().toLowerCase(),
      teacherName: teacherName,
      subjects: subjects,
      classPrefixes: classPrefixes,
    );
  }
}
