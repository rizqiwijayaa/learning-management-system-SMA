import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/screens/auth/login_page.dart';
import 'package:lms_guru/roles/guru/models/user_profile.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/models/curriculum_record.dart';
import 'package:lms_guru/roles/guru/models/managed_user.dart';
import 'package:lms_guru/roles/guru/models/sarpras_record.dart';
import 'package:lms_guru/roles/guru/models/humas_record.dart';
import 'package:lms_guru/roles/guru/models/student_record.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/attendance_model.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/kepsek_nav_data.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/dashboard_models.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/hero_section.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/stat_cards.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/menu_section.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/board_cards.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/bottom_nav.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kesiswaan/kesiswaan_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kurikulum/kurikulum_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/sarpras/sarpras_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/humas/humas_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/absensi/absensi_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/profile_page.dart';

class KepalaSekolahDashboardPage extends StatefulWidget {
  const KepalaSekolahDashboardPage({super.key});

  @override
  State<KepalaSekolahDashboardPage> createState() =>
      _KepalaSekolahDashboardPageState();
}

class _KepalaSekolahDashboardPageState
    extends State<KepalaSekolahDashboardPage> {
  final LmsApiService _api = LmsApiService();
  final ProfileStore _profileStore = ProfileStore.instance;

  int _currentNavIndex = 0;
  int _totalSiswa = 0;
  int _totalGuru = 0;
  int _totalSarpras = 0;
  int _sarprasRusak = 0;
  int _sarprasAman = 0;
  int _sarprasDamagePercentage = 0;
  int _totalMateri = 0;
  int _totalJurnal = 0;
  int _totalKelasJurnal = 0;
  int _avgAttendance = 0;
  int _journalSyncPercentage = 0;
  int _totalHumasAgenda = 0;
  int _humasPartnerCount = 0;
  int _humasScheduledCount = 0;
  int _humasOtherStatusCount = 0;
  List<ComparisonItem> _summaryComparisonInsights = const [];
  List<SnapshotItem> _summaryExecutiveSnapshots = const [];
  List<InsightItem> _summaryPriorityInsights = const [];
  List<CrossModuleItem> _summaryCrossModuleInsights = const [];
  List<ManagedUser> _managedUsers = const [];
  List<StudentRecord> _studentRecords = const [];
  List<MateriItem> _materiItems = const [];
  List<CurriculumRecord> _curriculumItems = const [];
  List<SarprasRecord> _sarprasRecords = const [];
  List<HumasRecord> _humasRecords = const [];
  List<JournalEntry> _journalEntries = const [];
  List<AttendanceSummary> _attendanceRecords = const [];

  List<IssueItem> get _sarprasIssues => _sarprasRecords
      .where((item) => item.itemCondition.trim().toLowerCase() != 'baik')
      .take(3)
      .map(
        (item) => IssueItem(
          title: item.itemName,
          status: item.itemCondition,
        ),
      )
      .toList(growable: false);

  List<EventItem> get _humasEvents => _humasRecords
      .take(3)
      .map(
        (item) => EventItem(
          title: item.title,
          schedule: item.scheduleDate,
          location: item.location,
        ),
      )
      .toList(growable: false);

  List<ComparisonItem> get _comparisonInsights {
    final studentByName = <String, StudentRecord>{
      for (final item in _studentRecords) _normalizeKey(item.name): item,
    };
    final classStats = <String, List<int>>{};
    final majorStats = <String, List<int>>{};

    for (final item in _attendanceRecords) {
      final student = studentByName[_normalizeKey(item.studentName)];
      if (student == null) continue;

      final className = student.className.trim().isEmpty ? '-' : student.className.trim();
      final major = student.major.trim().isEmpty ? '-' : student.major.trim();

      final classBox = classStats.putIfAbsent(className, () => [0, 0, 0, 0]);
      classBox[0] += item.presentDays;
      classBox[1] += item.izinDays;
      classBox[2] += item.alfaDays;
      classBox[3] += 1;

      final majorBox = majorStats.putIfAbsent(major, () => [0, 0, 0, 0]);
      majorBox[0] += item.presentDays;
      majorBox[1] += item.izinDays;
      majorBox[2] += item.alfaDays;
      majorBox[3] += 1;
    }

    String attendanceBadge(List<int> values) {
      final total = values[0] + values[1] + values[2];
      if (total <= 0) return '0%';
      return '${((values[0] / total) * 100).round()}%';
    }

    MapEntry<String, List<int>>? highestAttendanceClass;
    MapEntry<String, List<int>>? highestAttentionClass;
    for (final entry in classStats.entries) {
      if (highestAttendanceClass == null) {
        highestAttendanceClass = entry;
      } else {
        final currentTotal = entry.value[0] + entry.value[1] + entry.value[2];
        final bestTotal = highestAttendanceClass.value[0] +
            highestAttendanceClass.value[1] +
            highestAttendanceClass.value[2];
        final currentRate = currentTotal == 0 ? 0.0 : entry.value[0] / currentTotal;
        final bestRate = bestTotal == 0
            ? 0.0
            : highestAttendanceClass.value[0] / bestTotal;
        if (currentRate > bestRate) highestAttendanceClass = entry;
      }

      if (highestAttentionClass == null ||
          (entry.value[1] + entry.value[2]) >
              (highestAttentionClass.value[1] + highestAttentionClass.value[2])) {
        highestAttentionClass = entry;
      }
    }

    MapEntry<String, List<int>>? largestMajor;
    MapEntry<String, List<int>>? highestAttentionMajor;
    for (final entry in majorStats.entries) {
      if (largestMajor == null || entry.value[3] > largestMajor.value[3]) {
        largestMajor = entry;
      }
      if (highestAttentionMajor == null ||
          (entry.value[1] + entry.value[2]) >
              (highestAttentionMajor.value[1] + highestAttentionMajor.value[2])) {
        highestAttentionMajor = entry;
      }
    }

    if (_summaryComparisonInsights.isNotEmpty) {
      return _summaryComparisonInsights;
    }

    return [
      ComparisonItem(
        title: highestAttendanceClass == null
            ? 'Belum ada pembanding kelas'
            : 'Kelas dengan hadir tertinggi: ${highestAttendanceClass.key}',
        subtitle: highestAttendanceClass == null
            ? 'Data absensi per kelas akan tampil setelah rekap tersedia.'
            : '${highestAttendanceClass.value[0]} hadir dari ${highestAttendanceClass.value[0] + highestAttendanceClass.value[1] + highestAttendanceClass.value[2]} catatan absensi.',
        badge: highestAttendanceClass == null
            ? '-'
            : attendanceBadge(highestAttendanceClass.value),
      ),
      ComparisonItem(
        title: highestAttentionClass == null
            ? 'Belum ada kelas atensi'
            : 'Kelas perlu atensi: ${highestAttentionClass.key}',
        subtitle: highestAttentionClass == null
            ? 'Perbandingan izin dan alfa akan muncul di sini.'
            : '${highestAttentionClass.value[1] + highestAttentionClass.value[2]} catatan izin/alfa perlu ditindaklanjuti.',
        badge: highestAttentionClass == null
            ? '-'
            : '${highestAttentionClass.value[1] + highestAttentionClass.value[2]} atensi',
      ),
      ComparisonItem(
        title: largestMajor == null
            ? 'Belum ada data jurusan'
            : 'Jurusan dengan populasi terbesar: ${largestMajor.key}',
        subtitle: largestMajor == null
            ? 'Sebaran jurusan akan muncul setelah data siswa terbaca.'
            : '${largestMajor.value[3]} siswa aktif dan mutasi tercatat pada jurusan ini.',
        badge: largestMajor == null ? '-' : '${largestMajor.value[3]} siswa',
      ),
      ComparisonItem(
        title: highestAttentionMajor == null
            ? 'Belum ada jurusan atensi'
            : 'Jurusan dengan atensi tertinggi: ${highestAttentionMajor.key}',
        subtitle: highestAttentionMajor == null
            ? 'Tren disiplin per jurusan akan tampil di sini.'
            : '${highestAttentionMajor.value[1] + highestAttentionMajor.value[2]} izin/alfa terkumpul di jurusan ini.',
        badge: highestAttentionMajor == null
            ? '-'
            : '${highestAttentionMajor.value[1] + highestAttentionMajor.value[2]} catatan',
      ),
    ];
  }

  List<SnapshotItem> get _executiveSnapshots {
    final siswaAtensi = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.izinDays + item.alfaDays,
    );
    final kesiapanSarpras = _totalSarpras == 0
        ? 0
        : ((_sarprasAman / _totalSarpras) * 100).round();

    if (_summaryExecutiveSnapshots.isNotEmpty) {
      return _summaryExecutiveSnapshots;
    }

    return [
      SnapshotItem(
        label: 'Kelas Terpantau',
        value: '$_totalKelasJurnal',
        note: 'kelas muncul pada jurnal guru',
      ),
      SnapshotItem(
        label: 'Mapel Aktif',
        value: '${_curriculumItems.map((item) => item.subject.trim()).where((item) => item.isNotEmpty).toSet().length}',
        note: 'mata pelajaran pada kurikulum',
      ),
      SnapshotItem(
        label: 'Atensi Siswa',
        value: '$siswaAtensi',
        note: 'izin dan alfa perlu tindak lanjut',
      ),
      SnapshotItem(
        label: 'Sarpras Aman',
        value: '$kesiapanSarpras%',
        note: 'fasilitas dalam kondisi baik',
      ),
    ];
  }

  List<InsightItem> get _priorityInsights {
    final siswaAtensi = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.izinDays + item.alfaDays,
    );
    final lowSync = _journalSyncPercentage < 70;
    final items = <InsightItem>[
      InsightItem(
        title: 'Sarpras rusak perlu keputusan perbaikan',
        description:
            '$_sarprasRusak fasilitas masih tercatat rusak dan berpotensi mengganggu kegiatan belajar.',
        badge: 'Sarpras',
      ),
      InsightItem(
        title: 'Catatan izin dan alfa perlu pembinaan',
        description:
            '$siswaAtensi catatan absensi non-hadir perlu dibahas bersama wali kelas dan kesiswaan.',
        badge: 'Absensi',
      ),
      InsightItem(
        title: 'Agenda humas di luar jadwal perlu kontrol',
        description:
            '$_humasOtherStatusCount agenda humas tidak berada pada status terjadwal dan perlu dipastikan progresnya.',
        badge: 'Humas',
      ),
    ];

    if (lowSync) {
      items.add(
        InsightItem(
          title: 'Sinkron jurnal dan materi masih rendah',
          description:
              'Sinkronisasi baru $_journalSyncPercentage%, sehingga pemantauan kurikulum dan jurnal perlu diperkuat.',
          badge: 'Kurikulum',
        ),
      );
    }

    if (_summaryPriorityInsights.isNotEmpty) {
      return _summaryPriorityInsights;
    }

    return items.take(4).toList(growable: false);
  }

  List<CrossModuleItem> get _crossModuleInsights {
    final siswaAtensi = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.izinDays + item.alfaDays,
    );
    final atensiPercent = _totalSiswa == 0 ? 0 : ((siswaAtensi / _totalSiswa) * 100).round();

    if (_summaryCrossModuleInsights.isNotEmpty) {
      return _summaryCrossModuleInsights;
    }

    return [
      CrossModuleItem(
        title: 'Absensi + Kesiswaan',
        value: '$atensiPercent%',
        note:
            '$siswaAtensi catatan izin/alfa dibanding $_totalSiswa siswa perlu dijadikan fokus pembinaan.',
      ),
      CrossModuleItem(
        title: 'Jurnal + Kurikulum',
        value: '$_journalSyncPercentage%',
        note:
            'Sinkronisasi jurnal terhadap materi menunjukkan konsistensi dokumentasi pembelajaran lintas modul.',
      ),
      CrossModuleItem(
        title: 'Sarpras + Humas',
        value: '${_sarprasRusak + _humasScheduledCount}',
        note:
            'Gabungan kebutuhan sarpras rusak dan agenda humas terjadwal membantu membaca kesiapan operasional sekolah.',
      ),
      CrossModuleItem(
        title: 'Kelas + Jurnal',
        value: '$_totalKelasJurnal',
        note:
            'Jumlah kelas yang tercatat di jurnal dibanding sebaran siswa membantu kepala sekolah membaca cakupan pengawasan.',
      ),
    ];
  }

  Widget _buildDashboardColumns({
    required bool isWide,
    required List<Widget> children,
  }) {
    if (!isWide) {
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: children,
      );
    }

    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      final item = Padding(
        padding: EdgeInsets.only(bottom: index < children.length - 2 ? 14 : 0),
        child: children[index],
      );

      if (index.isEven) {
        leftColumn.add(item);
      } else {
        rightColumn.add(item);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: leftColumn,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rightColumn,
          ),
        ),
      ],
    );
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<T> _guard<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Ambil NIP dari store untuk memastikan kita mengambil profil yang benar dari DB
      final currentNip = _profileStore.profile?.nip;

      final results = await Future.wait<dynamic>([
        _guard<List<StudentRecord>>(_api.getStudents(), const []),
        _guard<List<ManagedUser>>(_api.getManagedUsers(), const []),
        _guard<List<MateriItem>>(_api.getMateri(), const []),
        _guard<List<SarprasRecord>>(_api.getSarpras(), const []),
        _guard<Map<String, dynamic>>(
          _api.getSarprasSummary(),
          const <String, dynamic>{},
        ),
        _guard<List<HumasRecord>>(_api.getHumasRecords(), const []),
        _guard<Map<String, dynamic>>(
          _api.getHumasSummary(),
          const <String, dynamic>{},
        ),
        _guard<List<JournalEntry>>(_api.getJournals(), const []),
        _guard<Map<String, dynamic>>(
          _api.getJournalSummary(),
          const <String, dynamic>{},
        ),
        _guard<Map<String, dynamic>>(
          _api.getKepsekSummary(),
          const <String, dynamic>{},
        ),
        _guard<List<dynamic>>(_api.getAttendance(), const []),
        _guard<List<CurriculumRecord>>(_api.getCurriculums(), const []),
        // Pastikan API menerima parameter NIP
        _guard<UserProfile?>(
          _api.getProfile(nip: currentNip),
          null,
        ),
      ]);

      if (!mounted) return;

      final List<StudentRecord> students = results[0] is List
          ? List<StudentRecord>.from(results[0] as Iterable)
          : [];
      final List<ManagedUser> users = results[1] is List
          ? List<ManagedUser>.from(results[1] as Iterable)
          : [];
      final List<MateriItem> materi = results[2] is List
          ? List<MateriItem>.from(results[2] as Iterable)
          : [];
      final List<SarprasRecord> sarpras = results[3] is List
          ? List<SarprasRecord>.from(results[3] as Iterable)
          : [];
      final Map<String, dynamic> sarprasSummary = results[4] is Map<String, dynamic>
          ? Map<String, dynamic>.from(results[4] as Map<String, dynamic>)
          : const <String, dynamic>{};
      final List<HumasRecord> humas = results[5] is List
          ? List<HumasRecord>.from(results[5] as Iterable)
          : [];
      final Map<String, dynamic> humasSummary = results[6] is Map<String, dynamic>
          ? Map<String, dynamic>.from(results[6] as Map<String, dynamic>)
          : const <String, dynamic>{};
      final List<JournalEntry> journals = results[7] is List
          ? List<JournalEntry>.from(results[7] as Iterable)
          : [];
      final Map<String, dynamic> journalSummary = results[8] is Map<String, dynamic>
          ? Map<String, dynamic>.from(results[8] as Map<String, dynamic>)
          : const <String, dynamic>{};
      final Map<String, dynamic> kepsekSummary = results[9] is Map<String, dynamic>
          ? Map<String, dynamic>.from(results[9] as Map<String, dynamic>)
          : const <String, dynamic>{};
      final List<AttendanceSummary> attendance = results[10] is List
          ? (results[10] as List).map((e) {
              if (e is AttendanceSummary) return e;
              final dynamic d =
                  e; // Casting ke dynamic untuk mengambil properti
              return AttendanceSummary(
                studentName: d.studentName?.toString() ?? '',
                presentDays: d.presentDays is int ? d.presentDays : 0,
                izinDays: d.izinDays is int ? d.izinDays : 0,
                alfaDays: d.alfaDays is int ? d.alfaDays : 0,
              );
            }).toList()
          : [];
      final List<CurriculumRecord> curriculums = results[11] is List
          ? List<CurriculumRecord>.from(results[11] as Iterable)
          : [];
      final UserProfile? updatedProfile = results[12] is UserProfile
          ? results[12] as UserProfile
          : null;

      setState(() {
        // Update ProfileStore agar data di seluruh aplikasi sinkron
        if (updatedProfile != null) {
          // Pastikan data profil dari database benar-benar menggantikan data lama di state management
          _profileStore.setProfile(
            UserProfile(
              id: updatedProfile.id,
              name: updatedProfile.name,
              role: 'Kepala Sekolah',
              nip: updatedProfile.nip,
              email: updatedProfile.email,
              phone: updatedProfile.phone,
              avatarBase64: updatedProfile.avatarBase64,
            ),
          );
        }
        _studentRecords = students;
        _totalSiswa = students.length;
        _managedUsers = users;
        _totalGuru = users
            .where(
              (user) =>
                  user.role.trim().toLowerCase() == 'guru' &&
                  user.status.trim().toLowerCase() == 'aktif',
            )
            .length;
        _totalMateri = materi.length;
        _sarprasRecords = sarpras;
        _totalSarpras = (sarprasSummary['totalSarpras'] as num?)?.toInt() ?? sarpras.length;
        _sarprasRusak = (sarprasSummary['damagedCount'] as num?)?.toInt() ??
            sarpras.where((item) => item.itemCondition.trim().toLowerCase() != 'baik').length;
        _sarprasAman = (sarprasSummary['safeCount'] as num?)?.toInt() ??
            sarpras.where((item) => item.itemCondition.trim().toLowerCase() == 'baik').length;
        _sarprasDamagePercentage =
            (sarprasSummary['damagePercentage'] as num?)?.toInt() ?? 0;
        _humasRecords = humas;
        _totalHumasAgenda = (humasSummary['totalAgenda'] as num?)?.toInt() ?? humas.length;
        _humasPartnerCount = (humasSummary['partnerCount'] as num?)?.toInt() ??
            humas.map((item) => item.partner.trim()).where((item) => item.isNotEmpty).toSet().length;
        _humasScheduledCount = (humasSummary['scheduledCount'] as num?)?.toInt() ??
            humas.where((item) => item.status.trim().toLowerCase() == 'terjadwal').length;
        _humasOtherStatusCount = (humasSummary['otherStatusCount'] as num?)?.toInt() ?? 0;
        _totalJurnal = (journalSummary['totalJurnal'] as num?)?.toInt() ?? journals.length;
        _totalKelasJurnal = (journalSummary['totalClasses'] as num?)?.toInt() ??
            journals.map((item) => item.className.trim()).where((item) => item.isNotEmpty).toSet().length;
        _avgAttendance = (journalSummary['avgAttendance'] as num?)?.toInt() ?? 0;
        _journalSyncPercentage =
            (journalSummary['syncMaterialPercentage'] as num?)?.toInt() ?? 0;
        _materiItems = materi;
        _curriculumItems = curriculums;
        _journalEntries = journals;
        _attendanceRecords = attendance;
        _summaryComparisonInsights = _parseComparisonItems(
          kepsekSummary['comparisonInsights'],
        );
        _summaryExecutiveSnapshots = _parseSnapshotItems(
          kepsekSummary['executiveSnapshots'],
        );
        _summaryPriorityInsights = _parseInsightItems(
          kepsekSummary['priorityInsights'],
        );
        _summaryCrossModuleInsights = _parseCrossModuleItems(
          kepsekSummary['crossModuleInsights'],
        );
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  void _logout() {
    ProfileStore.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  List<ComparisonItem> _parseComparisonItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => ComparisonItem(
            title: '${item['title'] ?? ''}',
            subtitle: '${item['subtitle'] ?? ''}',
            badge: '${item['badge'] ?? ''}',
          ),
        )
        .where((item) => item.title.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<SnapshotItem> _parseSnapshotItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => SnapshotItem(
            label: '${item['label'] ?? ''}',
            value: '${item['value'] ?? ''}',
            note: '${item['note'] ?? ''}',
          ),
        )
        .where((item) => item.label.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<InsightItem> _parseInsightItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => InsightItem(
            title: '${item['title'] ?? ''}',
            description: '${item['description'] ?? ''}',
            badge: '${item['badge'] ?? ''}',
          ),
        )
        .where((item) => item.title.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<CrossModuleItem> _parseCrossModuleItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => CrossModuleItem(
            title: '${item['title'] ?? ''}',
            value: '${item['value'] ?? ''}',
            note: '${item['note'] ?? ''}',
          ),
        )
        .where((item) => item.title.trim().isNotEmpty)
        .toList(growable: false);
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfilePage())).then((_) {
      _loadDashboardData(); // Memuat ulang data saat kembali dari halaman profil
    });
  }

  void _openKesiswaan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KesiswaanPage(
          totalSiswa: _totalSiswa,
          navData: _buildNavData(),
        ),
      ),
    );
  }

  void _openKurikulum() {
    final mapelCount = _curriculumItems
        .map((item) => item.subject.trim())
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .length;

    final highlights = _materiItems.take(3).map((item) {
      return KepalaSekolahHighlight(
        title: item.title,
        description:
            'Materi ${item.subject} menjadi bagian dari aktivitas kurikulum terbaru.',
        badge: item.subject,
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KurikulumPage(
          totalMateri: _totalMateri,
          mapelCount: mapelCount,
          highlights: highlights,
          navData: _buildNavData(
            totalMateri: _totalMateri,
            mapelCount: mapelCount,
            kurikulumHighlights: highlights,
          ),
        ),
      ),
    );
  }

  void _openSarpras() {
    final highlights = _sarprasIssues
        .map(
          (item) => KepalaSekolahHighlight(
            title: item.title,
            description: 'Status fasilitas saat ini: ${item.status}.',
            badge: item.status,
          ),
        )
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SarprasPage(
          totalSarpras: _totalSarpras,
          sarprasRusak: _sarprasRusak,
          highlights: highlights,
          navData: _buildNavData(sarprasHighlights: highlights),
        ),
      ),
    );
  }

  void _openHumas() {
    final highlights = _humasRecords.map((item) {
      return KepalaSekolahHighlight(
        title: item.title,
        description: '${item.scheduleDate} di ${item.location}.',
        badge: item.status,
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HumasPage(
          highlights: highlights,
          navData: _buildNavData(humasHighlights: highlights),
        ),
      ),
    );
  }

  void _openJurnal() {
    final highlights = _journalEntries.take(3).map((entry) {
      return KepalaSekolahHighlight(
        title: entry.title,
        description:
            '${entry.subject} - ${entry.className} - ${entry.dateLabel}',
        badge: '${entry.attendanceCount} hadir',
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JurnalPage(
          totalJurnal: _totalJurnal,
          avgAttendance: _avgAttendance,
          highlights: highlights.isEmpty
              ? [
                  const KepalaSekolahHighlight(
                    title: 'Kosong',
                    description: 'Belum ada jurnal.',
                    badge: 'Empty',
                  ),
                ]
              : highlights,
          navData: _buildNavData(
            avgAttendance: _avgAttendance,
            journalHighlights: highlights.isEmpty
                ? [
                    const KepalaSekolahHighlight(
                      title: 'Kosong',
                      description: 'Belum ada jurnal.',
                      badge: 'Empty',
                    ),
                  ]
                : highlights,
          ),
        ),
      ),
    );
  }

  void _openAbsensi() {
    final totalHadirSiswa = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.presentDays,
    );
    final totalIzinSiswa = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.izinDays,
    );
    final totalAlfaSiswa = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.alfaDays,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AbsensiPage(
          hadir: totalHadirSiswa,
          izin: totalIzinSiswa,
          alfa: totalAlfaSiswa,
          navData: _buildNavData(
            hadir: totalHadirSiswa,
            izin: totalIzinSiswa,
            alfa: totalAlfaSiswa,
          ),
        ),
      ),
    );
  }

  KepsekNavData _buildNavData({
    List<KepalaSekolahHighlight>? sarprasHighlights,
    List<KepalaSekolahHighlight>? humasHighlights,
    List<KepalaSekolahHighlight>? journalHighlights,
    int? avgAttendance,
    int? hadir,
    int? izin,
    int? alfa,
    int? totalMateri,
    int? mapelCount,
    List<KepalaSekolahHighlight>? kurikulumHighlights,
  }) {
    final computedSarprasHighlights = sarprasHighlights ??
        _sarprasRecords
            .map(
              (item) => KepalaSekolahHighlight(
                title: item.itemName,
                description: '${item.category} - ${item.location} - ${item.itemCondition}.',
                badge: item.itemCondition,
              ),
            )
            .toList();

    final computedHumasHighlights = humasHighlights ??
        _humasRecords
            .map(
              (item) => KepalaSekolahHighlight(
                title: item.title,
                description: '${item.scheduleDate} di ${item.location}.',
                badge: item.status,
              ),
            )
            .toList();

    final computedJournalHighlights = journalHighlights ??
        _journalEntries.take(3).map((entry) {
          return KepalaSekolahHighlight(
            title: entry.title,
            description: '${entry.subject} - ${entry.className} - ${entry.dateLabel}',
            badge: '${entry.attendanceCount} hadir',
          );
        }).toList();

    final computedAvgAttendance = avgAttendance ?? _avgAttendance;

    final computedHadir = hadir ??
        _attendanceRecords.fold<int>(0, (sum, item) => sum + item.presentDays);
    final computedIzin = izin ??
        _attendanceRecords.fold<int>(0, (sum, item) => sum + item.izinDays);
    final computedAlfa = alfa ??
        _attendanceRecords.fold<int>(0, (sum, item) => sum + item.alfaDays);

    final computedMapelCount = mapelCount ??
        _curriculumItems
            .map((item) => item.subject.trim())
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .length;
    final computedSchoolYear = _curriculumItems
        .map((item) => item.schoolYear.trim())
        .firstWhere((item) => item.isNotEmpty, orElse: () => '-');

    final computedKurikulumHighlights = kurikulumHighlights ??
        _materiItems.take(3).map((item) {
          return KepalaSekolahHighlight(
            title: item.title,
            description:
                'Materi ${item.subject} menjadi bagian dari aktivitas kurikulum terbaru.',
            badge: item.subject,
          );
        }).toList();

    return KepsekNavData(
      totalSiswa: _totalSiswa,
      totalSiswaAktif: _studentRecords
          .where((item) => item.status.trim().toLowerCase() == 'aktif')
          .length,
      totalSiswaMutasi: _studentRecords
          .where((item) => item.status.trim().toLowerCase() == 'mutasi')
          .length,
      totalKelasSiswa: _studentRecords
          .map((item) => item.className.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .length,
      totalSarpras: _totalSarpras,
      sarprasRusak: _sarprasRusak,
      sarprasAman: _sarprasAman,
      sarprasDamagePercentage: _sarprasDamagePercentage,
      totalJurnal: _totalJurnal,
      totalKelasJurnal: _totalKelasJurnal,
      avgAttendance: computedAvgAttendance,
      journalSyncPercentage: _journalSyncPercentage,
      hadir: computedHadir,
      izin: computedIzin,
      alfa: computedAlfa,
      sarprasHighlights: computedSarprasHighlights,
      humasHighlights: computedHumasHighlights,
      totalHumasAgenda: _totalHumasAgenda,
      humasPartnerCount: _humasPartnerCount,
      humasScheduledCount: _humasScheduledCount,
      humasOtherStatusCount: _humasOtherStatusCount,
      journalHighlights: computedJournalHighlights.isEmpty
          ? const [
              KepalaSekolahHighlight(
                title: 'Kosong',
                description: 'Belum ada jurnal.',
                badge: 'Empty',
              ),
            ]
          : computedJournalHighlights,
      totalMateri: totalMateri ?? _totalMateri,
      mapelCount: computedMapelCount,
      schoolYear: computedSchoolYear,
      kurikulumHighlights: computedKurikulumHighlights,
      students: _studentRecords,
      curriculums: _curriculumItems,
      sarprasRecords: _sarprasRecords,
      humasRecords: _humasRecords,
      journals: _journalEntries,
      attendanceRecords: _attendanceRecords,
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    if (index == 1) {
      _openKesiswaan();
      return;
    }
    if (index == 2) {
      _openKurikulum();
      return;
    }
    if (index == 3) {
      _openSarpras();
      return;
    }
    if (index == 4) {
      _openHumas();
      return;
    }
    if (index == 5) {
      _openJurnal();
      return;
    }
    if (index == 6) {
      _openAbsensi();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 880;
    final profile = _profileStore.profile;
    final name = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name.trim()
        : 'Profil Kepala Sekolah';
    final nip = (profile?.nip.trim().isNotEmpty ?? false)
        ? profile!.nip.trim()
        : '-';
    final avatarBytes = profile?.avatarBytes;
    final totalHadirSiswa = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.presentDays,
    );
    final totalIzinSiswa = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.izinDays,
    );
    final totalAlfaSiswa = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.alfaDays,
    );
    final totalAbsensiSiswa = totalHadirSiswa + totalIzinSiswa + totalAlfaSiswa;
    final persentaseSiswa = totalAbsensiSiswa == 0
        ? 0.0
        : (totalHadirSiswa / totalAbsensiSiswa) * 100;

    final latestJournals = _journalEntries.take(3).toList();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KepsekHero(
          name: name,
          nip: nip,
          avatarBytes: avatarBytes,
          onLogout: _logout,
          onProfileTap: _openProfile,
        ),
        const SizedBox(height: 18),
        StatGrid(
          items: [
            StatItem(
              title: 'Total Siswa',
              value: '$_totalSiswa',
              subtitle: 'Seluruh siswa aktif',
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF2F6BFF),
              iconBackground: const Color(0xFFEAF0FF),
              onTap: _openKesiswaan,
            ),
            StatItem(
              title: 'Total Guru',
              value: '$_totalGuru',
              subtitle: 'Guru aktif',
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF2CB34A),
              iconBackground: const Color(0xFFEAF8EE),
              onTap: _openAbsensi,
            ),
            StatItem(
              title: 'Total Sarpras',
              value: '$_totalSarpras',
              subtitle: 'Fasilitas terdata',
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF8B52E8),
              iconBackground: const Color(0xFFF1ECFF),
              onTap: _openSarpras,
            ),
            StatItem(
              title: 'Sarpras Rusak',
              value: '$_sarprasRusak',
              subtitle: 'Perlu perbaikan',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFFF8A00),
              iconBackground: const Color(0xFFFFF2E5),
              onTap: _openSarpras,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Menu Utama',
          style: TextStyle(
            color: Color(0xFF1E2433),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        MenuGrid(
          items: [
            MenuItem(
              title: 'Kesiswaan',
              subtitle: 'Kelola data siswa',
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF2F6BFF),
              iconBackground: const Color(0xFFEAF0FF),
              onTap: _openKesiswaan,
            ),
            MenuItem(
              title: 'Kurikulum',
              subtitle: 'Kelola kurikulum sekolah',
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF2CB34A),
              iconBackground: const Color(0xFFEAF8EE),
              onTap: _openKurikulum,
            ),
            MenuItem(
              title: 'Sarpras',
              subtitle: 'Sarana & prasarana',
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFFFF8A00),
              iconBackground: const Color(0xFFFFF2E5),
              onTap: _openSarpras,
            ),
            MenuItem(
              title: 'Humas',
              subtitle: 'Hubungan masyarakat',
              icon: Icons.campaign_rounded,
              iconColor: const Color(0xFF8B52E8),
              iconBackground: const Color(0xFFF3ECFF),
              onTap: _openHumas,
            ),
            MenuItem(
              title: 'Jurnal',
              subtitle: 'Jurnal pembelajaran guru',
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF1BB4C9),
              iconBackground: const Color(0xFFE9FAFD),
              onTap: _openJurnal,
            ),
            MenuItem(
              title: 'Absensi',
              subtitle: 'Lihat absensi siswa',
              icon: Icons.assignment_turned_in_rounded,
              iconColor: const Color(0xFFFF395D),
              iconBackground: const Color(0xFFFFEBEF),
              onTap: _openAbsensi,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDashboardColumns(
          isWide: isWide,
          children: [
            BoardCard(
              title: 'Sarpras Bermasalah',
              leadingIcon: Icons.warning_amber_rounded,
              leadingColor: const Color(0xFFFF8A00),
              trailingLabel: 'Buka',
              onTrailingTap: _openSarpras,
              child: IssueList(
                items: _sarprasIssues,
                onTap: _openSarpras,
              ),
            ),
            BoardCard(
              title: 'Kegiatan Terbaru (Humas)',
              leadingIcon: Icons.campaign_rounded,
              leadingColor: const Color(0xFF8B52E8),
              trailingLabel: 'Buka',
              onTrailingTap: _openHumas,
              child: EventList(items: _humasEvents, onTap: _openHumas),
            ),
            BoardCard(
              title: 'Jurnal Hari Ini',
              leadingIcon: Icons.receipt_long_rounded,
              leadingColor: const Color(0xFF2F6BFF),
              trailingLabel: 'Buka',
              onTrailingTap: _openJurnal,
              child: JournalPreviewList(
                entries: latestJournals,
                onTap: _openJurnal,
              ),
            ),
            BoardCard(
              title: 'Rekap Absensi Siswa Hari Ini',
              leadingIcon: Icons.check_circle_outline_rounded,
              leadingColor: const Color(0xFF2CB34A),
              trailingLabel: 'Buka',
              onTrailingTap: _openAbsensi,
              child: AttendanceRecap(
                siswaHadir: totalHadirSiswa,
                totalSiswa: totalAbsensiSiswa,
                totalGuru: totalAbsensiSiswa,
                guruHadir: totalIzinSiswa,
                persentaseSiswa: persentaseSiswa,
                persentaseGuru: totalAbsensiSiswa == 0
                    ? 0.0
                    : (totalIzinSiswa / totalAbsensiSiswa) * 100,
                primaryLabel: 'Hadir',
                secondaryLabel: 'Izin/Sakit',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Insight Pimpinan',
          style: TextStyle(
            color: Color(0xFF1E2433),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildDashboardColumns(
          isWide: isWide,
          children: [
            BoardCard(
              title: 'Perbandingan Kelas & Jurusan',
              leadingIcon: Icons.bar_chart_rounded,
              leadingColor: const Color(0xFF2F6BFF),
              trailingLabel: 'Buka',
              onTrailingTap: _openKesiswaan,
              child: ComparisonList(items: _comparisonInsights),
            ),
            BoardCard(
              title: 'Ringkasan Operasional',
              leadingIcon: Icons.dashboard_customize_rounded,
              leadingColor: const Color(0xFF8B52E8),
              trailingLabel: 'Buka',
              onTrailingTap: _openKurikulum,
              child: SnapshotGrid(items: _executiveSnapshots),
            ),
            BoardCard(
              title: 'Masalah Prioritas',
              leadingIcon: Icons.crisis_alert_rounded,
              leadingColor: const Color(0xFFFF8A00),
              trailingLabel: 'Buka',
              onTrailingTap: _openSarpras,
              child: InsightSummaryList(items: _priorityInsights),
            ),
            BoardCard(
              title: 'Rekap Lintas Modul',
              leadingIcon: Icons.hub_rounded,
              leadingColor: const Color(0xFF2CB34A),
              trailingLabel: 'Buka',
              onTrailingTap: _openAbsensi,
              child: CrossModuleList(items: _crossModuleInsights),
            ),
          ],
        ),
        const SizedBox(height: 22),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: const Color(0xFF2F6BFF),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 880;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 16 : 12,
                  vertical: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 1180 : 470),
                    child: body,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: KepsekBottomNav(
            currentIndex: _currentNavIndex,
            onTap: _onBottomNavTap,
          ),
        ),
      ),
    );
  }
}
