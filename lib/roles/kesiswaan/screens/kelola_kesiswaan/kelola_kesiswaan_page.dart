import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/models/activity_log.dart';
import 'package:lms_guru/roles/kesiswaan/models/student_record.dart';
import 'package:lms_guru/roles/kesiswaan/models/student_violation.dart';
import 'package:lms_guru/roles/kesiswaan/screens/auth/login_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kelola_menu_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_jurnal/kelola_jurnal_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/rekap_absensi/rekap_absensi_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/users/kelola_user_page.dart';
import 'package:lms_guru/roles/kesiswaan/services/lms_api_service.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';

class KelolaKesiswaanPage extends StatefulWidget {
  const KelolaKesiswaanPage({super.key});

  @override
  State<KelolaKesiswaanPage> createState() => _KelolaKesiswaanPageState();
}

class _KelolaKesiswaanPageState extends State<KelolaKesiswaanPage> {
  static const int _pageSize = 6;

  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<StudentRecord> _students = [];
  final List<StudentViolation> _violations = [];
  List<ActivityLog> _activities = const [];
  Map<String, dynamic>? _summary;

  String _selectedClass = 'Semua Kelas';
  String _selectedMajor = 'Semua Jurusan';
  String _selectedStatus = 'Semua Status';
  int _currentPage = 1;
  bool _isLoadingStudents = false;
  bool _isLoadingViolations = false;
  bool _isLoadingActivities = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _currentPage = 1);
    });
    _loadStudents();
    _loadViolations();
    _loadActivities();
    _loadSummary();
  }

  @override
  void dispose() {
    _profileStore.removeListener(_handleProfileChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleProfileChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String get _name => (_profileStore.profile?.name.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.name.trim()
      : 'Profil Kesiswaan';

  String get _role => (_profileStore.profile?.role.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.role.trim()
      : 'Kesiswaan';

  String get _initial => _name.substring(0, 1).toUpperCase();
  Uint8List? get _avatarBytes => _profileStore.profile?.avatarBytes;

  List<String> get _classOptions => [
    'Semua Kelas',
    ..._students
        .map((student) => student.className.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<String> get _majorOptions => [
    'Semua Jurusan',
    ..._students
        .map((student) => student.major.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  static const List<String> _statusOptions = [
    'Semua Status',
    'Aktif',
    'Nonaktif',
    'Mutasi',
  ];

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _errorText = null;
    });

    try {
      final students = await _api.getStudents();
      if (!mounted) return;
      setState(() {
        _students
          ..clear()
          ..addAll(students);
        _currentPage = 1;
        _normalizeFilters();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = '$error');
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final logs = await _api.getActivityLogs();
      if (!mounted) return;
      setState(() => _activities = logs);
    } catch (_) {
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingActivities = false);
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
    setState(() => _isLoadingViolations = true);
    try {
      final items = await _api.getStudentViolations();
      if (!mounted) return;
      setState(() {
        _violations
          ..clear()
          ..addAll(items);
      });
    } catch (_) {
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingViolations = false);
    }
  }

  void _normalizeFilters() {
    if (!_classOptions.contains(_selectedClass)) {
      _selectedClass = 'Semua Kelas';
    }
    if (!_majorOptions.contains(_selectedMajor)) {
      _selectedMajor = 'Semua Jurusan';
    }
    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = 'Semua Status';
    }
  }

  List<StudentRecord> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    return _students.where((student) {
      final matchesQuery = query.isEmpty ||
          [
            student.name,
            student.nis,
            student.className,
            student.major,
            student.status,
          ].join(' ').toLowerCase().contains(query);
      final matchesClass =
          _selectedClass == 'Semua Kelas' || student.className == _selectedClass;
      final matchesMajor =
          _selectedMajor == 'Semua Jurusan' || student.major == _selectedMajor;
      final matchesStatus =
          _selectedStatus == 'Semua Status' || student.status == _selectedStatus;
      return matchesQuery && matchesClass && matchesMajor && matchesStatus;
    }).toList(growable: false);
  }

  List<StudentRecord> get _pagedStudents {
    final filtered = _filteredStudents;
    if (filtered.isEmpty) return const [];
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages {
    final total = (_filteredStudents.length / _pageSize).ceil();
    return total <= 0 ? 1 : total;
  }

  int get _activeCount =>
      (_summary?['activeStudents'] as num?)?.toInt() ??
      _students.where((student) => student.status.trim().toLowerCase() == 'aktif').length;
  int get _mutationCount =>
      (_summary?['mutationStudents'] as num?)?.toInt() ??
      _students.where((student) => student.status.trim().toLowerCase() == 'mutasi').length;
  int get _violationCount =>
      (_summary?['violationCount'] as num?)?.toInt() ?? _violations.length;
  int get _classCount =>
      (_summary?['classCount'] as num?)?.toInt() ??
      _students.map((student) => student.className.trim()).where((value) => value.isNotEmpty).toSet().length;

  List<_KesiswaanInfoItem> get _mutationItems {
    final summaryItems = _summary?['recentMutations'];
    if (summaryItems is List && summaryItems.isNotEmpty) {
      return summaryItems.whereType<Map>().map((item) {
        return _KesiswaanInfoItem(
          title: '${item['title'] ?? ''}',
          subtitle: '${item['subtitle'] ?? ''}',
          trailing: _formatSummaryTime('${item['trailing'] ?? ''}'),
          icon: Icons.sync_alt_rounded,
          color: const Color(0xFFF28A1B),
          background: const Color(0xFFFFF3E6),
        );
      }).toList(growable: false);
    }

    return _activities
        .where((item) => item.type.trim().toLowerCase() == 'student_mutation')
        .take(3)
        .map(
          (item) => _KesiswaanInfoItem(
            title: item.title,
            subtitle: item.actor,
            trailing: item.createdAt == null
                ? 'Baru saja'
                : _ActivityPanel.formatActivityTime(item.createdAt!),
            icon: Icons.sync_alt_rounded,
            color: const Color(0xFFF28A1B),
            background: const Color(0xFFFFF3E6),
          ),
        )
        .toList(growable: false);
  }

  List<_KesiswaanInfoItem> get _recentViolations {
    final summaryItems = _summary?['recentViolations'];
    if (summaryItems is List && summaryItems.isNotEmpty) {
      return summaryItems.whereType<Map>().map((item) {
        final subtitle = '${item['subtitle'] ?? ''}';
        return _KesiswaanInfoItem(
          title: '${item['title'] ?? ''}',
          subtitle: subtitle,
          trailing: '${item['trailing'] ?? ''}',
          icon: _violationIcon(subtitle),
          color: _violationColor(subtitle),
          background: _violationBackground(subtitle),
        );
      }).toList(growable: false);
    }

    return _violations
        .take(3)
        .map(
          (item) => _KesiswaanInfoItem(
            title: '${item.studentName} (${item.className})',
            subtitle: item.violationType,
            trailing: item.violationDate,
            icon: _violationIcon(item.violationType),
            color: _violationColor(item.violationType),
            background: _violationBackground(item.violationType),
          ),
        )
        .toList(growable: false);
  }

  String _formatSummaryTime(String raw) {
    if (raw.trim().isEmpty) return 'Baru saja';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _ActivityPanel.formatActivityTime(parsed);
  }

  IconData _violationIcon(String type) {
    final lower = type.trim().toLowerCase();
    if (lower.contains('terlambat')) return Icons.access_time_filled_rounded;
    if (lower.contains('atribut')) return Icons.badge_rounded;
    if (lower.contains('izin')) return Icons.logout_rounded;
    return Icons.warning_amber_rounded;
  }

  Color _violationColor(String type) => _violationColorForType(type);

  Color _violationBackground(String type) => _violationBackgroundForType(type);

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KesiswaanDashboardPage()),
    );
  }

  void _openUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KelolaUserPage()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void _logout() {
    _profileStore.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openBottomNav(int index) {
    if (index == 0) {
      _openDashboard();
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KelolaJurnalPage()),
      );
      return;
    }
    if (index == 2) return;
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RekapAbsensiPage()),
      );
      return;
    }
    if (index == 4) {
      _openProfile();
      return;
    }
  }

  Future<void> _showMessageDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showViolationForm({StudentViolation? item}) async {
    final result = await showDialog<StudentViolation>(
      context: context,
      builder: (context) => _ViolationFormDialog(
        item: item,
        students: _students,
      ),
    );

    if (result == null) return;

    try {
      if (item == null) {
        final created = await _api.createStudentViolation(result);
        if (!mounted) return;
        await _loadViolations();
        await _loadSummary();
        if (!mounted) return;
        await _addActivity(
          title: 'Pelanggaran siswa "${created.studentName}" ditambahkan',
          actor: 'oleh Kesiswaan',
          type: 'violation_add',
        );
      } else {
        final updated = await _api.updateStudentViolation(result);
        if (!mounted) return;
        await _loadViolations();
        await _loadSummary();
        if (!mounted) return;
        await _addActivity(
          title: 'Pelanggaran siswa "${updated.studentName}" diperbarui',
          actor: 'oleh Kesiswaan',
          type: 'violation_edit',
        );
      }
      if (!mounted) return;
      await _loadActivities();
      await _loadSummary();
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Simpan Gagal', '$error');
    }
  }

  Future<void> _showViolationDetail(StudentViolation item) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Detail Pelanggaran'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLine('Nama Siswa', item.studentName),
              _detailLine('Kelas', item.className),
              _detailLine('Jenis Pelanggaran', item.violationType),
              _detailLine('Deskripsi', item.description),
              _detailLine(
                'Tindak Lanjut',
                item.actionTaken.trim().isEmpty ? '-' : item.actionTaken,
              ),
              _detailLine('Poin', '${item.points}'),
              _detailLine('Tanggal', item.violationDate),
            ],
          ),
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

  Future<void> _deleteViolation(StudentViolation item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Pelanggaran'),
        content: Text('Hapus catatan pelanggaran ${item.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84D67),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || item.id == null) return;

    try {
      await _api.deleteStudentViolation(item.id!);
      if (!mounted) return;
      await _loadViolations();
      await _loadSummary();
      if (!mounted) return;
      await _addActivity(
        title: 'Pelanggaran siswa "${item.studentName}" dihapus',
        actor: 'oleh Kesiswaan',
        type: 'violation_delete',
      );
      if (!mounted) return;
      await _loadActivities();
      await _loadSummary();
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Hapus Gagal', '$error');
    }
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF1A2A61),
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
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

  Future<void> _showStudentForm({StudentRecord? student}) async {
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

  Future<void> _showStudentDetail(StudentRecord student) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Siswa'),
        content: Text('Hapus data ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84D67),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (student.id == null) throw Exception('ID siswa kosong');
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;
    final paged = _pagedStudents;
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1120;
    final mobile = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroHeader(
                    name: _name,
                    role: _role,
                    initial: _initial,
                    avatarBytes: _avatarBytes,
                    onBackTap: _openDashboard,
                    onProfileTap: _openProfile,
                    onLogoutTap: _logout,
                  ),
                  const SizedBox(height: 28),
                  mobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kelola Kesiswaan',
                              style: TextStyle(
                                color: Color(0xFF1A2A61),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kelola data siswa, mutasi, dan aktivitas kesiswaan dalam satu halaman kerja.',
                              style: TextStyle(
                                color: Color(0xFF7D89AA),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showStudentForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E61F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.person_add_alt_1_rounded),
                                label: const Text('Tambah Siswa'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kelola Kesiswaan',
                                    style: TextStyle(
                                      color: Color(0xFF1A2A61),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Kelola data siswa, mutasi, dan aktivitas kesiswaan dalam satu halaman kerja.',
                                    style: TextStyle(
                                      color: Color(0xFF7D89AA),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showStudentForm(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E61F3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Tambah Siswa'),
                            ),
                          ],
                        ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Total Siswa',
                        value: '${_students.length}',
                        note: 'Semua siswa terdaftar',
                        icon: Icons.groups_rounded,
                        iconColor: const Color(0xFF3366F3),
                        iconBackground: const Color(0xFFEAF0FF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Siswa Aktif',
                        value: '$_activeCount',
                        note: 'Status aktif saat ini',
                        icon: Icons.verified_user_rounded,
                        iconColor: const Color(0xFF1DB56B),
                        iconBackground: const Color(0xFFEAF8EF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Data Mutasi',
                        value: '$_mutationCount',
                        note: 'Siswa dengan status mutasi',
                        icon: Icons.sync_alt_rounded,
                        iconColor: const Color(0xFFF28A1B),
                        iconBackground: const Color(0xFFFFF3E6),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Total Kelas',
                        value: '$_classCount',
                        note: 'Kelas aktif terdata',
                        icon: Icons.account_balance_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        iconBackground: const Color(0xFFF1EAFF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _InsightPanel(
                        width: compact ? double.infinity : 470,
                        title: 'Pelanggaran Terbaru',
                        subtitle:
                            'Catatan pelanggaran siswa yang perlu tindak lanjut kesiswaan.',
                        accent: const Color(0xFFF28A1B),
                        items: _recentViolations,
                      ),
                      _InsightPanel(
                        width: compact ? double.infinity : 470,
                        title: 'Mutasi Terbaru',
                        subtitle: 'Ringkasan perpindahan siswa terbaru.',
                        accent: const Color(0xFF3366F3),
                        items: _mutationItems,
                      ),
                      _ActivityPanel(
                        width: compact ? double.infinity : 470,
                        items: _activities,
                        isLoading: _isLoadingActivities,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (compact)
                    Column(
                      children: [
                        _StudentPanel(
                          searchController: _searchController,
                          classValue: _selectedClass,
                          classItems: _classOptions,
                          majorValue: _selectedMajor,
                          majorItems: _majorOptions,
                          statusValue: _selectedStatus,
                          statusItems: _statusOptions,
                          onClassChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedClass = value;
                              _currentPage = 1;
                            });
                          },
                          onMajorChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedMajor = value;
                              _currentPage = 1;
                            });
                          },
                          onStatusChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedStatus = value;
                              _currentPage = 1;
                            });
                          },
                          onReload: _loadStudents,
                          isLoading: _isLoadingStudents,
                          errorText: _errorText,
                          items: paged,
                          totalItems: filtered.length,
                          currentPage: _currentPage,
                          totalPages: _totalPages,
                          onPrevPage: _currentPage > 1
                              ? () => setState(() => _currentPage -= 1)
                              : null,
                          onNextPage: _currentPage < _totalPages
                              ? () => setState(() => _currentPage += 1)
                              : null,
                          onTapPage: (page) => setState(() => _currentPage = page),
                          onView: _showStudentDetail,
                          onEdit: (item) => _showStudentForm(student: item),
                          onDelete: _deleteStudent,
                        ),
                      ],
                    )
                  else
                    _StudentPanel(
                      searchController: _searchController,
                      classValue: _selectedClass,
                      classItems: _classOptions,
                      majorValue: _selectedMajor,
                      majorItems: _majorOptions,
                      statusValue: _selectedStatus,
                      statusItems: _statusOptions,
                      onClassChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedClass = value;
                          _currentPage = 1;
                        });
                      },
                      onMajorChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedMajor = value;
                          _currentPage = 1;
                        });
                      },
                      onStatusChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedStatus = value;
                          _currentPage = 1;
                        });
                      },
                      onReload: _loadStudents,
                      isLoading: _isLoadingStudents,
                      errorText: _errorText,
                      items: paged,
                      totalItems: filtered.length,
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      onPrevPage: _currentPage > 1
                          ? () => setState(() => _currentPage -= 1)
                          : null,
                      onNextPage: _currentPage < _totalPages
                          ? () => setState(() => _currentPage += 1)
                          : null,
                      onTapPage: (page) => setState(() => _currentPage = page),
                      onView: _showStudentDetail,
                      onEdit: (item) => _showStudentForm(student: item),
                      onDelete: _deleteStudent,
                    ),
                  const SizedBox(height: 20),
                  _ViolationPanel(
                    items: _violations,
                    isLoading: _isLoadingViolations,
                    totalItems: _violationCount,
                    onReload: _loadViolations,
                    onAdd: () => _showViolationForm(),
                    onView: _showViolationDetail,
                    onEdit: (item) => _showViolationForm(item: item),
                    onDelete: _deleteViolation,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: KesiswaanBottomNavBar(
            currentIndex: 2,
            onTap: _openBottomNav,
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final Uint8List? avatarBytes;
  final VoidCallback onBackTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const _HeroHeader({
    required this.name,
    required this.role,
    required this.initial,
    required this.avatarBytes,
    required this.onBackTap,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20, vertical: compact ? 16 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E61F3), Color(0xFF2B45D7)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: compact ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBackTap,
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(24),
                child: KesiswaanHeaderAvatar(
                  initial: initial,
                  avatarBytes: avatarBytes,
                  radius: 20,
                  outerColor: Colors.white,
                  innerColor: const Color(0xFF2953E3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Kelola Kesiswaan',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manajemen operasional siswa kesiswaan',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Color(0xFFDDE5FF), fontWeight: FontWeight.w600),
          ),
        ],
      ) : Row(
        children: [
          InkWell(
            onTap: onBackTap,
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Kesiswaan',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Manajemen operasional siswa kesiswaan',
                  style: TextStyle(color: Color(0xFFDDE5FF), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                KesiswaanHeaderAvatar(
                  initial: initial,
                  avatarBytes: avatarBytes,
                  radius: 18,
                  outerColor: Colors.white,
                  innerColor: const Color(0xFF2953E3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEF9)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 56 : 68,
            height: compact ? 56 : 68,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: compact ? 28 : 34),
          ),
          SizedBox(width: compact ? 14 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF57668E),
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 8 : 10),
                Text(
                  value,
                  style: TextStyle(
                    color: Color(0xFF1B2B68),
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8694B8),
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String classValue;
  final List<String> classItems;
  final String majorValue;
  final List<String> majorItems;
  final String statusValue;
  final List<String> statusItems;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onMajorChanged;
  final ValueChanged<String?> onStatusChanged;
  final Future<void> Function() onReload;
  final bool isLoading;
  final String? errorText;
  final List<StudentRecord> items;
  final int totalItems;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;
  final ValueChanged<int> onTapPage;
  final ValueChanged<StudentRecord> onView;
  final ValueChanged<StudentRecord> onEdit;
  final ValueChanged<StudentRecord> onDelete;

  const _StudentPanel({
    required this.searchController,
    required this.classValue,
    required this.classItems,
    required this.majorValue,
    required this.majorItems,
    required this.statusValue,
    required this.statusItems,
    required this.onClassChanged,
    required this.onMajorChanged,
    required this.onStatusChanged,
    required this.onReload,
    required this.isLoading,
    required this.errorText,
    required this.items,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onTapPage,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Siswa',
            style: TextStyle(
              color: Color(0xFF1A2A61),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: compact ? double.infinity : 280,
                child: _SearchField(controller: searchController),
              ),
              SizedBox(
                width: compact ? double.infinity : 180,
                child: _FilterDropdown(
                  value: classValue,
                  items: classItems,
                  onChanged: onClassChanged,
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : 180,
                child: _FilterDropdown(
                  value: majorValue,
                  items: majorItems,
                  onChanged: onMajorChanged,
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : 180,
                child: _FilterDropdown(
                  value: statusValue,
                  items: statusItems,
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: compact ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: onReload,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Muat Ulang'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorText != null)
            _LoadErrorState(message: errorText!, onRetry: onReload)
          else if (items.isEmpty)
            const _EmptyState()
          else ...[
            if (compact)
              ...items.map(
                (student) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StudentMobileCard(
                    student: student,
                    onView: () => onView(student),
                    onEdit: () => onEdit(student),
                    onDelete: () => onDelete(student),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFF)),
                  columns: const [
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('NIS')),
                    DataColumn(label: Text('Kelas')),
                    DataColumn(label: Text('Jurusan')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Aksi')),
                  ],
                  rows: items.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            student.name,
                            style: const TextStyle(
                              color: Color(0xFF1A2A61),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataCell(Text(student.nis)),
                        DataCell(Text(student.className)),
                        DataCell(Text(student.major)),
                        DataCell(_StatusBadge(status: student.status)),
                        DataCell(
                          Row(
                            children: [
                              _MiniAction(
                                icon: Icons.visibility_outlined,
                                onTap: () => onView(student),
                              ),
                              const SizedBox(width: 8),
                              _MiniAction(
                                icon: Icons.edit_outlined,
                                onTap: () => onEdit(student),
                              ),
                              const SizedBox(width: 8),
                              _MiniAction(
                                icon: Icons.delete_outline_rounded,
                                danger: true,
                                onTap: () => onDelete(student),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(growable: false),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Total tersaring: $totalItems siswa',
                  style: const TextStyle(
                    color: Color(0xFF7D89AA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _PagerArrow(
                      icon: Icons.chevron_left_rounded,
                      enabled: onPrevPage != null,
                      onTap: onPrevPage ?? () {},
                    ),
                    ...List.generate(
                      totalPages > 5 ? 5 : totalPages,
                      (index) {
                        final page = index + 1;
                        return _PagerNumber(
                          label: '$page',
                          active: currentPage == page,
                          onTap: () => onTapPage(page),
                        );
                      },
                    ),
                    _PagerArrow(
                      icon: Icons.chevron_right_rounded,
                      enabled: onNextPage != null,
                      onTap: onNextPage ?? () {},
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ViolationPanel extends StatelessWidget {
  final List<StudentViolation> items;
  final bool isLoading;
  final int totalItems;
  final Future<void> Function() onReload;
  final VoidCallback onAdd;
  final ValueChanged<StudentViolation> onView;
  final ValueChanged<StudentViolation> onEdit;
  final ValueChanged<StudentViolation> onDelete;

  const _ViolationPanel({
    required this.items,
    required this.isLoading,
    required this.totalItems,
    required this.onReload,
    required this.onAdd,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Pelanggaran Siswa',
                      style: TextStyle(
                        color: Color(0xFF1A2A61),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Catat, pantau, dan tindak lanjuti pelanggaran siswa dari kesiswaan.',
                      style: TextStyle(
                        color: Color(0xFF7D89AA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onReload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Muat Ulang'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF28A1B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Pelanggaran'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Pelanggaran Siswa',
                            style: TextStyle(
                              color: Color(0xFF1A2A61),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Catat, pantau, dan tindak lanjuti pelanggaran siswa dari kesiswaan.',
                            style: TextStyle(
                              color: Color(0xFF7D89AA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: onReload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Muat Ulang'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF28A1B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah Pelanggaran'),
                    ),
                  ],
                ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Belum ada pelanggaran siswa',
                  style: TextStyle(
                    color: Color(0xFF7D89AA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (compact)
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ViolationMobileCard(
                  item: item,
                  onView: () => onView(item),
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF8F0)),
                columns: const [
                  DataColumn(label: Text('Siswa')),
                  DataColumn(label: Text('Kelas')),
                  DataColumn(label: Text('Jenis')),
                  DataColumn(label: Text('Poin')),
                  DataColumn(label: Text('Tindak Lanjut')),
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item.studentName,
                          style: const TextStyle(
                            color: Color(0xFF1A2A61),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(Text(item.className)),
                      DataCell(_ViolationBadge(type: item.violationType)),
                      DataCell(Text('${item.points}')),
                      DataCell(Text(item.actionTaken.trim().isEmpty ? '-' : item.actionTaken)),
                      DataCell(Text(item.violationDate)),
                      DataCell(
                        Row(
                          children: [
                            _MiniAction(
                              icon: Icons.visibility_outlined,
                              onTap: () => onView(item),
                            ),
                            const SizedBox(width: 8),
                            _MiniAction(
                              icon: Icons.edit_outlined,
                              onTap: () => onEdit(item),
                            ),
                            const SizedBox(width: 8),
                            _MiniAction(
                              icon: Icons.delete_outline_rounded,
                              danger: true,
                              onTap: () => onDelete(item),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Total pelanggaran tercatat: $totalItems',
            style: const TextStyle(
              color: Color(0xFF7D89AA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViolationBadge extends StatelessWidget {
  final String type;

  const _ViolationBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _violationColorForType(type);
    final background = _violationBackgroundForType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final Color accent;
  final List<_KesiswaanInfoItem> items;

  const _InsightPanel({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A2A61),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            maxLines: compact ? 3 : null,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
            style: const TextStyle(
              color: Color(0xFF7D89AA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada data yang ditampilkan',
                style: TextStyle(
                  color: Color(0xFF7D89AA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InsightTile(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final _KesiswaanInfoItem item;

  const _InsightTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0FB)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1A2A61),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7D89AA),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.trailing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9AA6C3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Color(0xFF1A2A61),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF7D89AA),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.trailing,
                  style: const TextStyle(
                    color: Color(0xFF9AA6C3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  final double width;
  final List<ActivityLog> items;
  final bool isLoading;

  const _ActivityPanel({
    required this.width,
    required this.items,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              color: Color(0xFF1A2A61),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Belum ada aktivitas terbaru',
                  style: TextStyle(
                    color: Color(0xFF7D89AA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...items.take(8).map((item) {
              final style = _activityStyle(item.type);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAF0FB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: style.$3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(style.$1, color: style.$2, size: 20),
                    ),
                    const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.actor,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7D89AA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              formatActivityTime(item.createdAt!),
                              style: const TextStyle(
                                color: Color(0xFF9AA6C3),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  static String formatActivityTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static (IconData, Color, Color) _activityStyle(String type) {
    switch (type.trim().toLowerCase()) {
      case 'student_add':
        return (
          Icons.group_add_rounded,
          const Color(0xFF1DB56B),
          const Color(0xFFEAF8EF),
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
      case 'student_edit':
        return (
          Icons.edit_outlined,
          const Color(0xFF3366F3),
          const Color(0xFFEAF0FF),
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
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari nama, NIS, kelas, atau jurusan...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE5F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF345DF4), width: 1.3),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE5F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF345DF4), width: 1.3),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.trim().toLowerCase();
    late final Color bg;
    late final Color color;
    if (lower == 'aktif') {
      bg = const Color(0xFFEAF8EF);
      color = const Color(0xFF1DB56B);
    } else if (lower == 'mutasi') {
      bg = const Color(0xFFFFF3E6);
      color = const Color(0xFFF28A1B);
    } else {
      bg = const Color(0xFFFFEDF1);
      color = const Color(0xFFE84D67);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
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
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFEEF1) : const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: danger ? const Color(0xFFE84D67) : const Color(0xFF2E61F3),
        ),
      ),
    );
  }
}

class _StudentMobileCard extends StatelessWidget {
  final StudentRecord student;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentMobileCard({
    required this.student,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1A2A61),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'NIS: ${student.nis}',
            style: const TextStyle(
              color: Color(0xFF7D89AA),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${student.className} • ${student.major}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7D89AA),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _StatusBadge(status: student.status),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniAction(icon: Icons.visibility_outlined, onTap: onView),
              _MiniAction(icon: Icons.edit_outlined, onTap: onEdit),
              _MiniAction(
                icon: Icons.delete_outline_rounded,
                danger: true,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViolationMobileCard extends StatelessWidget {
  final StudentViolation item;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ViolationMobileCard({
    required this.item,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFECD7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.studentName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1A2A61),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kelas: ${item.className}',
            style: const TextStyle(
              color: Color(0xFF7D89AA),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _ViolationBadge(type: item.violationType),
          const SizedBox(height: 10),
          Text(
            'Poin: ${item.points}',
            style: const TextStyle(
              color: Color(0xFF1A2A61),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tanggal: ${item.violationDate}',
            style: const TextStyle(
              color: Color(0xFF7D89AA),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (item.actionTaken.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tindak lanjut: ${item.actionTaken}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7D89AA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniAction(icon: Icons.visibility_outlined, onTap: onView),
              _MiniAction(icon: Icons.edit_outlined, onTap: onEdit),
              _MiniAction(
                icon: Icons.delete_outline_rounded,
                danger: true,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _LoadErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.groups_rounded, size: 42, color: Color(0xFF91A0C7)),
            SizedBox(height: 10),
            Text(
              'Data siswa tidak ditemukan',
              style: TextStyle(
                color: Color(0xFF5E6D94),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _violationColorForType(String type) {
  final lower = type.trim().toLowerCase();
  if (lower.contains('terlambat')) return const Color(0xFFF28A1B);
  if (lower.contains('atribut')) return const Color(0xFFE84D67);
  if (lower.contains('izin')) return const Color(0xFF7C4DFF);
  return const Color(0xFFF28A1B);
}

Color _violationBackgroundForType(String type) {
  final lower = type.trim().toLowerCase();
  if (lower.contains('terlambat')) return const Color(0xFFFFF3E6);
  if (lower.contains('atribut')) return const Color(0xFFFFEDF1);
  if (lower.contains('izin')) return const Color(0xFFF1EAFF);
  return const Color(0xFFFFF3E6);
}

class _ViolationFormDialog extends StatefulWidget {
  final StudentViolation? item;
  final List<StudentRecord> students;

  const _ViolationFormDialog({
    this.item,
    required this.students,
  });

  @override
  State<_ViolationFormDialog> createState() => _ViolationFormDialogState();
}

class _ViolationFormDialogState extends State<_ViolationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentController;
  late final TextEditingController _classController;
  late final TextEditingController _typeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _actionController;
  late final TextEditingController _pointsController;
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _studentController = TextEditingController(text: widget.item?.studentName ?? '');
    _classController = TextEditingController(text: widget.item?.className ?? '');
    _typeController = TextEditingController(text: widget.item?.violationType ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _actionController = TextEditingController(text: widget.item?.actionTaken ?? '');
    _pointsController = TextEditingController(
      text: widget.item != null ? '${widget.item!.points}' : '0',
    );
    _dateController = TextEditingController(text: widget.item?.violationDate ?? '');
  }

  @override
  void dispose() {
    _studentController.dispose();
    _classController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _actionController.dispose();
    _pointsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentNames = widget.students.map((item) => item.name).toList(growable: false);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.item == null ? 'Tambah Pelanggaran' : 'Edit Pelanggaran'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: studentNames.contains(_studentController.text.trim())
                      ? _studentController.text.trim()
                      : null,
                  decoration: _inputDecoration('Nama Siswa'),
                  items: studentNames
                      .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    _studentController.text = value;
                    StudentRecord? student;
                    for (final item in widget.students) {
                      if (item.name == value) {
                        student = item;
                        break;
                      }
                    }
                    if (student != null) {
                      _classController.text = student.className;
                    }
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama siswa wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _FormField(controller: _classController, label: 'Kelas'),
                const SizedBox(height: 12),
                _FormField(controller: _typeController, label: 'Jenis Pelanggaran'),
                const SizedBox(height: 12),
                _FormField(
                  controller: _descriptionController,
                  label: 'Deskripsi',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _FormField(controller: _actionController, label: 'Tindak Lanjut'),
                const SizedBox(height: 12),
                _FormField(
                  controller: _pointsController,
                  label: 'Poin',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _FormField(controller: _dateController, label: 'Tanggal Pelanggaran'),
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
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF28A1B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFDFEFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF28A1B)),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      StudentViolation(
        id: widget.item?.id,
        studentName: _studentController.text.trim(),
        className: _classController.text.trim(),
        violationType: _typeController.text.trim(),
        description: _descriptionController.text.trim(),
        actionTaken: _actionController.text.trim(),
        points: int.tryParse(_pointsController.text.trim()) ?? 0,
        violationDate: _dateController.text.trim(),
      ),
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
    _classController = TextEditingController(text: widget.student?.className ?? '');
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.student == null ? 'Tambah Siswa' : 'Edit Siswa'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(controller: _nameController, label: 'Nama Siswa'),
                const SizedBox(height: 12),
                _FormField(controller: _nisController, label: 'NIS'),
                const SizedBox(height: 12),
                _FormField(controller: _classController, label: 'Kelas'),
                const SizedBox(height: 12),
                _FormField(controller: _majorController, label: 'Jurusan'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: const Color(0xFFFDFEFF),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E61F3)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(value: 'Nonaktif', child: Text('Nonaktif')),
                    DropdownMenuItem(value: 'Mutasi', child: Text('Mutasi')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
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
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E61F3),
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFDFEFF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E61F3)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
    );
  }
}

class _PagerArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PagerArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE5F7)),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF536388) : const Color(0xFFB7C2DC),
        ),
      ),
    );
  }
}

class _PagerNumber extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PagerNumber({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF345DF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF345DF4) : const Color(0xFFDCE5F7),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF536388),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _KesiswaanInfoItem {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final Color color;
  final Color background;

  const _KesiswaanInfoItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.color,
    required this.background,
  });
}
