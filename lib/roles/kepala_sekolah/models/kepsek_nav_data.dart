import 'package:lms_guru/roles/guru/models/curriculum_record.dart';
import 'package:lms_guru/roles/guru/models/humas_record.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/models/sarpras_record.dart';
import 'package:lms_guru/roles/guru/models/student_record.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/attendance_model.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';

class KepsekNavData {
  final int totalSiswa;
  final int totalSiswaAktif;
  final int totalSiswaMutasi;
  final int totalKelasSiswa;
  final int totalSarpras;
  final int sarprasRusak;
  final int sarprasAman;
  final int sarprasDamagePercentage;
  final int totalJurnal;
  final int totalKelasJurnal;
  final int avgAttendance;
  final int journalSyncPercentage;
  final int hadir;
  final int izin;
  final int alfa;
  final List<KepalaSekolahHighlight> sarprasHighlights;
  final List<KepalaSekolahHighlight> humasHighlights;
  final int totalHumasAgenda;
  final int humasPartnerCount;
  final int humasScheduledCount;
  final int humasOtherStatusCount;
  final List<KepalaSekolahHighlight> journalHighlights;
  final int totalMateri;
  final int mapelCount;
  final String schoolYear;
  final List<KepalaSekolahHighlight> kurikulumHighlights;
  final List<StudentRecord> students;
  final List<CurriculumRecord> curriculums;
  final List<SarprasRecord> sarprasRecords;
  final List<HumasRecord> humasRecords;
  final List<JournalEntry> journals;
  final List<AttendanceSummary> attendanceRecords;

  const KepsekNavData({
    required this.totalSiswa,
    required this.totalSiswaAktif,
    required this.totalSiswaMutasi,
    required this.totalKelasSiswa,
    required this.totalSarpras,
    required this.sarprasRusak,
    required this.sarprasAman,
    required this.sarprasDamagePercentage,
    required this.totalJurnal,
    required this.totalKelasJurnal,
    required this.avgAttendance,
    required this.journalSyncPercentage,
    required this.hadir,
    required this.izin,
    required this.alfa,
    required this.sarprasHighlights,
    required this.humasHighlights,
    required this.totalHumasAgenda,
    required this.humasPartnerCount,
    required this.humasScheduledCount,
    required this.humasOtherStatusCount,
    required this.journalHighlights,
    required this.totalMateri,
    required this.mapelCount,
    required this.schoolYear,
    required this.kurikulumHighlights,
    required this.students,
    required this.curriculums,
    required this.sarprasRecords,
    required this.humasRecords,
    required this.journals,
    required this.attendanceRecords,
  });
}
