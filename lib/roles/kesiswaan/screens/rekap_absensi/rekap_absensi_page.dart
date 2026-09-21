import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/models/attendance_record.dart';
import 'package:lms_guru/roles/kesiswaan/screens/auth/login_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kelola_menu_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_jurnal/kelola_jurnal_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/users/kelola_user_page.dart';
import 'package:lms_guru/roles/kesiswaan/services/lms_api_service.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';

class RekapAbsensiPage extends StatefulWidget {
  const RekapAbsensiPage({super.key});

  @override
  State<RekapAbsensiPage> createState() => _RekapAbsensiPageState();
}

class _RekapAbsensiPageState extends State<RekapAbsensiPage> {
  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<AttendanceRecord> _records = [];

  bool _isLoading = false;
  String? _errorText;
  String _selectedClass = 'Semua Kelas';
  String _selectedMonth = 'Semua Bulan';

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _searchController.addListener(_handleSearchChanged);
    _loadAttendance();
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
    ..._records
        .map((item) => item.className.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<String> get _monthOptions => [
    'Semua Bulan',
    ..._records
        .map((item) => item.monthLabel.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<AttendanceRecord> get _filteredRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _records.where((item) {
      final matchesQuery = query.isEmpty ||
          item.studentName.toLowerCase().contains(query) ||
          item.className.toLowerCase().contains(query) ||
          item.monthLabel.toLowerCase().contains(query);
      final matchesClass =
          _selectedClass == 'Semua Kelas' || item.className == _selectedClass;
      final matchesMonth =
          _selectedMonth == 'Semua Bulan' || item.monthLabel == _selectedMonth;
      return matchesQuery && matchesClass && matchesMonth;
    }).toList(growable: false);
  }

  int get _totalStudents => _filteredRecords.length;
  int get _totalPresent =>
      _filteredRecords.fold(0, (sum, item) => sum + item.presentDays);
  int get _totalIzin =>
      _filteredRecords.fold(0, (sum, item) => sum + item.izinDays);
  int get _totalAlfa =>
      _filteredRecords.fold(0, (sum, item) => sum + item.alfaDays);
  double get _avgPresentRate {
    if (_filteredRecords.isEmpty) return 0;
    final totalRate = _filteredRecords.fold<double>(
      0,
      (sum, item) => sum + _attendanceRate(item),
    );
    return totalRate / _filteredRecords.length;
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await _api.getAttendance();
      if (!mounted) return;
      setState(() {
        _records
          ..clear()
          ..addAll(items);
        if (!_classOptions.contains(_selectedClass)) {
          _selectedClass = 'Semua Kelas';
        }
        if (!_monthOptions.contains(_selectedMonth)) {
          _selectedMonth = 'Semua Bulan';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = '$error');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double _attendanceRate(AttendanceRecord item) {
    final total = item.presentDays + item.izinDays + item.alfaDays;
    if (total <= 0) return 0;
    return (item.presentDays / total) * 100;
  }

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KesiswaanDashboardPage()),
    );
  }

  void _openJurnal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KelolaJurnalPage()),
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
    if (index == 3) return;
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
    if (index == 1) {
      _openJurnal();
      return;
    }
    if (index == 4) {
      _openProfile();
      return;
    }
  }

  Future<void> _showDetail(AttendanceRecord item) {
    final total = item.presentDays + item.izinDays + item.alfaDays;
    final rate = _attendanceRate(item);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Detail Rekap Absensi'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLine('Nama Siswa', item.studentName),
              _detailLine('Kelas', item.className),
              _detailLine('Periode', item.monthLabel),
              _detailLine('Hadir', '${item.presentDays} hari'),
              _detailLine('Izin', '${item.izinDays} hari'),
              _detailLine('Alfa', '${item.alfaDays} hari'),
              _detailLine('Total Hari Tercatat', '$total hari'),
              _detailLine('Persentase Kehadiran', '${rate.toStringAsFixed(1)}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;
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
                              'Rekap Absensi',
                              style: TextStyle(
                                color: Color(0xFF1A2A61),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pantau rekap kehadiran siswa berdasarkan kelas, bulan, dan tren ketidakhadiran.',
                              style: TextStyle(
                                color: Color(0xFF7D89AA),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loadAttendance,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF345DF4),
                                  side: const BorderSide(color: Color(0xFFDCE5F7)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Muat Ulang'),
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
                                    'Rekap Absensi',
                                    style: TextStyle(
                                      color: Color(0xFF1A2A61),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Pantau rekap kehadiran siswa berdasarkan kelas, bulan, dan tren ketidakhadiran.',
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
                            OutlinedButton.icon(
                              onPressed: _loadAttendance,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF345DF4),
                                side: const BorderSide(color: Color(0xFFDCE5F7)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Muat Ulang'),
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
                        value: '$_totalStudents',
                        note: 'Siswa sesuai filter',
                        icon: Icons.groups_rounded,
                        iconColor: const Color(0xFF3366F3),
                        iconBackground: const Color(0xFFEAF0FF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Total Hadir',
                        value: '$_totalPresent',
                        note: 'Akumulasi kehadiran',
                        icon: Icons.check_circle_rounded,
                        iconColor: const Color(0xFF1DB56B),
                        iconBackground: const Color(0xFFEAF8EF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Izin + Alfa',
                        value: '${_totalIzin + _totalAlfa}',
                        note: 'Butuh perhatian',
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFF28A1B),
                        iconBackground: const Color(0xFFFFF3E6),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Rata-rata Hadir',
                        value: '${_avgPresentRate.toStringAsFixed(1)}%',
                        note: 'Persentase kehadiran',
                        icon: Icons.query_stats_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        iconBackground: const Color(0xFFF1EAFF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8ECF7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: compact ? double.infinity : 320,
                              child: _SearchField(controller: _searchController),
                            ),
                            SizedBox(
                              width: compact ? double.infinity : 220,
                              child: _FilterDropdown(
                                value: _selectedClass,
                                items: _classOptions,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedClass = value);
                                },
                              ),
                            ),
                            SizedBox(
                              width: compact ? double.infinity : 220,
                              child: _FilterDropdown(
                                value: _selectedMonth,
                                items: _monthOptions,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedMonth = value);
                                },
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedClass = 'Semua Kelas';
                                  _selectedMonth = 'Semua Bulan';
                                });
                              },
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 56),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorText != null)
                          _LoadErrorState(message: _errorText!, onRetry: _loadAttendance)
                        else if (filtered.isEmpty)
                          const _EmptyState()
                        else
                          _AttendanceTable(
                            items: filtered,
                            onView: _showDetail,
                            attendanceRate: _attendanceRate,
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
            currentIndex: 3,
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
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 20,
            compact ? 18 : 18,
            compact ? 18 : 20,
            compact ? 18 : 18,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Rekap Absensi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Monitoring kehadiran siswa kesiswaan',
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
                            'Rekap Absensi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Monitoring kehadiran siswa kesiswaan',
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
        hintText: 'Cari nama siswa, kelas, atau bulan...',
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

class _AttendanceTable extends StatelessWidget {
  final List<AttendanceRecord> items;
  final ValueChanged<AttendanceRecord> onView;
  final double Function(AttendanceRecord item) attendanceRate;

  const _AttendanceTable({
    required this.items,
    required this.onView,
    required this.attendanceRate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFF)),
        columns: const [
          DataColumn(label: Text('No')),
          DataColumn(label: Text('Siswa')),
          DataColumn(label: Text('Kelas')),
          DataColumn(label: Text('Bulan')),
          DataColumn(label: Text('Hadir')),
          DataColumn(label: Text('Izin')),
          DataColumn(label: Text('Alfa')),
          DataColumn(label: Text('Persentase')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          final rate = attendanceRate(item);
          return DataRow(
            cells: [
              DataCell(Text('$index')),
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
              DataCell(Text(item.monthLabel)),
              DataCell(Text('${item.presentDays}')),
              DataCell(Text('${item.izinDays}')),
              DataCell(Text('${item.alfaDays}')),
              DataCell(_RateBadge(rate: rate)),
              DataCell(
                _MiniAction(
                  icon: Icons.visibility_outlined,
                  onTap: () => onView(item),
                ),
              ),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _RateBadge extends StatelessWidget {
  final double rate;

  const _RateBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color color;
    if (rate >= 90) {
      bg = const Color(0xFFEAF8EF);
      color = const Color(0xFF1DB56B);
    } else if (rate >= 75) {
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
        '${rate.toStringAsFixed(1)}%',
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
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.onTap,
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
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF2E61F3),
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
            Icon(Icons.fact_check_rounded, size: 42, color: Color(0xFF91A0C7)),
            SizedBox(height: 10),
            Text(
              'Data absensi tidak ditemukan',
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
