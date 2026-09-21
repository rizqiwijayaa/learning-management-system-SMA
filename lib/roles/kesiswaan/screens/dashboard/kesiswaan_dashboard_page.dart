import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/models/activity_log.dart';
import 'package:lms_guru/roles/kesiswaan/models/student_record.dart';
import 'package:lms_guru/roles/kesiswaan/models/student_violation.dart';
import 'package:lms_guru/roles/kesiswaan/screens/auth/login_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kelola_menu_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_humas/kelola_humas_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_jurnal/kelola_jurnal_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_kesiswaan/kelola_kesiswaan_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kurikulum/kelola_kurikulum_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_sarpras/kelola_sarpras_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/rekap_absensi/rekap_absensi_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/users/kelola_user_page.dart';
import 'package:lms_guru/roles/kesiswaan/services/lms_api_service.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';
import 'package:lms_guru/roles/shared/feature_placeholder_page.dart';

class KesiswaanDashboardPage extends StatefulWidget {
  const KesiswaanDashboardPage({super.key});

  @override
  State<KesiswaanDashboardPage> createState() => _KesiswaanDashboardPageState();
}

class _KesiswaanDashboardPageState extends State<KesiswaanDashboardPage> {
  static const int _studentsPerPage = 5;
  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<StudentRecord> _students = [];
  final List<StudentViolation> _violationsData = [];
  List<_ActivityInfo> _activities = const [];
  bool _isLoadingActivities = false;
  bool _isLoadingViolations = false;
  bool _isLoadingStudents = false;
  Map<String, dynamic>? _summary;
  int _presentTotal = 0;
  int _izinTotal = 0;
  int _alfaTotal = 0;
  int _attendanceStudentCount = 0;
  String? _studentError;
  int _currentStudentPage = 1;
  String? _selectedClassFilter;
  String? _selectedMajorFilter;
  String? _selectedStatusFilter;

  static const List<_MenuItem> _menuItems = [
    _MenuItem(
      title: 'Kelola User',
      subtitle: 'Kelola akun pengguna',
      icon: Icons.person_rounded,
      iconColor: Color(0xFF3366F3),
      iconBackground: Color(0xFFEAF0FF),
    ),
    _MenuItem(
      title: 'Kelola Kurikulum',
      subtitle: 'Kelola data kurikulum',
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF18A860),
      iconBackground: Color(0xFFEAF8EF),
    ),
    _MenuItem(
      title: 'Kelola Kesiswaan',
      subtitle: 'Kelola data siswa, mutasi, dan aktivitas kesiswaan',
      icon: Icons.gavel_rounded,
      iconColor: Color(0xFF7C4DFF),
      iconBackground: Color(0xFFF1EAFF),
    ),
    _MenuItem(
      title: 'Kelola Sarpras',
      subtitle: 'Kelola sarana & prasarana',
      icon: Icons.inventory_2_rounded,
      iconColor: Color(0xFFF28A1B),
      iconBackground: Color(0xFFFFF3E6),
    ),
    _MenuItem(
      title: 'Kelola Humas',
      subtitle: 'Kelola informasi humas',
      icon: Icons.campaign_rounded,
      iconColor: Color(0xFFE84D67),
      iconBackground: Color(0xFFFFEDF1),
    ),
    _MenuItem(
      title: 'Kelola Jurnal',
      subtitle: 'Kelola jurnal pembelajaran',
      icon: Icons.library_books_rounded,
      iconColor: Color(0xFF3366F3),
      iconBackground: Color(0xFFEAF0FF),
    ),
    _MenuItem(
      title: 'Lihat Rekap Absensi',
      subtitle: 'Lihat rekap absensi guru & siswa',
      icon: Icons.fact_check_rounded,
      iconColor: Color(0xFF17A2A0),
      iconBackground: Color(0xFFE8FAF7),
    ),
    _MenuItem(
      title: 'Logout',
      subtitle: 'Keluar dari sistem',
      icon: Icons.logout_rounded,
      iconColor: Color(0xFFE84D67),
      iconBackground: Color(0xFFFFEDF1),
    ),
  ];

  List<_ListInfo> get _violationHighlights => _violationsData
      .take(3)
      .map(
        (item) => _ListInfo(
          '${item.studentName} (${item.className})',
          item.violationType,
          item.violationDate,
        ),
      )
      .toList(growable: false);

  List<_ListInfo> get _mutationHighlights {
    final activityItems = _activities
        .where((item) => item.type.trim().toLowerCase() == 'student_mutation')
        .take(3)
        .map((item) => _ListInfo(_extractStudentName(item.title), 'Mutasi', item.time))
        .toList(growable: false);
    if (activityItems.isNotEmpty) return activityItems;

    final studentItems = _students
        .where((student) => student.status.trim().toLowerCase() == 'mutasi')
        .take(3)
        .map((student) => _ListInfo(student.name, 'Mutasi', student.className))
        .toList(growable: false);
    return studentItems;
  }

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _searchController.addListener(_handleSearchChanged);
    _loadStudents();
    _loadViolations();
    _loadActivities();
    _loadSummary();
    _loadAttendanceSummary();
  }

  @override
  void dispose() {
    _profileStore.removeListener(_handleProfileChanged);
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleProfileChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {
      _currentStudentPage = 1;
    });
  }

  List<StudentRecord> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    return _students
        .where((student) {
          final matchesClass =
              _selectedClassFilter == null ||
              student.className.trim().toLowerCase() ==
                  _selectedClassFilter!.toLowerCase();
          final matchesMajor =
              _selectedMajorFilter == null ||
              student.major.trim().toLowerCase() ==
                  _selectedMajorFilter!.toLowerCase();
          final matchesStatus =
              _selectedStatusFilter == null ||
              student.status.trim().toLowerCase() ==
                  _selectedStatusFilter!.toLowerCase();
          final haystack = [
            student.name,
            student.nis,
            student.className,
            student.major,
            student.status,
          ].join(' ').toLowerCase();
          final matchesQuery = query.isEmpty || haystack.contains(query);
          return matchesClass && matchesMajor && matchesStatus && matchesQuery;
        })
        .toList(growable: false);
  }

  List<String> get _availableClassFilters =>
      _students
          .map((student) => student.className.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  List<String> get _availableMajorFilters =>
      _students
          .map((student) => student.major.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  List<String> get _availableStatusFilters =>
      _students
          .map((student) => student.status.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  int get _studentPageCount {
    final total = _filteredStudents.length;
    if (total == 0) return 1;
    return (total / _studentsPerPage).ceil();
  }

  List<StudentRecord> get _pagedStudents {
    final filtered = _filteredStudents;
    if (filtered.isEmpty) return const [];

    final safePage = _currentStudentPage.clamp(1, _studentPageCount);
    final start = (safePage - 1) * _studentsPerPage;
    final end = (start + _studentsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  List<_StatItem> get _stats {
    final totalStudents = (_summary?['totalStudents'] as num?)?.toInt() ?? _students.length;
    final activeCount = (_summary?['activeStudents'] as num?)?.toInt() ??
        _students.where((student) => student.status.trim().toLowerCase() == 'aktif').length;
    final violationCount =
        (_summary?['violationCount'] as num?)?.toInt() ?? _violationsData.length;
    final attendanceRate =
        (_summary?['attendanceSummary']?['attendanceRate'] as num?)?.toInt() ??
            _attendanceRatePercent.round();

    return [
      _StatItem(
        title: 'Total Siswa',
        value: '$totalStudents',
        note: 'Seluruh siswa terdaftar',
        icon: Icons.groups_rounded,
        iconColor: const Color(0xFF3366F3),
        iconBackground: const Color(0xFFEAF0FF),
      ),
      _StatItem(
        title: 'Siswa Aktif',
        value: '$activeCount',
        note: 'Siswa aktif saat ini',
        icon: Icons.verified_user_rounded,
        iconColor: const Color(0xFF1DB56B),
        iconBackground: const Color(0xFFEAF8EF),
      ),
      _StatItem(
        title: 'Pelanggaran',
        value: '$violationCount',
        note: 'Catatan pelanggaran siswa',
        icon: Icons.gavel_rounded,
        iconColor: const Color(0xFF7C4DFF),
        iconBackground: const Color(0xFFF1EAFF),
      ),
      _StatItem(
        title: 'Kehadiran',
        value: '$attendanceRate%',
        note: ((_summary?['attendanceSummary']?['attendanceStudentCount'] as num?)?.toInt() ??
                    _attendanceStudentCount) >
                0
            ? 'Rata-rata kehadiran siswa'
            : 'Menunggu rekap absensi',
        icon: Icons.assignment_rounded,
        iconColor: const Color(0xFFF28A1B),
        iconBackground: const Color(0xFFFFF3E6),
      ),
    ];
  }

  double get _attendanceRatePercent {
    final total = _presentTotal + _izinTotal + _alfaTotal;
    if (total <= 0) return 0;
    return (_presentTotal / total) * 100;
  }

  List<_SimpleInfo> get _attendanceSummary {
    final summaryAttendance = _summary?['attendanceSummary'];
    final present = (summaryAttendance?['presentTotal'] as num?)?.toInt() ?? _presentTotal;
    final izin = (summaryAttendance?['izinTotal'] as num?)?.toInt() ?? _izinTotal;
    final alfa = (summaryAttendance?['alfaTotal'] as num?)?.toInt() ?? _alfaTotal;
    final attendanceStudentCount =
        (summaryAttendance?['attendanceStudentCount'] as num?)?.toInt() ??
            _attendanceStudentCount;
    final total = present + izin + alfa;

    String percentFor(int value) {
      if (total <= 0) return '0%';
      return '${((value / total) * 100).round()}%';
    }

    final coverage = _students.isEmpty
        ? '0%'
        : '${((attendanceStudentCount / _students.length) * 100).round()}%';

    return [
      _SimpleInfo(
        'Hadir',
        '$present',
        percentFor(present),
        const Color(0xFF17A34A),
      ),
      _SimpleInfo(
        'Izin',
        '$izin',
        percentFor(izin),
        const Color(0xFFF59E0B),
      ),
      _SimpleInfo(
        'Alfa',
        '$alfa',
        percentFor(alfa),
        const Color(0xFFE11D48),
      ),
      _SimpleInfo(
        'Siswa Tercatat',
        '$attendanceStudentCount',
        coverage,
        const Color(0xFF7C4DFF),
      ),
    ];
  }

  List<_ListInfo> get _summaryViolationHighlights {
    final items = _summary?['recentViolations'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => _ListInfo(
            '${item['title'] ?? ''}',
            '${item['subtitle'] ?? ''}',
            '${item['trailing'] ?? ''}',
          ),
        )
        .toList(growable: false);
  }

  List<_ListInfo> get _summaryMutationHighlights {
    final items = _summary?['recentMutations'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => _ListInfo(
            '${item['title'] ?? ''}',
            '${item['subtitle'] ?? ''}',
            _formatSummaryTime('${item['trailing'] ?? ''}'),
          ),
        )
        .toList(growable: false);
  }

  int get _totalStudentsSummary =>
      (_summary?['totalStudents'] as num?)?.toInt() ?? _students.length;

  int get _activeStudentsSummary =>
      (_summary?['activeStudents'] as num?)?.toInt() ??
      _students.where((student) => student.status.trim().toLowerCase() == 'aktif').length;

  int get _mutationStudentsSummary =>
      (_summary?['mutationStudents'] as num?)?.toInt() ??
      _students.where((student) => student.status.trim().toLowerCase() == 'mutasi').length;

  int get _nonActiveStudentsSummary {
    final derived =
        _students.where((student) => student.status.trim().toLowerCase() == 'nonaktif').length;
    final total = _totalStudentsSummary;
    final active = _activeStudentsSummary;
    final mutation = _mutationStudentsSummary;
    final fromSummary = total - active - mutation;
    return fromSummary >= 0 ? fromSummary : derived;
  }

  List<_InsightMetric> get _statusInsights {
    final summaryItems = _summary?['statusInsights'];
    if (summaryItems is List) {
      final mapped = summaryItems
          .whereType<Map>()
          .map(
            (item) => _InsightMetric(
              title: '${item['title'] ?? ''}',
              value: '${item['value'] ?? ''}',
              subtitle: '${item['subtitle'] ?? ''}',
              color: _insightMetricColor('${item['title'] ?? ''}'),
              background: _insightMetricBackground('${item['title'] ?? ''}'),
            ),
          )
          .where((item) => item.title.trim().isNotEmpty)
          .toList(growable: false);
      if (mapped.isNotEmpty) return mapped;
    }

    final total = _totalStudentsSummary;
    final active = _activeStudentsSummary;
    final mutation = _mutationStudentsSummary;
    final nonActive = _nonActiveStudentsSummary;
    final attendanceCoverage = (_summary?['attendanceSummary']?['attendanceStudentCount'] as num?)
            ?.toInt() ??
        _attendanceStudentCount;

    String ratioOf(int value) {
      if (total <= 0) return '0%';
      return '${((value / total) * 100).round()}%';
    }

    return [
      _InsightMetric(
        title: 'Siswa Aktif',
        value: '$active',
        subtitle: '${ratioOf(active)} dari total siswa',
        color: const Color(0xFF1DB56B),
        background: const Color(0xFFEAF8EF),
      ),
      _InsightMetric(
        title: 'Status Mutasi',
        value: '$mutation',
        subtitle: '${ratioOf(mutation)} perlu pemantauan',
        color: const Color(0xFFF28A1B),
        background: const Color(0xFFFFF3E6),
      ),
      _InsightMetric(
        title: 'Siswa Nonaktif',
        value: '$nonActive',
        subtitle: '${ratioOf(nonActive)} perlu verifikasi',
        color: const Color(0xFFE84D67),
        background: const Color(0xFFFFEDF1),
      ),
      _InsightMetric(
        title: 'Absensi Masuk',
        value: '$attendanceCoverage',
        subtitle: total <= 0
            ? 'Menunggu data siswa'
            : '${((attendanceCoverage / total) * 100).round()}% siswa tercatat',
        color: const Color(0xFF3366F3),
        background: const Color(0xFFEAF0FF),
      ),
    ];
  }

  List<_ListInfo> get _classAttentionHighlights {
    final summaryItems = _summary?['classAttentionHighlights'];
    if (summaryItems is List) {
      final mapped = summaryItems
          .whereType<Map>()
          .map(
            (item) => _ListInfo(
              '${item['title'] ?? ''}',
              '${item['subtitle'] ?? ''}',
              '${item['trailing'] ?? ''}',
            ),
          )
          .where((item) => item.title.trim().isNotEmpty)
          .toList(growable: false);
      if (mapped.isNotEmpty) return mapped;
    }

    final Map<String, int> classScores = {};
    final Map<String, int> violationCounts = {};
    final Map<String, int> studentCounts = {};

    for (final student in _students) {
      final className = student.className.trim();
      if (className.isEmpty) continue;
      studentCounts[className] = (studentCounts[className] ?? 0) + 1;
      final status = student.status.trim().toLowerCase();
      if (status == 'mutasi' || status == 'nonaktif') {
        classScores[className] = (classScores[className] ?? 0) + 1;
      }
    }

    for (final violation in _violationsData) {
      final className = violation.className.trim();
      if (className.isEmpty) continue;
      violationCounts[className] = (violationCounts[className] ?? 0) + 1;
      classScores[className] = (classScores[className] ?? 0) + 2;
    }

    final ranked = classScores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.compareTo(b.key);
      });

    if (ranked.isEmpty) {
      final classRoster = _students.fold<Map<String, int>>({}, (map, student) {
        final className = student.className.trim();
        if (className.isNotEmpty) {
          map[className] = (map[className] ?? 0) + 1;
        }
        return map;
      });
      final rankedRoster = classRoster.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return rankedRoster
          .take(3)
          .map(
            (entry) => _ListInfo(
              entry.key,
              '${entry.value} siswa terdata pada kelas ini',
              'Pantau kelas',
            ),
          )
          .toList(growable: false);
    }

    return ranked.take(3).map((entry) {
      final className = entry.key;
      final violationTotal = violationCounts[className] ?? 0;
      final studentTotal = studentCounts[className] ?? 0;
      final attentionStudents = _students.where((student) {
        return student.className.trim() == className &&
            {'mutasi', 'nonaktif'}.contains(student.status.trim().toLowerCase());
      }).length;
      return _ListInfo(
        className,
        '$violationTotal pelanggaran • $attentionStudents siswa atensi dari $studentTotal siswa',
        entry.value >= 4 ? 'Prioritas' : 'Pantau',
      );
    }).toList(growable: false);
  }

  List<_ListInfo> get _followUpHighlights {
    final summaryItems = _summary?['followUpHighlights'];
    if (summaryItems is List) {
      final mapped = summaryItems
          .whereType<Map>()
          .map(
            (item) => _ListInfo(
              '${item['title'] ?? ''}',
              '${item['subtitle'] ?? ''}',
              '${item['trailing'] ?? ''}',
            ),
          )
          .where((item) => item.title.trim().isNotEmpty)
          .toList(growable: false);
      if (mapped.isNotEmpty) return mapped;
    }

    final totalStudents = _totalStudentsSummary;
    final mutation = _mutationStudentsSummary;
    final nonActive = _nonActiveStudentsSummary;
    final violation = (_summary?['violationCount'] as num?)?.toInt() ?? _violationsData.length;
    final attendanceCoverage = (_summary?['attendanceSummary']?['attendanceStudentCount'] as num?)
            ?.toInt() ??
        _attendanceStudentCount;
    final missingAttendance = totalStudents > attendanceCoverage
        ? totalStudents - attendanceCoverage
        : 0;

    return [
      _ListInfo(
        'Rekap absensi perlu dilengkapi',
        missingAttendance > 0
            ? '$missingAttendance siswa belum masuk rekap absensi terbaru'
            : 'Seluruh siswa sudah tercatat pada rekap absensi',
        missingAttendance > 0 ? 'Cek absensi' : 'Sudah lengkap',
      ),
      _ListInfo(
        'Status siswa perlu verifikasi',
        '${mutation + nonActive} siswa berstatus mutasi atau nonaktif',
        mutation + nonActive > 0 ? 'Verifikasi' : 'Stabil',
      ),
      _ListInfo(
        'Pelanggaran perlu koordinasi',
        violation > 0
            ? '$violation catatan pelanggaran perlu tindak lanjut wali kelas'
            : 'Belum ada pelanggaran yang perlu ditindaklanjuti',
        violation > 0 ? 'Tindak lanjut' : 'Terkendali',
      ),
    ];
  }

  Color _insightMetricColor(String title) {
    final normalized = title.trim().toLowerCase();
    if (normalized.contains('aktif')) return const Color(0xFF1DB56B);
    if (normalized.contains('mutasi')) return const Color(0xFFF28A1B);
    if (normalized.contains('nonaktif')) return const Color(0xFFE84D67);
    return const Color(0xFF3366F3);
  }

  Color _insightMetricBackground(String title) {
    final normalized = title.trim().toLowerCase();
    if (normalized.contains('aktif')) return const Color(0xFFEAF8EF);
    if (normalized.contains('mutasi')) return const Color(0xFFFFF3E6);
    if (normalized.contains('nonaktif')) return const Color(0xFFFFEDF1);
    return const Color(0xFFEAF0FF);
  }

  String _formatSummaryTime(String raw) {
    if (raw.trim().isEmpty) return 'Baru saja';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _relativeTime(parsed);
  }

  String get _name => (_profileStore.profile?.name.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.name.trim()
      : 'Profil Kesiswaan';

  String get _role => (_profileStore.profile?.role.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.role.trim()
      : 'Kesiswaan';

  String get _initial => _name.substring(0, 1).toUpperCase();
  Uint8List? get _avatarBytes => _profileStore.profile?.avatarBytes;

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _studentError = null;
    });

    try {
      final students = await _api.getStudents();
      if (!mounted) return;
      setState(() {
        _students
          ..clear()
          ..addAll(students);
        _currentStudentPage = 1;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _studentError = '$error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _showMessageDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;
    setState(() => _isLoadingActivities = true);

    try {
      final items = await _api.getActivityLogs();
      if (!mounted) return;
      setState(() {
        _activities = items.map(_mapActivityLog).toList(growable: false);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _api.getKesiswaanSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (_) {}
  }

  Future<void> _loadViolations() async {
    if (!mounted) return;
    setState(() => _isLoadingViolations = true);

    try {
      final items = await _api.getStudentViolations();
      if (!mounted) return;
      setState(() {
        _violationsData
          ..clear()
          ..addAll(items);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingViolations = false);
    }
  }

  Future<void> _loadAttendanceSummary() async {
    try {
      final items = await _api.getAttendance();
      if (!mounted) return;

      var present = 0;
      var izin = 0;
      var alfa = 0;
      for (final item in items) {
        present += item.presentDays;
        izin += item.izinDays;
        alfa += item.alfaDays;
      }

      setState(() {
        _attendanceStudentCount = items.length;
        _presentTotal = present;
        _izinTotal = izin;
        _alfaTotal = alfa;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendanceStudentCount = 0;
        _presentTotal = 0;
        _izinTotal = 0;
        _alfaTotal = 0;
      });
    }
  }

  Future<void> _addActivity({
    required String title,
    required String actor,
    required String type,
  }) async {
    try {
      await _api.createActivityLog(title: title, actor: actor, type: type);
      await _loadActivities();
      await _loadSummary();
    } catch (_) {}
  }

  Future<void> _openStudentFilter() async {
    final result = await showDialog<_StudentFilterResult>(
      context: context,
      builder: (context) => _StudentFilterDialog(
        classOptions: _availableClassFilters,
        majorOptions: _availableMajorFilters,
        statusOptions: _availableStatusFilters,
        selectedClass: _selectedClassFilter,
        selectedMajor: _selectedMajorFilter,
        selectedStatus: _selectedStatusFilter,
      ),
    );

    if (result == null) return;

    setState(() {
      _selectedClassFilter = result.className;
      _selectedMajorFilter = result.major;
      _selectedStatusFilter = result.status;
      _currentStudentPage = 1;
    });
  }

  Future<void> _openStudentForm({StudentRecord? student}) async {
    final result = await showDialog<StudentRecord>(
      context: context,
      builder: (context) => _StudentFormDialog(student: student),
    );

    if (result == null) return;

    try {
      if (student == null) {
        final created = await _api.createStudent(result);
        if (!mounted) return;
        await _loadStudents();
        await _loadSummary();
        if (!mounted) return;
        await _addActivity(
          title: 'Data siswa baru "${created.name}" telah ditambahkan',
          actor: 'oleh Kesiswaan',
          type: 'student_add',
        );
      } else {
        final previousStatus = student.status.trim().toLowerCase();
        final nextStatus = result.status.trim().toLowerCase();
        final updated = await _api.updateStudent(result);
        if (!mounted) return;
        await _loadStudents();
        await _loadSummary();
        if (!mounted) return;
        final activity = _buildStudentUpdateActivity(
          name: updated.name,
          previousStatus: previousStatus,
          nextStatus: nextStatus,
        );
        await _addActivity(
          title: activity.$1,
          actor: 'oleh Kesiswaan',
          type: activity.$2,
        );
      }
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Perubahan Gagal', '$error');
    }
  }

  Future<void> _openStudentDetail(StudentRecord student) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Siswa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${student.name}'),
            const SizedBox(height: 8),
            Text('NIS: ${student.nis}'),
            const SizedBox(height: 8),
            Text('Kelas: ${student.className}'),
            const SizedBox(height: 8),
            Text('Jurusan: ${student.major}'),
            const SizedBox(height: 8),
            Text('Status: ${student.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(StudentRecord student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text('Hapus data ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (student.id == null) {
        throw Exception('ID siswa kosong');
      }

      await _api.deleteStudent(student.id!);
      if (!mounted) return;
      await _loadStudents();
      await _loadSummary();
      if (!mounted) return;
      await _addActivity(
        title: 'Data siswa "${student.name}" telah dihapus',
        actor: 'oleh Kesiswaan',
        type: 'student_delete',
      );
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Hapus Gagal', '$error');
    }
  }

  (String, String) _buildStudentUpdateActivity({
    required String name,
    required String previousStatus,
    required String nextStatus,
  }) {
    if (nextStatus == 'mutasi' && previousStatus != 'mutasi') {
      return ('Siswa "$name" dimutasi', 'student_mutation');
    }
    if (nextStatus == 'nonaktif' && previousStatus != 'nonaktif') {
      return ('Siswa "$name" dinonaktifkan', 'student_deactivate');
    }
    if (nextStatus == 'aktif' &&
        previousStatus.isNotEmpty &&
        previousStatus != 'aktif') {
      return ('Siswa "$name" diaktifkan kembali', 'student_activate');
    }
    return ('Data siswa "$name" telah diperbarui', 'student_edit');
  }

  _ActivityInfo _mapActivityLog(ActivityLog log) {
    final style = _activityStyle(log.type);
    return _ActivityInfo(
      log.title,
      log.actor,
      _relativeTime(log.createdAt),
      log.type,
      style.$1,
      style.$2,
      style.$3,
    );
  }

  (IconData, Color, Color) _activityStyle(String type) {
    switch (type.trim().toLowerCase()) {
      case 'student_add':
        return (
          Icons.group_add_rounded,
          const Color(0xFF1DB56B),
          const Color(0xFFEAF8EF),
        );
      case 'student_edit':
      case 'attendance_update':
        return (
          Icons.edit_outlined,
          const Color(0xFF3366F3),
          const Color(0xFFEAF0FF),
        );
      case 'student_activate':
        return (
          Icons.verified_user_rounded,
          const Color(0xFF1DB56B),
          const Color(0xFFEAF8EF),
        );
      case 'student_deactivate':
        return (
          Icons.person_off_rounded,
          const Color(0xFFE84D67),
          const Color(0xFFFFEDF1),
        );
      case 'student_delete':
        return (
          Icons.delete_outline_rounded,
          const Color(0xFFE84D67),
          const Color(0xFFFFEDF1),
        );
      case 'violation_add':
      case 'violation_edit':
        return (
          Icons.warning_amber_rounded,
          const Color(0xFFF28A1B),
          const Color(0xFFFFF3E6),
        );
      case 'violation_delete':
        return (
          Icons.delete_outline_rounded,
          const Color(0xFFE84D67),
          const Color(0xFFFFEDF1),
        );
      case 'student_mutation':
        return (
          Icons.sync_alt_rounded,
          const Color(0xFFF28A1B),
          const Color(0xFFFFF3E6),
        );
      default:
        return (
          Icons.groups_rounded,
          const Color(0xFF7C4DFF),
          const Color(0xFFF1EAFF),
        );
    }
  }

  String _relativeTime(DateTime? createdAt) {
    if (createdAt == null) return 'Baru saja';
    final now = DateTime.now();
    final diff = now.difference(createdAt.toLocal());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit yang lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam yang lalu';
    return '${diff.inDays} hari yang lalu';
  }

  String _extractStudentName(String title) {
    final match = RegExp(r'"([^"]+)"').firstMatch(title);
    if (match != null) {
      return match.group(1) ?? title;
    }

    final normalized = title
        .replaceFirst(RegExp(r'^Siswa\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s+dimutasi.*$', caseSensitive: false), '')
        .trim();
    return normalized.isEmpty ? title : normalized;
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  void _openFeature({
    required String title,
    required String description,
    required IconData icon,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeaturePlaceholderPage(
          title: title,
          description: description,
          icon: icon,
        ),
      ),
    );
  }

  void _openMenu(_MenuItem item) {
    if (item.title == 'Kelola User') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaUserPage()));
      return;
    }

    if (item.title == 'Kelola Kurikulum') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaKurikulumPage()));
      return;
    }

    if (item.title == 'Kelola Sarpras') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaSarprasPage()));
      return;
    }

    if (item.title == 'Kelola Kesiswaan') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaKesiswaanPage()));
      return;
    }

    if (item.title == 'Kelola Humas') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaHumasPage()));
      return;
    }

    if (item.title == 'Kelola Jurnal') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaJurnalPage()));
      return;
    }

    if (item.title == 'Lihat Rekap Absensi') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RekapAbsensiPage()));
      return;
    }

    if (item.title == 'Logout') {
      _profileStore.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    _openFeature(
      title: item.title,
      description: item.subtitle,
      icon: item.icon,
    );
  }

  void _openStat(_StatItem item) {
    _openFeature(title: item.title, description: item.note, icon: item.icon);
  }

  void _openSection(String title, String description, IconData icon) {
    _openFeature(title: title, description: description, icon: icon);
  }

  void _openBottomNav(int index) {
    if (index == 0) {
      return;
    }
    if (index == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaJurnalPage()));
      return;
    }
    if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const KelolaMenuPage()));
      return;
    }
    if (index == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RekapAbsensiPage()));
      return;
    }
    if (index == 4) {
      _openProfile();
      return;
    }
    if (index == 2) return;
  }

  void _changeStudentPage(int page) {
    final safePage = page.clamp(1, _studentPageCount);
    if (safePage == _currentStudentPage) return;
    setState(() {
      _currentStudentPage = safePage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth;
                  final compact = contentWidth < 900;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(
                        name: _name,
                        role: _role,
                        initial: _initial,
                        avatarBytes: _avatarBytes,
                        onProfileTap: _openProfile,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: _stats
                            .map(
                              (item) => _StatCard(
                                item: item,
                                compact: compact,
                                onTap: () {},
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Akses Cepat',
                        style: TextStyle(
                          color: Color(0xFF1A2A61),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: _menuItems
                            .take(4)
                            .map(
                              (item) => _MenuCard(
                                item: item,
                                compact: compact,
                                onTap: () => _openMenu(item),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const KelolaMenuPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.dashboard_customize_rounded),
                          label: const Text('Buka Semua Menu Kelola'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D60F1),
                            side: const BorderSide(color: Color(0xFFD8E2F7)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                       Wrap(
                         spacing: 14,
                         runSpacing: 14,
                         children: [
                          _PanelCard(
                            width: compact ? contentWidth : 350,
                            title: 'Rekap Absensi Siswa',
                            actionLabel: 'Lihat detail',
                            onActionTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RekapAbsensiPage(),
                                ),
                              );
                            },
                            child: Column(
                              children: _attendanceSummary
                                  .map(
                                    (item) =>
                                        _AttendanceRow(item: item, onTap: () {}),
                                  )
                                  .toList(),
                            ),
                          ),
                          _PanelCard(
                            width: compact ? contentWidth : 350,
                            title: 'Pelanggaran Terbaru',
                            actionLabel: 'Lihat semua',
                            onActionTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const KelolaKesiswaanPage(),
                                ),
                              );
                            },
                            child: Column(
                              children: _isLoadingViolations
                                  ? const [
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: 24),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ]
                                  : ((_summaryViolationHighlights.isEmpty
                                              ? _violationHighlights
                                              : _summaryViolationHighlights)
                                          .isEmpty
                                        ? const [
                                            Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              child: Text(
                                                'Belum ada pelanggaran terbaru yang tercatat',
                                                style: TextStyle(
                                                  color: Color(0xFF7D89AA),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : (_summaryViolationHighlights.isEmpty
                                                  ? _violationHighlights
                                                  : _summaryViolationHighlights)
                                              .map(
                                                (item) => _InfoTile(
                                                  title: item.title,
                                                  subtitle: item.subtitle,
                                                  trailing: item.trailing,
                                                  icon: Icons.warning_amber_rounded,
                                                  color: const Color(0xFFFF8A1F),
                                                  background: const Color(0xFFFFF1E8),
                                                  onTap: () {},
                                                ),
                                              )
                                              .toList()),
                            ),
                          ),
                          _PanelCard(
                            width: compact ? contentWidth : 350,
                            title: 'Mutasi Siswa Terbaru',
                            actionLabel: 'Lihat semua',
                            onActionTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const KelolaKesiswaanPage(),
                                ),
                              );
                            },
                            child: Column(
                              children: (_summaryMutationHighlights.isEmpty
                                      ? _mutationHighlights
                                      : _summaryMutationHighlights)
                                  .map(
                                    (item) => _InfoTile(
                                      title: item.title,
                                      subtitle: item.subtitle,
                                      trailing: item.trailing,
                                      icon: Icons.sync_alt_rounded,
                                      color: const Color(0xFFF28A1B),
                                      background: const Color(0xFFFFF3E6),
                                      onTap: () {},
                                    ),
                                  )
                                  .toList(),
                            ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 18),
                       const Text(
                         'Insight Kesiswaan',
                         style: TextStyle(
                           color: Color(0xFF1A2A61),
                           fontSize: 20,
                           fontWeight: FontWeight.w800,
                         ),
                       ),
                       const SizedBox(height: 12),
                       Wrap(
                         spacing: 14,
                         runSpacing: 14,
                         children: [
                           _PanelCard(
                             width: compact ? contentWidth : 350,
                             title: 'Status Siswa',
                             actionLabel: 'Lihat detail',
                             onActionTap: () {
                               Navigator.of(context).push(
                                 MaterialPageRoute(
                                   builder: (_) => const KelolaKesiswaanPage(),
                                 ),
                               );
                             },
                             child: _InsightMetricGrid(items: _statusInsights),
                           ),
                           _PanelCard(
                             width: compact ? contentWidth : 350,
                             title: 'Kelas Perlu Atensi',
                             actionLabel: 'Lihat kelas',
                             onActionTap: () {
                               Navigator.of(context).push(
                                 MaterialPageRoute(
                                   builder: (_) => const KelolaKesiswaanPage(),
                                 ),
                               );
                             },
                             child: Column(
                               children: _classAttentionHighlights
                                   .map(
                                     (item) => _InfoTile(
                                       title: item.title,
                                       subtitle: item.subtitle,
                                       trailing: item.trailing,
                                       icon: Icons.groups_rounded,
                                       color: const Color(0xFF7C4DFF),
                                       background: const Color(0xFFF1EAFF),
                                       onTap: () {},
                                     ),
                                   )
                                   .toList(),
                             ),
                           ),
                           _PanelCard(
                             width: compact ? contentWidth : 350,
                             title: 'Fokus Tindak Lanjut',
                             actionLabel: 'Lihat tindak lanjut',
                             onActionTap: () {
                               Navigator.of(context).push(
                                 MaterialPageRoute(
                                   builder: (_) => const KelolaKesiswaanPage(),
                                 ),
                               );
                             },
                             child: Column(
                               children: _followUpHighlights
                                   .map(
                                     (item) => _InfoTile(
                                       title: item.title,
                                       subtitle: item.subtitle,
                                       trailing: item.trailing,
                                       icon: Icons.rule_folder_rounded,
                                       color: const Color(0xFF3366F3),
                                       background: const Color(0xFFEAF0FF),
                                       onTap: () {},
                                     ),
                                   )
                                   .toList(),
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 18),
                       _StudentPanel(
                         students: _pagedStudents,
                        filteredCount: _filteredStudents.length,
                        totalStudents: _students.length,
                        currentPage: _currentStudentPage,
                        pageCount: _studentPageCount,
                        searchController: _searchController,
                        selectedClassFilter: _selectedClassFilter,
                        selectedMajorFilter: _selectedMajorFilter,
                        selectedStatusFilter: _selectedStatusFilter,
                        isLoading: _isLoadingStudents,
                        errorText: _studentError,
                        onRefresh: _loadStudents,
                        onFilterTap: _openStudentFilter,
                        onAddTap: () => _openStudentForm(),
                        onViewStudent: _openStudentDetail,
                        onEditStudent: (student) =>
                            _openStudentForm(student: student),
                        onDeleteStudent: _deleteStudent,
                        onPageTap: _changeStudentPage,
                      ),
                      const SizedBox(height: 18),
                      _ActivityPanel(
                        items: _activities,
                        isLoading: _isLoadingActivities,
                        onActionTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const KelolaKesiswaanPage(),
                            ),
                          );
                        },
                        onItemTap: (_) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const KelolaKesiswaanPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: KesiswaanBottomNavBar(
          currentIndex: 0,
          onTap: _openBottomNav,
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final Uint8List? avatarBytes;
  final VoidCallback onProfileTap;

  const _DashboardHeader({
    required this.name,
    required this.role,
    required this.initial,
    required this.avatarBytes,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: compact ? 220 : 152,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF113E8B), Color(0xFF102A7A)],
                    ),
                  ),
                ),
                const Positioned(
                  left: -45,
                  top: -26,
                  child: _HeaderBubble(size: 150, color: Color(0x1EFFFFFF)),
                ),
                const Positioned(
                  right: -60,
                  top: 8,
                  child: _HeaderBubble(size: 165, color: Color(0x10FFFFFF)),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      child: ClipPath(
                        clipper: _HeaderCurveClipper(),
                        child: Container(
                          height: compact ? 34 : 44,
                          color: const Color(0xFFF6F8FF),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 26,
                    compact ? 18 : 22,
                    compact ? 18 : 24,
                    compact ? 16 : 14,
                  ),
                  child: compact
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _HeaderIdentity(name: name, role: role, compact: true)),
                            const SizedBox(width: 14),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _MobileHeaderProfileButton(
                                initial: initial,
                                avatarBytes: avatarBytes,
                                onProfileTap: onProfileTap,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _HeaderIdentity(name: name, role: role, compact: false)),
                            const SizedBox(width: 16),
                            _HeaderProfileMenu(
                              name: name,
                              role: role,
                              initial: initial,
                              avatarBytes: avatarBytes,
                              onProfileTap: onProfileTap,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderIdentity extends StatelessWidget {
  final String name;
  final String role;
  final bool compact;

  const _HeaderIdentity({required this.name, required this.role, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat datang,',
          style: TextStyle(
            color: Color(0xFFE3EBFF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 8 : 6),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: compact ? 8 : 6),
        Text(
          role,
          style: const TextStyle(
            color: Color(0xFFDDE5FF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MobileHeaderProfileButton extends StatelessWidget {
  final String initial;
  final Uint8List? avatarBytes;
  final VoidCallback onProfileTap;

  const _MobileHeaderProfileButton({
    required this.initial,
    required this.avatarBytes,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFEFF3FF),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: KesiswaanHeaderAvatar(
            initial: initial,
            avatarBytes: avatarBytes,
            radius: 26,
            outerColor: Colors.white,
            innerColor: const Color(0xFF2953E3),
          ),
        ),
      ),
    );
  }
}

class _HeaderBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _HeaderBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          radius: 0.92,
        ),
      ),
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 52);
    path.quadraticBezierTo(size.width * 0.34, 24, size.width * 0.68, 44);
    path.quadraticBezierTo(size.width * 0.9, 58, size.width, 36);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _HeaderProfileMenu extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final Uint8List? avatarBytes;
  final VoidCallback onProfileTap;

  const _HeaderProfileMenu({
    required this.name,
    required this.role,
    required this.initial,
    required this.avatarBytes,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: BorderRadius.circular(18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  color: Color(0xFFDDE5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          KesiswaanHeaderAvatar(
            initial: initial,
            avatarBytes: avatarBytes,
            radius: 18,
            outerColor: Colors.white,
            innerColor: const Color(0xFF2953E3),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  final bool compact;
  final VoidCallback onTap;

  const _StatCard({
    required this.item,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: compact ? double.infinity : 262,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8ECF7)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: item.iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF425179),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: Color(0xFF1A2A61),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D89AA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final bool compact;
  final VoidCallback onTap;

  const _MenuCard({required this.item, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: compact ? double.infinity : 262,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8ECF7)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A2A61),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D89AA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7D89AA)),
          ],
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final double width;
  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final Widget child;

  const _PanelCard({
    required this.width,
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width > 1120 ? 350 : width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A2A61),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: Color(0xFF2D60F1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final _SimpleInfo item;
  final VoidCallback onTap;

  const _AttendanceRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF2C3B67),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              item.total,
              style: const TextStyle(
                color: Color(0xFF2C3B67),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.percent,
              style: const TextStyle(
                color: Color(0xFF6E7A9A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _InfoTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF2C3B67),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6E7A9A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFF8A94B4),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentPanel extends StatelessWidget {
  final List<StudentRecord> students;
  final int filteredCount;
  final int totalStudents;
  final int currentPage;
  final int pageCount;
  final TextEditingController searchController;
  final String? selectedClassFilter;
  final String? selectedMajorFilter;
  final String? selectedStatusFilter;
  final bool isLoading;
  final String? errorText;
  final Future<void> Function() onRefresh;
  final VoidCallback onFilterTap;
  final VoidCallback onAddTap;
  final ValueChanged<StudentRecord> onViewStudent;
  final ValueChanged<StudentRecord> onEditStudent;
  final ValueChanged<StudentRecord> onDeleteStudent;
  final ValueChanged<int> onPageTap;

  const _StudentPanel({
    required this.students,
    required this.filteredCount,
    required this.totalStudents,
    required this.currentPage,
    required this.pageCount,
    required this.searchController,
    required this.selectedClassFilter,
    required this.selectedMajorFilter,
    required this.selectedStatusFilter,
    required this.isLoading,
    required this.errorText,
    required this.onRefresh,
    required this.onFilterTap,
    required this.onAddTap,
    required this.onViewStudent,
    required this.onEditStudent,
    required this.onDeleteStudent,
    required this.onPageTap,
  });

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.length < 2) return name.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8ECF7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Siswa',
                    style: TextStyle(
                      color: Color(0xFF1A2A61),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : 144,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari siswa...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2E61F3)),
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onFilterTap,
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E61F3),
                      side: const BorderSide(color: Color(0xFFD9E2F7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onAddTap,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Siswa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E61F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
          if (_activeFilters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeFilters
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF2E61F3),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorText != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onRefresh,
                      child: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              ),
            )
          else if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data siswa.',
                  style: TextStyle(
                    color: Color(0xFF7080A8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF9FBFF),
                ),
                columns: const [
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Nama Siswa')),
                  DataColumn(label: Text('NIS')),
                  DataColumn(label: Text('Kelas')),
                  DataColumn(label: Text('Jurusan')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: students.asMap().entries.map((entry) {
                  final index = entry.key;
                  final student = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: const Color(0xFFEAF0FF),
                              child: Text(
                                _initials(student.name),
                                style: const TextStyle(
                                  color: Color(0xFF2E61F3),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(student.name),
                          ],
                        ),
                      ),
                      DataCell(Text(student.nis)),
                      DataCell(Text(student.className)),
                      DataCell(Text(student.major)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(student.status).$2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            student.status,
                            style: TextStyle(
                              color: _statusColor(student.status).$1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            _MiniAction(
                              icon: Icons.visibility_outlined,
                              onTap: () => onViewStudent(student),
                            ),
                            const SizedBox(width: 6),
                            _MiniAction(
                              icon: Icons.edit_outlined,
                              onTap: () => onEditStudent(student),
                            ),
                            const SizedBox(width: 6),
                            _MiniAction(
                              icon: Icons.delete_outline_rounded,
                              danger: true,
                              onTap: () => onDeleteStudent(student),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _summaryLabel(),
                    style: const TextStyle(
                      color: Color(0xFF7080A8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _PagerArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: currentPage > 1,
                    onTap: () => onPageTap(currentPage - 1),
                  ),
                  ..._buildPageItems(),
                  _PagerArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: currentPage < pageCount,
                    onTap: () => onPageTap(currentPage + 1),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  (Color, Color) _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'aktif':
        return (const Color(0xFF1DB56B), const Color(0xFFEAF8EF));
      case 'nonaktif':
        return (const Color(0xFFE84D67), const Color(0xFFFFEDF1));
      default:
        return (const Color(0xFF7C4DFF), const Color(0xFFF1EAFF));
    }
  }

  String _summaryLabel() {
    if (filteredCount == 0) {
      return 'Menampilkan 0 dari $totalStudents siswa';
    }

    final start =
        ((currentPage - 1) * _KesiswaanDashboardPageState._studentsPerPage) + 1;
    final end = start + students.length - 1;
    return 'Menampilkan $start - $end dari $filteredCount siswa';
  }

  List<Widget> _buildPageItems() {
    final pages = <int?>[];
    if (pageCount <= 5) {
      for (var page = 1; page <= pageCount; page++) {
        pages.add(page);
      }
    } else {
      pages.add(1);
      if (currentPage > 3) pages.add(null);
      for (var page = currentPage - 1; page <= currentPage + 1; page++) {
        if (page > 1 && page < pageCount) {
          pages.add(page);
        }
      }
      if (currentPage < pageCount - 2) pages.add(null);
      pages.add(pageCount);
    }

    final widgets = <Widget>[];
    for (final page in pages) {
      widgets.add(
        _PagerNumber(
          label: page?.toString() ?? '...',
          active: page == currentPage,
          enabled: page != null,
          onTap: page == null ? null : () => onPageTap(page),
        ),
      );
      widgets.add(const SizedBox(width: 6));
    }

    if (widgets.isNotEmpty) {
      widgets.removeLast();
      widgets.add(const SizedBox(width: 6));
    }

    return widgets;
  }

  List<String> get _activeFilters {
    final filters = <String>[];
    if (selectedClassFilter != null) filters.add('Kelas: $selectedClassFilter');
    if (selectedMajorFilter != null)
      filters.add('Jurusan: $selectedMajorFilter');
    if (selectedStatusFilter != null)
      filters.add('Status: $selectedStatusFilter');
    return filters;
  }
}

class _ActivityPanel extends StatelessWidget {
  final List<_ActivityInfo> items;
  final bool isLoading;
  final VoidCallback onActionTap;
  final ValueChanged<_ActivityInfo> onItemTap;

  const _ActivityPanel({
    required this.items,
    required this.isLoading,
    required this.onActionTap,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    color: Color(0xFF1A2A61),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Lihat semua',
                    style: TextStyle(
                      color: Color(0xFF2D60F1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada aktivitas terbaru',
                  style: TextStyle(
                    color: Color(0xFF7D89AA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final item = entry.value;
              return InkWell(
                onTap: () => onItemTap(item),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: entry.key == 0
                          ? BorderSide.none
                          : const BorderSide(color: Color(0xFFF0F4FC)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color(0xFF1A2A61),
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(text: item.title),
                              TextSpan(
                                text: ' ${item.actor}',
                                style: const TextStyle(
                                  color: Color(0xFF7D89AA),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: Color(0xFF7D89AA),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InsightMetricGrid extends StatelessWidget {
  final List<_InsightMetric> items;

  const _InsightMetricGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final medium = constraints.maxWidth < 960;
        final itemWidth = compact
            ? double.infinity
            : medium
            ? (constraints.maxWidth - 10) / 2
            : 145.0;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => Container(
                  width: itemWidth,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: item.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.value,
                        style: const TextStyle(
                          color: Color(0xFF1A2A61),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF607094),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StudentFormDialog extends StatefulWidget {
  final StudentRecord? student;

  const _StudentFormDialog({this.student});

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nisController;
  late final TextEditingController _classController;
  late final TextEditingController _majorController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _nisController = TextEditingController(text: widget.student?.nis ?? '');
    _classController = TextEditingController(
      text: widget.student?.className ?? '',
    );
    _majorController = TextEditingController(text: widget.student?.major ?? '');
    _status = (widget.student?.status.trim().isNotEmpty ?? false)
        ? widget.student!.status
        : 'Aktif';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nisController.dispose();
    _classController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Siswa' : 'Tambah Siswa'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(controller: _nameController, label: 'Nama Siswa'),
                const SizedBox(height: 12),
                _buildField(controller: _nisController, label: 'NIS'),
                const SizedBox(height: 12),
                _buildField(controller: _classController, label: 'Kelas'),
                const SizedBox(height: 12),
                _buildField(controller: _majorController, label: 'Jurusan'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'Nonaktif',
                      child: Text('Nonaktif'),
                    ),
                    DropdownMenuItem(value: 'Mutasi', child: Text('Mutasi')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _status = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      StudentRecord(
        id: widget.student?.id,
        name: _nameController.text.trim(),
        nis: _nisController.text.trim(),
        className: _classController.text.trim(),
        major: _majorController.text.trim(),
        status: _status,
      ),
    );
  }
}

class _StudentFilterResult {
  final String? className;
  final String? major;
  final String? status;

  const _StudentFilterResult({
    required this.className,
    required this.major,
    required this.status,
  });
}

class _StudentFilterDialog extends StatefulWidget {
  final List<String> classOptions;
  final List<String> majorOptions;
  final List<String> statusOptions;
  final String? selectedClass;
  final String? selectedMajor;
  final String? selectedStatus;

  const _StudentFilterDialog({
    required this.classOptions,
    required this.majorOptions,
    required this.statusOptions,
    required this.selectedClass,
    required this.selectedMajor,
    required this.selectedStatus,
  });

  @override
  State<_StudentFilterDialog> createState() => _StudentFilterDialogState();
}

class _StudentFilterDialogState extends State<_StudentFilterDialog> {
  String? _selectedClass;
  String? _selectedMajor;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.selectedClass;
    _selectedMajor = widget.selectedMajor;
    _selectedStatus = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Siswa'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDropdown(
              label: 'Kelas',
              value: _selectedClass,
              items: widget.classOptions,
              onChanged: (value) => setState(() => _selectedClass = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Jurusan',
              value: _selectedMajor,
              items: widget.majorOptions,
              onChanged: (value) => setState(() => _selectedMajor = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Status',
              value: _selectedStatus,
              items: widget.statusOptions,
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              const _StudentFilterResult(
                className: null,
                major: null,
                status: null,
              ),
            );
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _StudentFilterResult(
                className: _selectedClass,
                major: _selectedMajor,
                status: _selectedStatus,
              ),
            );
          },
          child: const Text('Terapkan'),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Semua')),
        ...items.map(
          (item) => DropdownMenuItem<String?>(value: item, child: Text(item)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFEEF1) : const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: danger ? const Color(0xFFE84D67) : const Color(0xFF2E61F3),
        ),
      ),
    );
  }
}

class _PagerArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PagerArrow({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD8E2F7)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? const Color(0xFF44537E) : const Color(0xFFB8C1D9),
        ),
      ),
    );
  }
}

class _PagerNumber extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const _PagerNumber({
    required this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E61F3) : Colors.white,
          border: Border.all(
            color: active ? const Color(0xFF2E61F3) : const Color(0xFFD8E2F7),
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : enabled
                ? const Color(0xFF44537E)
                : const Color(0xFFB8C1D9),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _StatItem({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}

class _SimpleInfo {
  final String label;
  final String total;
  final String percent;
  final Color color;

  const _SimpleInfo(this.label, this.total, this.percent, this.color);
}

class _ListInfo {
  final String title;
  final String subtitle;
  final String trailing;

  const _ListInfo(this.title, this.subtitle, this.trailing);
}

class _ActivityInfo {
  final String title;
  final String actor;
  final String time;
  final String type;
  final IconData icon;
  final Color color;
  final Color background;

  const _ActivityInfo(
    this.title,
    this.actor,
    this.time,
    this.type,
    this.icon,
    this.color,
    this.background,
  );
}

class _InsightMetric {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color background;

  const _InsightMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.background,
  });
}
