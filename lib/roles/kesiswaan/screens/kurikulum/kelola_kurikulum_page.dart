import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/models/curriculum_record.dart';
import 'package:lms_guru/roles/kesiswaan/screens/auth/login_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_jurnal/kelola_jurnal_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/rekap_absensi/rekap_absensi_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/users/kelola_user_page.dart';
import 'package:lms_guru/roles/kesiswaan/services/lms_api_service.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';

class KelolaKurikulumPage extends StatefulWidget {
  const KelolaKurikulumPage({super.key});

  @override
  State<KelolaKurikulumPage> createState() => _KelolaKurikulumPageState();
}

class _KelolaKurikulumPageState extends State<KelolaKurikulumPage> {
  static const int _pageSize = 6;
  static const List<String> _statusOptions = [
    'Semua Status',
    'Aktif',
    'Nonaktif',
  ];

  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<CurriculumRecord> _curriculums = [];

  String _selectedMajor = 'Semua Jurusan';
  String _selectedGrade = 'Semua Kelas';
  String _selectedStatus = 'Semua Status';
  String _selectedSchoolYear = 'Semua Tahun';
  String _draftSelectedMajor = 'Semua Jurusan';
  String _draftSelectedGrade = 'Semua Kelas';
  String _draftSelectedStatus = 'Semua Status';
  String _draftSelectedSchoolYear = 'Semua Tahun';
  int _currentPage = 1;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
      });
    });
    _loadCurriculums();
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

  List<String> get _majorOptions => [
    'Semua Jurusan',
    ..._curriculums
        .map((item) => item.major)
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<String> get _gradeOptions => [
    'Semua Kelas',
    ..._curriculums
        .map((item) => item.grade)
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<String> get _schoolYearOptions => [
    'Semua Tahun',
    ..._curriculums
        .map((item) => item.schoolYear)
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  Future<void> _loadCurriculums() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await _api.getCurriculums();
      if (!mounted) return;
      setState(() {
        _curriculums
          ..clear()
          ..addAll(items);
        _currentPage = 1;
        _normalizeFilters();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = '$error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _normalizeFilters() {
    if (!_majorOptions.contains(_selectedMajor)) {
      _selectedMajor = 'Semua Jurusan';
    }
    if (!_gradeOptions.contains(_selectedGrade)) {
      _selectedGrade = 'Semua Kelas';
    }
    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = 'Semua Status';
    }
    if (!_schoolYearOptions.contains(_selectedSchoolYear)) {
      _selectedSchoolYear = 'Semua Tahun';
    }
    if (!_majorOptions.contains(_draftSelectedMajor)) {
      _draftSelectedMajor = _selectedMajor;
    }
    if (!_gradeOptions.contains(_draftSelectedGrade)) {
      _draftSelectedGrade = _selectedGrade;
    }
    if (!_statusOptions.contains(_draftSelectedStatus)) {
      _draftSelectedStatus = _selectedStatus;
    }
    if (!_schoolYearOptions.contains(_draftSelectedSchoolYear)) {
      _draftSelectedSchoolYear = _selectedSchoolYear;
    }
  }

  List<CurriculumRecord> get _filteredCurriculums {
    final query = _searchController.text.trim().toLowerCase();
    return _curriculums.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.subject.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query) ||
          item.teacher.toLowerCase().contains(query) ||
          item.major.toLowerCase().contains(query) ||
          item.grade.toLowerCase().contains(query) ||
          item.schoolYear.toLowerCase().contains(query);
      final matchesMajor =
          _selectedMajor == 'Semua Jurusan' ||
          item.major.trim().toLowerCase() == _selectedMajor.trim().toLowerCase();
      final matchesGrade =
          _selectedGrade == 'Semua Kelas' ||
          item.grade.trim().toLowerCase() == _selectedGrade.trim().toLowerCase();
      final matchesStatus =
          _selectedStatus == 'Semua Status' ||
          item.status.trim().toLowerCase() == _selectedStatus.trim().toLowerCase();
      final matchesSchoolYear =
          _selectedSchoolYear == 'Semua Tahun' ||
          item.schoolYear.trim() == _selectedSchoolYear.trim();
      return matchesQuery &&
          matchesMajor &&
          matchesGrade &&
          matchesStatus &&
          matchesSchoolYear;
    }).toList(growable: false);
  }

  List<CurriculumRecord> get _pagedCurriculums {
    final filtered = _filteredCurriculums;
    if (filtered.isEmpty) return const [];
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages {
    final total = (_filteredCurriculums.length / _pageSize).ceil();
    return total <= 0 ? 1 : total;
  }

  int get _totalSubjects => _curriculums.length;

  int get _totalMajors => _curriculums
      .map((item) => item.major)
      .where((item) => item.trim().isNotEmpty)
      .toSet()
      .length;

  int get _totalClasses => _curriculums
      .map((item) => '${item.grade.trim()}-${item.major.trim()}')
      .where((item) => item.replaceAll('-', '').trim().isNotEmpty)
      .toSet()
      .length;

  int get _totalSchoolYears => _curriculums
      .map((item) => item.schoolYear.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .length;

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
    if (index == 2) return;
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

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedMajor = _draftSelectedMajor;
      _selectedGrade = _draftSelectedGrade;
      _selectedStatus = _draftSelectedStatus;
      _selectedSchoolYear = _draftSelectedSchoolYear;
      _currentPage = 1;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedMajor = 'Semua Jurusan';
      _selectedGrade = 'Semua Kelas';
      _selectedStatus = 'Semua Status';
      _selectedSchoolYear = 'Semua Tahun';
      _draftSelectedMajor = 'Semua Jurusan';
      _draftSelectedGrade = 'Semua Kelas';
      _draftSelectedStatus = 'Semua Status';
      _draftSelectedSchoolYear = 'Semua Tahun';
      _currentPage = 1;
    });
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

  Future<void> _showCurriculumForm({CurriculumRecord? item}) async {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController(text: item?.subject ?? '');
    final codeController = TextEditingController(text: item?.code ?? '');
    final teacherController = TextEditingController(text: item?.teacher ?? '');
    final schoolYearController = TextEditingController(
      text: item?.schoolYear.isNotEmpty == true ? item!.schoolYear : '2024/2025',
    );

    String selectedMajor = item?.major ?? 'RPL';
    String selectedGrade = item?.grade ?? 'X';
    String selectedStatus = item?.status ?? 'Aktif';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(item == null ? 'Tambah Kurikulum' : 'Edit Kurikulum'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FormField(
                        controller: subjectController,
                        label: 'Mata Pelajaran',
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: codeController,
                        label: 'Kode',
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _SimpleDropdown(
                        label: 'Jurusan',
                        value: selectedMajor,
                        items: const ['RPL', 'TKJ', 'DKV', 'AKL', 'IPA', 'IPS'],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedMajor = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _SimpleDropdown(
                        label: 'Kelas',
                        value: selectedGrade,
                        items: const ['X', 'XI', 'XII'],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedGrade = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: teacherController,
                        label: 'Guru Pengampu',
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _SimpleDropdown(
                        label: 'Status',
                        value: selectedStatus,
                        items: const ['Aktif', 'Nonaktif'],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => selectedStatus = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: schoolYearController,
                        label: 'Tahun Ajaran',
                        validator: _requiredValidator,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.of(dialogContext).pop(true);
                },
                child: Text(item == null ? 'Simpan' : 'Update'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true) return;

    final payload = CurriculumRecord(
      id: item?.id ?? 0,
      subject: subjectController.text.trim(),
      code: codeController.text.trim().toUpperCase(),
      major: selectedMajor,
      grade: selectedGrade,
      teacher: teacherController.text.trim(),
      status: selectedStatus,
      schoolYear: schoolYearController.text.trim(),
    );

    try {
      if (item == null) {
        final created = await _api.createCurriculum(payload);
        if (!mounted) return;
        setState(() {
          _curriculums.insert(0, created);
          _normalizeFilters();
          _currentPage = 1;
        });
      } else {
        final updated = await _api.updateCurriculum(payload);
        if (!mounted) return;
        final index = _curriculums.indexWhere((record) => record.id == updated.id);
        setState(() {
          if (index != -1) {
            _curriculums[index] = updated;
          }
          _normalizeFilters();
        });
      }
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Simpan Gagal', '$error');
    }
  }

  Future<void> _confirmDelete(CurriculumRecord item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Kurikulum'),
        content: Text('Hapus data ${item.subject} (${item.code})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94F64),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteCurriculum(item.id);
      if (!mounted) return;
      setState(() {
        _curriculums.removeWhere((record) => record.id == item.id);
        _normalizeFilters();
        if (_currentPage > _totalPages) {
          _currentPage = _totalPages;
        }
      });
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Hapus Gagal', '$error');
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field wajib diisi';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1100;
    final mobile = width < 700;
    final filtered = _filteredCurriculums;
    final paged = _pagedCurriculums;
    final start = filtered.isEmpty ? 0 : ((_currentPage - 1) * _pageSize) + 1;
    final end = filtered.isEmpty ? 0 : start + paged.length - 1;

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
                              'Kelola Kurikulum',
                              style: TextStyle(
                                color: Color(0xFF1B2B68),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kelola data mata pelajaran, jurusan, kelas, dan guru pengampu',
                              style: TextStyle(
                                color: Color(0xFF6F7FA8),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showCurriculumForm(),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Tambah Kurikulum'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF345DF4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
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
                                children: const [
                                  Text(
                                    'Kelola Kurikulum',
                                    style: TextStyle(
                                      color: Color(0xFF1B2B68),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Kelola data mata pelajaran, jurusan, kelas, dan guru pengampu',
                                    style: TextStyle(
                                      color: Color(0xFF6F7FA8),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showCurriculumForm(),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text('Tambah Kurikulum'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF345DF4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _StatCard(
                        width: compact ? double.infinity : 338,
                        title: 'Total Mata Pelajaran',
                        value: '$_totalSubjects',
                        note: 'Semua mapel terdaftar',
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        iconBackground: const Color(0xFFF2EAFF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 338,
                        title: 'Total Jurusan',
                        value: '$_totalMajors',
                        note: 'Semua jurusan',
                        icon: Icons.groups_rounded,
                        iconColor: const Color(0xFF1DB56B),
                        iconBackground: const Color(0xFFE9FAF0),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 338,
                        title: 'Total Kelas',
                        value: '$_totalClasses',
                        note: 'Semua kombinasi kelas aktif',
                        icon: Icons.cast_for_education_rounded,
                        iconColor: const Color(0xFFF28A1B),
                        iconBackground: const Color(0xFFFFF1E1),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 338,
                        title: 'Tahun Ajaran',
                        value: '$_totalSchoolYears',
                        note: 'Semua periode terdaftar',
                        icon: Icons.verified_rounded,
                        iconColor: const Color(0xFF19B66A),
                        iconBackground: const Color(0xFFE7F8EE),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE9EEF9)),
                    ),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 14,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: compact ? double.infinity : 360,
                          child: _SearchField(controller: _searchController),
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 220,
                          child: _FilterDropdown(
                            value: _draftSelectedMajor,
                            items: _majorOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _draftSelectedMajor = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 210,
                          child: _FilterDropdown(
                            value: _draftSelectedGrade,
                            items: _gradeOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _draftSelectedGrade = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 210,
                          child: _FilterDropdown(
                            value: _draftSelectedStatus,
                            items: _statusOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _draftSelectedStatus = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 220,
                          child: _FilterDropdown(
                            value: _draftSelectedSchoolYear,
                            items: _schoolYearOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _draftSelectedSchoolYear = value;
                              });
                            },
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3E4D79),
                            side: const BorderSide(color: Color(0xFFD9E2F5)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(Icons.filter_alt_outlined, size: 20),
                          label: const Text('Filter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF345DF4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE9EEF9)),
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 56),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _errorText != null
                            ? _LoadErrorState(
                                message: _errorText!,
                                onRetry: _loadCurriculums,
                              )
                            : filtered.isEmpty
                                ? const _EmptyState()
                                : Column(
                                    children: [
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingRowHeight: 58,
                                          dataRowMinHeight: 68,
                                          dataRowMaxHeight: 74,
                                          horizontalMargin: 22,
                                          columnSpacing: 42,
                                          headingTextStyle: const TextStyle(
                                            color: Color(0xFF233770),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          dataTextStyle: const TextStyle(
                                            color: Color(0xFF213261),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          columns: const [
                                            DataColumn(label: Text('No')),
                                            DataColumn(label: Text('Mata Pelajaran')),
                                            DataColumn(label: Text('Kode')),
                                            DataColumn(label: Text('Jurusan')),
                                            DataColumn(label: Text('Kelas')),
                                            DataColumn(label: Text('Tahun Ajaran')),
                                            DataColumn(label: Text('Guru Pengampu')),
                                            DataColumn(label: Text('Status')),
                                            DataColumn(label: Text('Aksi')),
                                          ],
                                          rows: List.generate(
                                            paged.length,
                                            (index) {
                                              final item = paged[index];
                                              return DataRow(
                                                cells: [
                                                  DataCell(Text('${start + index}')),
                                                  DataCell(Text(item.subject)),
                                                  DataCell(Text(item.code)),
                                                  DataCell(Text(item.major)),
                                                  DataCell(Text(item.grade)),
                                                  DataCell(Text(item.schoolYear)),
                                                  DataCell(Text(item.teacher)),
                                                  DataCell(_StatusBadge(status: item.status)),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        _ActionIconButton(
                                                          icon: Icons.edit_outlined,
                                                          color: const Color(0xFF4569F4),
                                                          background: const Color(0xFFF0F4FF),
                                                          onTap: () => _showCurriculumForm(
                                                            item: item,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        _ActionIconButton(
                                                          icon: Icons.delete_outline_rounded,
                                                          color: const Color(0xFFE94F64),
                                                          background: const Color(0xFFFFEEF1),
                                                          onTap: () => _confirmDelete(item),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                                        child: Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          runSpacing: 14,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              'Menampilkan $start - $end dari ${filtered.length} data',
                                              style: const TextStyle(
                                                color: Color(0xFF7080A8),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Wrap(
                                              spacing: 10,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                _PaginationArrow(
                                                  icon: Icons.chevron_left_rounded,
                                                  enabled: _currentPage > 1,
                                                  onTap: () => _goToPage(_currentPage - 1),
                                                ),
                                                ...List.generate(
                                                  _totalPages,
                                                  (index) => _PaginationNumber(
                                                    label: '${index + 1}',
                                                    active: _currentPage == index + 1,
                                                    onTap: () => _goToPage(index + 1),
                                                  ),
                                                ),
                                                _PaginationArrow(
                                                  icon: Icons.chevron_right_rounded,
                                                  enabled: _currentPage < _totalPages,
                                                  onTap: () => _goToPage(_currentPage + 1),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: KesiswaanBottomNavBar(
          currentIndex: 2,
          onTap: _openBottomNav,
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
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 26,
            compact ? 18 : 20,
            compact ? 18 : 24,
            compact ? 18 : 20,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E61F3), Color(0xFF2138C9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: onBackTap,
                            borderRadius: BorderRadius.circular(14),
                            child: const SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                            ),
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
                    const SizedBox(height: 16),
                    const Text(
                      'Kelola Kurikulum',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manajemen kurikulum kesiswaan',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFDDE5FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onBackTap,
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Kurikulum',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manajemen kurikulum kesiswaan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFDDE5FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(18),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEF9)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF57668E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1B2B68),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note,
                  style: const TextStyle(
                    color: Color(0xFF8694B8),
                    fontSize: 14,
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari mata pelajaran...',
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

class _SimpleDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SimpleDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      onChanged: onChanged,
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
      items: items
          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(growable: false),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == 'Aktif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8FAEF) : const Color(0xFFFFEDF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1DB56B) : const Color(0xFFE94F64),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: active ? const Color(0xFF1EA75E) : const Color(0xFFE94F64),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _PaginationArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationArrow({
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

class _PaginationNumber extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PaginationNumber({
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
            Icon(Icons.menu_book_rounded, size: 42, color: Color(0xFF91A0C7)),
            SizedBox(height: 10),
            Text(
              'Data kurikulum tidak ditemukan',
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
