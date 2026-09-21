import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/models/journal_entry.dart';
import 'package:lms_guru/roles/kesiswaan/screens/auth/login_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kelola_menu_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/rekap_absensi/rekap_absensi_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/users/kelola_user_page.dart';
import 'package:lms_guru/roles/kesiswaan/services/lms_api_service.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';

class KelolaJurnalPage extends StatefulWidget {
  const KelolaJurnalPage({super.key});

  @override
  State<KelolaJurnalPage> createState() => _KelolaJurnalPageState();
}

class _KelolaJurnalPageState extends State<KelolaJurnalPage> {
  static const int _pageSize = 6;

  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<JournalEntry> _journals = [];

  String _selectedSubject = 'Semua Mapel';
  String _selectedClass = 'Semua Kelas';
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
      setState(() => _currentPage = 1);
    });
    _loadJournals();
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

  List<String> get _subjectOptions => [
    'Semua Mapel',
    ..._journals
        .map((item) => item.subject.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<String> get _classOptions => [
    'Semua Kelas',
    ..._journals
        .map((item) => item.className.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  Future<void> _loadJournals() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await _api.getJournals();
      if (!mounted) return;
      setState(() {
        _journals
          ..clear()
          ..addAll(items);
        _currentPage = 1;
        _normalizeFilters();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = '$error');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _normalizeFilters() {
    if (!_subjectOptions.contains(_selectedSubject)) {
      _selectedSubject = 'Semua Mapel';
    }
    if (!_classOptions.contains(_selectedClass)) {
      _selectedClass = 'Semua Kelas';
    }
  }

  List<JournalEntry> get _filteredJournals {
    final query = _searchController.text.trim().toLowerCase();
    return _journals.where((item) {
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subject.toLowerCase().contains(query) ||
          item.className.toLowerCase().contains(query) ||
          item.dateLabel.toLowerCase().contains(query) ||
          item.materialSummary.toLowerCase().contains(query);
      final matchesSubject =
          _selectedSubject == 'Semua Mapel' || item.subject == _selectedSubject;
      final matchesClass =
          _selectedClass == 'Semua Kelas' || item.className == _selectedClass;
      return matchesQuery && matchesSubject && matchesClass;
    }).toList(growable: false);
  }

  List<JournalEntry> get _pagedJournals {
    final filtered = _filteredJournals;
    if (filtered.isEmpty) return const [];
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages {
    final total = (_filteredJournals.length / _pageSize).ceil();
    return total <= 0 ? 1 : total;
  }

  int get _totalSubjects => _journals
      .map((item) => item.subject.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .length;

  int get _totalClasses => _journals
      .map((item) => item.className.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .length;

  int get _avgAttendance => _journals.isEmpty
      ? 0
      : (_journals.fold<int>(0, (sum, item) => sum + item.attendanceCount) ~/
          _journals.length);

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
    if (index == 1) return;
    if (index == 0) {
      _openDashboard();
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KelolaMenuPage()),
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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedSubject = 'Semua Mapel';
      _selectedClass = 'Semua Kelas';
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

  Future<void> _showJournalForm({JournalEntry? item}) async {
    final result = await showDialog<JournalEntry>(
      context: context,
      builder: (context) => _JournalFormDialog(item: item),
    );

    if (result == null) return;

    try {
      if (item == null) {
        final created = await _api.createJournal(result);
        if (!mounted) return;
        setState(() => _journals.insert(0, created));
      } else {
        final updated = await _api.updateJournal(result);
        if (!mounted) return;
        final index = _journals.indexWhere((entry) => entry.id == updated.id);
        setState(() {
          if (index != -1) {
            _journals[index] = updated;
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Simpan Gagal', '$error');
    }
  }

  Future<void> _showJournalDetail(JournalEntry item) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(item.title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine('Tanggal', item.dateLabel),
                _detailLine('Mata Pelajaran', item.subject),
                _detailLine('Kelas', item.className),
                _detailLine('Kehadiran', '${item.attendanceCount} siswa'),
                _detailLine('Ringkasan', item.materialSummary),
                if (item.progressNote.trim().isNotEmpty)
                  _detailLine('Progress', item.progressNote),
                if (item.taskTitle.trim().isNotEmpty)
                  _detailLine('Tugas', item.taskTitle),
                if (item.taskDeadline.trim().isNotEmpty)
                  _detailLine('Deadline', item.taskDeadline),
              ],
            ),
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

  Future<void> _confirmDelete(JournalEntry item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Jurnal'),
        content: Text('Hapus jurnal "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84D67),
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
      if (item.id == null) throw Exception('ID jurnal kosong');
      await _api.deleteJournal(item.id!);
      if (!mounted) return;
      setState(() {
        _journals.removeWhere((entry) => entry.id == item.id);
      });
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Hapus Gagal', '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredJournals;
    final paged = _pagedJournals;
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1120;
    final mobile = width < 700;
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
                              'Kelola Jurnal',
                              style: TextStyle(
                                color: Color(0xFF1A2A61),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kelola jurnal pembelajaran guru, rekap kehadiran, dan tindak lanjut kelas.',
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
                                onPressed: () => _showJournalForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E61F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Tambah Jurnal'),
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
                                    'Kelola Jurnal',
                                    style: TextStyle(
                                      color: Color(0xFF1A2A61),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Kelola jurnal pembelajaran guru, rekap kehadiran, dan tindak lanjut kelas.',
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
                              onPressed: () => _showJournalForm(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E61F3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tambah Jurnal'),
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
                        title: 'Total Jurnal',
                        value: '${_journals.length}',
                        note: 'Semua jurnal terdaftar',
                        icon: Icons.library_books_rounded,
                        iconColor: const Color(0xFF3366F3),
                        iconBackground: const Color(0xFFEAF0FF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Mata Pelajaran',
                        value: '$_totalSubjects',
                        note: 'Mapel aktif terdata',
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFF1DB56B),
                        iconBackground: const Color(0xFFEAF8EF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Total Kelas',
                        value: '$_totalClasses',
                        note: 'Kelas dalam jurnal',
                        icon: Icons.cast_for_education_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        iconBackground: const Color(0xFFF1EAFF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Rata-rata Hadir',
                        value: '$_avgAttendance',
                        note: 'Per entri jurnal',
                        icon: Icons.fact_check_rounded,
                        iconColor: const Color(0xFFF28A1B),
                        iconBackground: const Color(0xFFFFF3E6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                          width: compact ? double.infinity : 240,
                          child: _FilterDropdown(
                            value: _selectedSubject,
                            items: _subjectOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedSubject = value;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 220,
                          child: _FilterDropdown(
                            value: _selectedClass,
                            items: _classOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedClass = value;
                                _currentPage = 1;
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
                                onRetry: _loadJournals,
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
                                          dataRowMaxHeight: 76,
                                          horizontalMargin: 22,
                                          columnSpacing: 32,
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
                                            DataColumn(label: Text('Tanggal')),
                                            DataColumn(label: Text('Mata Pelajaran')),
                                            DataColumn(label: Text('Judul')),
                                            DataColumn(label: Text('Kelas')),
                                            DataColumn(label: Text('Hadir')),
                                            DataColumn(label: Text('Tugas')),
                                            DataColumn(label: Text('Aksi')),
                                          ],
                                          rows: List.generate(
                                            paged.length,
                                            (index) {
                                              final item = paged[index];
                                              return DataRow(
                                                cells: [
                                                  DataCell(Text('${start + index}')),
                                                  DataCell(Text(item.dateLabel)),
                                                  DataCell(Text(item.subject)),
                                                  DataCell(
                                                    SizedBox(
                                                      width: 220,
                                                      child: Text(
                                                        item.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(Text(item.className)),
                                                  DataCell(Text('${item.attendanceCount}')),
                                                  DataCell(
                                                    SizedBox(
                                                      width: 180,
                                                      child: Text(
                                                        item.taskTitle.trim().isEmpty
                                                            ? '-'
                                                            : item.taskTitle,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        _ActionIconButton(
                                                          icon: Icons.visibility_outlined,
                                                          color: const Color(0xFF1DB56B),
                                                          background: const Color(0xFFEAF8EF),
                                                          onTap: () => _showJournalDetail(item),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        _ActionIconButton(
                                                          icon: Icons.edit_outlined,
                                                          color: const Color(0xFF4569F4),
                                                          background: const Color(0xFFF0F4FF),
                                                          onTap: () => _showJournalForm(item: item),
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
            currentIndex: 1,
            onTap: _openBottomNav,
          ),
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
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
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 20,
            vertical: compact ? 16 : 18,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E61F3), Color(0xFF2B45D7)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: compact
              ? Column(
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
                      'Kelola Jurnal',
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
                      'Manajemen jurnal pembelajaran kesiswaan',
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
                            'Kelola Jurnal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manajemen jurnal pembelajaran kesiswaan',
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
        hintText: 'Cari judul, mapel, kelas, atau tanggal...',
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
          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(growable: false),
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
            Icon(Icons.library_books_rounded, size: 42, color: Color(0xFF91A0C7)),
            SizedBox(height: 10),
            Text(
              'Data jurnal tidak ditemukan',
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

class _JournalFormDialog extends StatefulWidget {
  final JournalEntry? item;

  const _JournalFormDialog({this.item});

  @override
  State<_JournalFormDialog> createState() => _JournalFormDialogState();
}

class _JournalFormDialogState extends State<_JournalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _subjectController;
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _classController;
  late final TextEditingController _attendanceController;
  late final TextEditingController _progressController;
  late final TextEditingController _taskController;
  late final TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.item?.dateLabel ?? '');
    _subjectController = TextEditingController(text: widget.item?.subject ?? '');
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _summaryController = TextEditingController(text: widget.item?.materialSummary ?? '');
    _classController = TextEditingController(text: widget.item?.className ?? '');
    _attendanceController = TextEditingController(
      text: widget.item != null ? '${widget.item!.attendanceCount}' : '0',
    );
    _progressController = TextEditingController(text: widget.item?.progressNote ?? '');
    _taskController = TextEditingController(text: widget.item?.taskTitle ?? '');
    _deadlineController = TextEditingController(text: widget.item?.taskDeadline ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _subjectController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _classController.dispose();
    _attendanceController.dispose();
    _progressController.dispose();
    _taskController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.item == null ? 'Tambah Jurnal' : 'Edit Jurnal'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(controller: _dateController, label: 'Tanggal'),
                const SizedBox(height: 12),
                _FormField(controller: _subjectController, label: 'Mata Pelajaran'),
                const SizedBox(height: 12),
                _FormField(controller: _titleController, label: 'Judul Jurnal'),
                const SizedBox(height: 12),
                _FormField(
                  controller: _summaryController,
                  label: 'Ringkasan Materi',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _FormField(controller: _classController, label: 'Kelas'),
                const SizedBox(height: 12),
                _FormField(
                  controller: _attendanceController,
                  label: 'Jumlah Kehadiran',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: _progressController,
                  label: 'Catatan Progress',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _FormField(controller: _taskController, label: 'Tugas'),
                const SizedBox(height: 12),
                _FormField(controller: _deadlineController, label: 'Deadline Tugas'),
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
      JournalEntry(
        id: widget.item?.id,
        dateLabel: _dateController.text.trim(),
        subject: _subjectController.text.trim(),
        title: _titleController.text.trim(),
        materialSummary: _summaryController.text.trim(),
        className: _classController.text.trim(),
        attendanceCount: int.tryParse(_attendanceController.text.trim()) ?? 0,
        accentColor: widget.item?.accentColor ?? const Color(0xFF4D7CFF),
        learningPoints: widget.item?.learningPoints ?? const [],
        summaryParagraphs: widget.item?.summaryParagraphs ?? const [],
        progressTitle: widget.item?.progressTitle ?? 'Progress Pembelajaran',
        progressNote: _progressController.text.trim(),
        taskTitle: _taskController.text.trim(),
        taskDeadline: _deadlineController.text.trim(),
        imageBytes: widget.item?.imageBytes,
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
        if ((label == 'Catatan Progress' || label == 'Tugas' || label == 'Deadline Tugas') &&
            (value == null || value.trim().isEmpty)) {
          return null;
        }
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
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
