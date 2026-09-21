import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/attendance_record.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/models/student_grade.dart';
import 'package:lms_guru/roles/guru/models/tugas_item.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';
import 'package:lms_guru/roles/guru/services/guru_scoped_data_service.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';

class GuruDashboardPage extends StatefulWidget {
  const GuruDashboardPage({super.key});

  @override
  State<GuruDashboardPage> createState() => _GuruDashboardPageState();
}

class _GuruDashboardPageState extends State<GuruDashboardPage> {
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  final ProfileStore _profileStore = ProfileStore.instance;

  int _currentTab = 0;
  int _materiCount = 0;
  int _tugasCount = 0;
  int _studentCount = 0;
  int _classCount = 0;
  List<MateriItem> _materiItems = const [];
  List<TugasItem> _tugasItems = const [];
  List<JournalEntry> _journalEntries = const [];
  List<AttendanceRecord> _attendanceRecords = const [];
  List<StudentGrade> _gradeItems = const [];

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _loadDashboard();
  }

  @override
  void dispose() {
    _profileStore.removeListener(_handleProfileChanged);
    super.dispose();
  }

  void _handleProfileChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadDashboard() async {
    try {
      final results = await Future.wait<Object>([
        _scopedData.getMateri(),
        _scopedData.getAssignments('tugas'),
        _scopedData.getStudentCount(),
        _scopedData.getJournals(),
        _scopedData.getAttendance(),
        _scopedData.getGrades(),
      ]);

      if (!mounted) return;

      final materi = List<MateriItem>.from(results[0] as List);
      final tugas = List<TugasItem>.from(results[1] as List);
      final studentCount = results[2] as int;
      final journals = List<JournalEntry>.from(results[3] as List);
      final attendance = List<AttendanceRecord>.from(results[4] as List);
      final grades = List<StudentGrade>.from(results[5] as List);

      final classSet = <String>{
        ...journals
            .map((item) => item.className.trim())
            .where((item) => item.isNotEmpty),
        ...attendance
            .map((item) => item.className.trim())
            .where((item) => item.isNotEmpty),
      };

      setState(() {
        _materiItems = materi;
        _tugasItems = tugas;
        _journalEntries = journals;
        _attendanceRecords = attendance;
        _gradeItems = grades;
        _materiCount = materi.length;
        _tugasCount = tugas.length;
        _studentCount = studentCount;
        _classCount = classSet.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _materiItems = const [];
        _tugasItems = const [];
        _journalEntries = const [];
        _attendanceRecords = const [];
        _gradeItems = const [];
        _materiCount = 0;
        _tugasCount = 0;
        _studentCount = 0;
        _classCount = 0;
      });
    }
  }

  void _openMateriPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MateriPage()));
  }

  void _openTugasPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TugasPage()));
  }

  void _openNilaiPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NilaiPage()));
  }

  void _openJurnalPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const JurnalPage()));
  }

  void _openAbsensiPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AbsensiPage()));
  }

  void _openProfilePage() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfilePage()))
        .then((didSave) async {
          if (didSave == true) {
            await _profileStore.ensureLoaded(force: true);
            if (mounted) {
              setState(() {});
            }
            await _loadDashboard();
          }
        });
  }

  void _onBottomNavTap(int value) {
    if (value == 1) {
      _openMateriPage();
      return;
    }
    if (value == 2) {
      _openTugasPage();
      return;
    }
    if (value == 3) {
      _openNilaiPage();
      return;
    }
    if (value == 4) {
      _openAbsensiPage();
      return;
    }
    if (value == 5) {
      _openJurnalPage();
      return;
    }

    setState(() {
      _currentTab = value;
    });
  }

  void _openAnnouncementsPage() {
    _openJurnalPage();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = !kIsWeb && screenWidth < 760;
    final isTablet = screenWidth >= 760 && screenWidth < 1180;
    final isDesktop = screenWidth >= 1180;
    final profile = _profileStore.profile;
    final latestTasks = _tugasItems.take(3).toList();
    final latestMaterials = _materiItems.take(3).toList();
    final latestJournals = _journalEntries.take(3).toList();
    final passedCount = _gradeItems.where((item) => item.score >= 70).length;
    final remedialCount = _gradeItems.where((item) => item.score < 70).length;
    final highestScore = _gradeItems.isEmpty
        ? 0
        : _gradeItems
              .map((item) => item.score)
              .reduce((value, element) => value > element ? value : element);
    final topStudentName = _gradeItems.isEmpty
        ? 'Belum ada data nilai'
        : _gradeItems
            .firstWhere((item) => item.score == highestScore)
            .studentName;
    final subjectCount = _gradeItems
        .map((item) => item.subject.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .length;
    final totalPresentDays = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.presentDays,
    );
    final totalAbsentDays = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.alfaDays,
    );
    final totalIzinDays = _attendanceRecords.fold<int>(
      0,
      (sum, item) => sum + item.izinDays,
    );
    final totalAttendanceRecords =
        totalPresentDays + totalIzinDays + totalAbsentDays;
    final attendanceRate = totalAttendanceRecords <= 0
        ? 0
        : ((totalPresentDays / totalAttendanceRecords) * 100).round();
    final averageScore = _gradeItems.isEmpty
        ? 0
        : (_gradeItems.fold<int>(0, (sum, item) => sum + item.score) /
                  _gradeItems.length)
              .round();
    final todaySummary = _buildTodaySummary(
      totalPresentDays: totalPresentDays,
      totalAbsentDays: totalAbsentDays,
      totalIzinDays: totalIzinDays,
      journalCount: _journalEntries.length,
      attendanceRate: attendanceRate,
      averageScore: averageScore,
      passedCount: passedCount,
      subjectCount: subjectCount,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GuruHeroCard(
          profileName: profile?.name.trim().isNotEmpty == true
              ? profile!.name
              : 'Profil Guru',
          profileRole: profile?.role ?? 'Guru',
          avatarBytes: profile?.avatarBytes,
          onProfileTap: _openProfilePage,
          compact: isMobile,
          showNotification: !isMobile,
        ),
        SizedBox(height: isMobile ? 16 : 20),
        _TopStatGrid(
          compact: isMobile,
          stats: [
            _TopStatData(
              title: 'Materi',
              value: '$_materiCount',
              subtitle: 'Total Materi',
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF2F61F3),
              iconBackground: const Color(0xFFEAF0FF),
              onTap: _openMateriPage,
            ),
            _TopStatData(
              title: 'Tugas',
              value: '$_tugasCount',
              subtitle: 'Total Tugas',
              icon: Icons.assignment_rounded,
              iconColor: const Color(0xFF18A957),
              iconBackground: const Color(0xFFEAF8EF),
              onTap: _openTugasPage,
            ),
            _TopStatData(
              title: 'Siswa',
              value: '$_studentCount',
              subtitle: 'Total Siswa',
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFFF08A11),
              iconBackground: const Color(0xFFFFF2E6),
              onTap: _openAbsensiPage,
            ),
            _TopStatData(
              title: 'Kelas Diampu',
              value: '$_classCount',
              subtitle: 'Total Kelas',
              icon: Icons.event_available_rounded,
              iconColor: const Color(0xFF8852E8),
              iconBackground: const Color(0xFFF2EBFF),
              onTap: _openJurnalPage,
            ),
          ],
        ),
        if (!isMobile) ...[
          SizedBox(height: isMobile ? 18 : 22),
          const Text(
            'Menu Utama',
            style: TextStyle(
              color: Color(0xFF1A2442),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 14),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            if (isDesktop) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _MenuGrid(
                              compact: false,
                              items: [
                                _MenuItemData(
                                  label: 'Materi',
                                  icon: Icons.menu_book_rounded,
                                  iconColor: const Color(0xFF2F61F3),
                                  iconBackground: const Color(0xFFEAF0FF),
                                  onTap: _openMateriPage,
                                ),
                                _MenuItemData(
                                  label: 'Tugas',
                                  icon: Icons.assignment_rounded,
                                  iconColor: const Color(0xFF18A957),
                                  iconBackground: const Color(0xFFEAF8EF),
                                  onTap: _openTugasPage,
                                ),
                                _MenuItemData(
                                  label: 'Nilai',
                                  icon: Icons.bar_chart_rounded,
                                  iconColor: const Color(0xFF7B4CE1),
                                  iconBackground: const Color(0xFFF1EBFF),
                                  onTap: _openNilaiPage,
                                ),
                                _MenuItemData(
                                  label: 'Absensi',
                                  icon: Icons.calendar_month_rounded,
                                  iconColor: const Color(0xFFF29822),
                                  iconBackground: const Color(0xFFFFF3E3),
                                  onTap: _openAbsensiPage,
                                ),
                                _MenuItemData(
                                  label: 'Jurnal',
                                  icon: Icons.receipt_long_rounded,
                                  iconColor: const Color(0xFF13A9C0),
                                  iconBackground: const Color(0xFFE8FAFD),
                                  onTap: _openJurnalPage,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _DashboardPanel(
                                    compact: false,
                                    title: 'Tugas Terbaru',
                                    actionLabel: 'Lihat semua',
                                    onActionTap: _openTugasPage,
                                    child: _TaskList(
                                      items: latestTasks,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _DashboardPanel(
                                    compact: false,
                                    title: 'Materi Terbaru',
                                    actionLabel: 'Lihat semua',
                                    onActionTap: _openMateriPage,
                                    child: _LatestMateriList(items: latestMaterials),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                              _DashboardPanel(
                                compact: false,
                                title: 'Ringkasan Nilai',
                                actionLabel: 'Lihat semua',
                                onActionTap: _openNilaiPage,
                                child: _GradeSummaryList(
                                  passedCount: passedCount,
                                  remedialCount: remedialCount,
                                  highestScore: highestScore,
                                  topStudentName: topStudentName,
                                  subjectCount: subjectCount,
                                  onFooterTap: _openNilaiPage,
                                ),
                              ),
                            const SizedBox(height: 16),
                            _DashboardPanel(
                              compact: false,
                              title: 'Update Jurnal Terbaru',
                              actionLabel: 'Lihat semua',
                              onActionTap: _openJurnalPage,
                              child: _AnnouncementList(entries: latestJournals),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SummaryStrip(items: todaySummary, compact: false),
                ],
              );
            }

            if (isMobile) {
              return Column(
                children: [
                  _DashboardPanel(
                    compact: true,
                    title: 'Tugas Terbaru',
                    actionLabel: 'Lihat semua',
                    onActionTap: _openTugasPage,
                    child: _TaskList(items: latestTasks),
                  ),
                  const SizedBox(height: 16),
                  _DashboardPanel(
                    compact: true,
                    title: 'Ringkasan Nilai',
                    actionLabel: 'Lihat semua',
                    onActionTap: _openNilaiPage,
                    child: _GradeSummaryList(
                      passedCount: passedCount,
                      remedialCount: remedialCount,
                      highestScore: highestScore,
                      topStudentName: topStudentName,
                      subjectCount: subjectCount,
                      onFooterTap: _openNilaiPage,
                      compact: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DashboardPanel(
                    compact: true,
                    title: 'Materi Terbaru',
                    actionLabel: 'Lihat semua',
                    onActionTap: _openMateriPage,
                    child: _LatestMateriList(items: latestMaterials),
                  ),
                  const SizedBox(height: 16),
                  _DashboardPanel(
                    compact: true,
                    title: 'Update Jurnal Terbaru',
                    actionLabel: 'Lihat semua',
                    onActionTap: _openAnnouncementsPage,
                    child: _AnnouncementList(entries: latestJournals),
                  ),
                  const SizedBox(height: 16),
                  _SummaryStrip(items: todaySummary, compact: true),
                ],
              );
            }

            return Column(
              children: [
                _MenuGrid(
                  compact: false,
                  items: [
                    _MenuItemData(
                      label: 'Materi',
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFF2F61F3),
                      iconBackground: const Color(0xFFEAF0FF),
                      onTap: _openMateriPage,
                    ),
                    _MenuItemData(
                      label: 'Tugas',
                      icon: Icons.assignment_rounded,
                      iconColor: const Color(0xFF18A957),
                      iconBackground: const Color(0xFFEAF8EF),
                      onTap: _openTugasPage,
                    ),
                    _MenuItemData(
                      label: 'Nilai',
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF7B4CE1),
                      iconBackground: const Color(0xFFF1EBFF),
                      onTap: _openNilaiPage,
                    ),
                    _MenuItemData(
                      label: 'Absensi',
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFFF29822),
                      iconBackground: const Color(0xFFFFF3E3),
                      onTap: _openAbsensiPage,
                    ),
                    _MenuItemData(
                      label: 'Jurnal',
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF13A9C0),
                      iconBackground: const Color(0xFFE8FAFD),
                      onTap: _openJurnalPage,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DashboardPanel(
                  compact: isMobile,
                  title: 'Ringkasan Nilai',
                  actionLabel: 'Lihat semua',
                  onActionTap: _openNilaiPage,
                  child: _GradeSummaryList(
                    passedCount: passedCount,
                    remedialCount: remedialCount,
                    highestScore: highestScore,
                    topStudentName: topStudentName,
                    subjectCount: subjectCount,
                    onFooterTap: _openNilaiPage,
                    compact: false,
                  ),
                ),
                const SizedBox(height: 16),
                _DashboardPanel(
                  compact: isMobile,
                  title: 'Tugas Terbaru',
                  actionLabel: 'Lihat semua',
                  onActionTap: _openTugasPage,
                  child: _TaskList(items: latestTasks),
                ),
                const SizedBox(height: 16),
                _DashboardPanel(
                  compact: isMobile,
                  title: 'Materi Terbaru',
                  actionLabel: 'Lihat semua',
                  onActionTap: _openMateriPage,
                  child: _LatestMateriList(items: latestMaterials),
                ),
                const SizedBox(height: 16),
                _SummaryStrip(items: todaySummary, compact: isMobile),
                SizedBox(height: isMobile ? 14 : 16),
                _DashboardPanel(
                  compact: isMobile,
                  title: 'Update Jurnal Terbaru',
                  actionLabel: 'Lihat semua',
                  onActionTap: _openJurnalPage,
                  child: _AnnouncementList(entries: latestJournals),
                ),
              ],
            );
          },
        ),
        SizedBox(height: isMobile ? 12 : 24),
        if (!isMobile)
          GuruBottomNavBar(
            currentIndex: _currentTab,
            onChanged: _onBottomNavTap,
            compact: false,
            includeNilai: true,
          ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: const Color(0xFF2F61F3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : (isTablet ? 16 : 18),
                  vertical: isMobile ? 8 : 10,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? 470 : (isTablet ? 920 : 1380),
                    ),
                    child: content,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GuruBottomNavBar(
                  currentIndex: _currentTab,
                  onChanged: _onBottomNavTap,
                  compact: true,
                  mobile: true,
                  includeNilai: true,
                ),
              ),
            )
          : null,
    );
  }

  List<_SummaryItemData> _buildTodaySummary({
    required int totalPresentDays,
    required int totalAbsentDays,
    required int totalIzinDays,
    required int journalCount,
    required int attendanceRate,
    required int averageScore,
    required int passedCount,
    required int subjectCount,
  }) {
    return [
      _SummaryItemData(
        label: 'Hadir Tercatat',
        value: '$totalPresentDays',
        note: '$attendanceRate%',
        icon: Icons.groups_rounded,
        iconColor: const Color(0xFF1AA85C),
        iconBackground: const Color(0xFFE8F8EF),
      ),
      _SummaryItemData(
        label: 'Izin dan Alfa',
        value: '${totalIzinDays + totalAbsentDays}',
        note: '$totalIzinDays izin',
        icon: Icons.event_busy_rounded,
        iconColor: const Color(0xFFF08A11),
        iconBackground: const Color(0xFFFFF3E4),
      ),
      _SummaryItemData(
        label: 'Entri Jurnal',
        value: '$journalCount',
        note: 'Data backend',
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFF13A9C0),
        iconBackground: const Color(0xFFE8FAFD),
      ),
      _SummaryItemData(
        label: 'Rata-rata Nilai',
        value: '$averageScore',
        note: '$passedCount lulus',
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFF7B4CE1),
        iconBackground: const Color(0xFFF0EAFE),
      ),
      _SummaryItemData(
        label: 'Mapel Aktif',
        value: '$subjectCount',
        note: 'Nilai tercatat',
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF2F61F3),
        iconBackground: const Color(0xFFEAF0FF),
      ),
    ];
  }
}

class _GuruHeroCard extends StatelessWidget {
  final String profileName;
  final String profileRole;
  final Uint8List? avatarBytes;
  final VoidCallback onProfileTap;
  final bool compact;
  final bool showNotification;

  const _GuruHeroCard({
    required this.profileName,
    required this.profileRole,
    required this.avatarBytes,
    required this.onProfileTap,
    required this.compact,
    required this.showNotification,
  });

  @override
  Widget build(BuildContext context) {
    final roleLabel = profileRole.trim().isEmpty ? 'Guru' : profileRole.trim();

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
              child: _BubbleShape(size: 150, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -60,
              top: 8,
              child: _BubbleShape(size: 165, color: Color(0x10FFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeroCurveClipper(),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'Selamat datang,',
                                style: TextStyle(
                                  color: Color(0xFFE3EBFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                profileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: Color(0xFFE3EBFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _MobileProfileAvatar(
                            profileName: profileName,
                            avatarBytes: avatarBytes,
                            onTap: onProfileTap,
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
                                'Selamat datang,',
                                style: TextStyle(
                                  color: Color(0xFFE3EBFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                roleLabel,
                                style: const TextStyle(
                                  color: Color(0xFFE3EBFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showNotification) ...[
                              const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 18),
                            ],
                            _ProfileHeroChip(
                              profileName: profileName,
                              roleLabel: roleLabel,
                              avatarBytes: avatarBytes,
                              onTap: onProfileTap,
                              compact: false,
                            ),
                          ],
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

class _MobileProfileAvatar extends StatelessWidget {
  final String profileName;
  final Uint8List? avatarBytes;
  final VoidCallback onTap;

  const _MobileProfileAvatar({
    required this.profileName,
    required this.avatarBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF4B6CFF),
            backgroundImage: avatarBytes != null
                ? MemoryImage(avatarBytes!)
                : null,
            child: avatarBytes == null
                ? Text(
                    profileName.trim().isEmpty
                        ? 'R'
                        : profileName.trim().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 3,
            bottom: 3,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroChip extends StatelessWidget {
  final String profileName;
  final String roleLabel;
  final Uint8List? avatarBytes;
  final VoidCallback onTap;
  final bool compact;

  const _ProfileHeroChip({
    required this.profileName,
    required this.roleLabel,
    required this.avatarBytes,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: compact ? 20 : 22,
              backgroundColor: const Color(0xFF6F8AFF),
              backgroundImage: avatarBytes != null
                  ? MemoryImage(avatarBytes!)
                  : null,
              child: avatarBytes == null
                  ? Text(
                      profileName.trim().isEmpty
                          ? 'R'
                          : profileName.trim().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 18 : 21,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profileName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel == 'Guru' ? 'Guru Matematika' : roleLabel,
                  style: TextStyle(
                    color: const Color(0xFFD9E3FF),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopStatGrid extends StatelessWidget {
  final List<_TopStatData> stats;
  final bool compact;

  const _TopStatGrid({required this.stats, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 760
            ? 2
            : constraints.maxWidth >= 420
            ? 2
            : 1;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: stats.map((item) {
            final width = crossAxisCount == 4
                ? (constraints.maxWidth - 42) / 4
                : crossAxisCount == 2
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
            return SizedBox(
              width: width,
              child: _TopStatCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TopStatCard extends StatelessWidget {
  final _TopStatData data;

  const _TopStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8ECF6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A19407F),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 34),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1B2440),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.value,
                      style: const TextStyle(
                        color: Color(0xFF1F2D5C),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7783A2),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final List<_MenuItemData> items;
  final bool compact;

  const _MenuGrid({required this.items, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 5
            : constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        final width = columns == 5
            ? (constraints.maxWidth - 56) / 5
            : columns == 3
            ? (constraints.maxWidth - 28) / 3
            : (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: _MenuCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItemData data;

  const _MenuCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0819407F),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 30),
              ),
              const SizedBox(height: 22),
              Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF35415F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8C99BA),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final Widget child;
  final bool compact;

  const _DashboardPanel({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    required this.child,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 14 : 16,
        compact ? 14 : 18,
        compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0819407F),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1B2440),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onActionTap,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Color(0xFF2E5EF4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<TugasItem> items;

  const _TaskList({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SimpleEmptyPanel(
        icon: Icons.assignment_outlined,
        message: 'Belum ada tugas dari backend.',
      );
    }

    return Column(
      children: List.generate(items.take(3).length, (index) {
        final item = items[index];
        final typeLabel = item.type.toLowerCase() == 'ujian' ? 'Ujian' : 'Tugas';

        return Column(
          children: [
            if (index != 0) const Divider(height: 18, color: Color(0xFFF0F2F8)),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF704EF0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E2746),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.subject} • ${item.date}',
                        style: const TextStyle(
                          color: Color(0xFF6F7B99),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: const Color(0xFF6E51F4),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terjadwal',
                      style: const TextStyle(
                        color: Color(0xFF7F89A7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _LatestMateriList extends StatelessWidget {
  final List<MateriItem> items;

  const _LatestMateriList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SimpleEmptyPanel(
        icon: Icons.menu_book_outlined,
        message: 'Belum ada materi dari backend.',
      );
    }

    return Column(
      children: List.generate(items.take(3).length, (index) {
        final item = items[index];
        return Column(
          children: [
            if (index != 0) const Divider(height: 18, color: Color(0xFFF0F2F8)),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF2F61F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E2746),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.subject} • ${item.uploadDate}',
                        style: const TextStyle(
                          color: Color(0xFF6F7B99),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _SimpleEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SimpleEmptyPanel({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8C95BF), size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5E6883),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeSummaryList extends StatelessWidget {
  final int passedCount;
  final int remedialCount;
  final int highestScore;
  final String topStudentName;
  final int subjectCount;
  final VoidCallback onFooterTap;
  final bool compact;

  const _GradeSummaryList({
    required this.passedCount,
    required this.remedialCount,
    required this.highestScore,
    required this.topStudentName,
    required this.subjectCount,
    required this.onFooterTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (passedCount == 0 && remedialCount == 0 && highestScore == 0) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF8C95BF),
                  size: 34,
                ),
                SizedBox(height: 10),
                Text(
                  'Belum ada data nilai dari backend.',
                  style: TextStyle(
                    color: Color(0xFF5E6883),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onFooterTap,
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Buka halaman nilai',
                    style: TextStyle(
                      color: Color(0xFF2E5EF4),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2E5EF4),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _GradeSummaryRow(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF18A957),
          iconBackground: const Color(0xFFEAF8EF),
          label: 'Siswa lulus',
          value: '$passedCount siswa',
          note: 'Sudah mencapai nilai minimum.',
          compact: compact,
        ),
        const Divider(height: 20, color: Color(0xFFF0F2F8)),
        _GradeSummaryRow(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF08A11),
          iconBackground: const Color(0xFFFFF3E4),
          label: 'Perlu remedial',
          value: '$remedialCount siswa',
          note: 'Masih di bawah batas nilai.',
          compact: compact,
        ),
        const Divider(height: 20, color: Color(0xFFF0F2F8)),
        _GradeSummaryRow(
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFF7B4CE1),
          iconBackground: const Color(0xFFF1EBFF),
          label: 'Nilai tertinggi',
          value: highestScore == 0 ? '-' : '$highestScore',
          note: highestScore == 0
              ? 'Belum ada siswa terdata.'
              : '$topStudentName • $subjectCount mapel tercatat',
          compact: compact,
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: onFooterTap,
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Buka halaman nilai',
                  style: TextStyle(
                    color: Color(0xFF2E5EF4),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF2E5EF4),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GradeSummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String note;
  final bool compact;

  const _GradeSummaryRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.note,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF1E2746),
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF33415F),
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7A86A3),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnnouncementList extends StatelessWidget {
  final List<JournalEntry> entries;

  const _AnnouncementList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final items = entries.isNotEmpty
        ? entries.take(3).map((entry) {
            return (
              entry.title,
              '${entry.subject} - ${entry.className}',
              entry.dateLabel,
            );
          }).toList()
        : const [
            (
              'Belum ada jurnal terbaru',
              'Tambahkan jurnal pembelajaran hari ini',
              'Siap diperbarui',
            ),
            (
              'Catatan kelas akan tampil di sini',
              'Ringkasan mapel dan kelas otomatis sinkron',
              'Terhubung ke jurnal',
            ),
          ];

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Column(
          children: [
            if (index != 0) const Divider(height: 20, color: Color(0xFFF0F2F8)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FAFD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.library_books_rounded,
                    color: Color(0xFF13A9C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E2746),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item.$2}  •  ${item.$3}',
                        style: const TextStyle(
                          color: Color(0xFF6F7B99),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<_SummaryItemData> items;
  final bool compact;

  const _SummaryStrip({required this.items, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 14 : 16,
        compact ? 14 : 18,
        compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0819407F),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pembelajaran',
            style: TextStyle(
              color: Color(0xFF1B2440),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 56) / 5
                  : constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 28) / 3
                  : constraints.maxWidth >= 560
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: items.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: _SummaryTile(data: item),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final _SummaryItemData data;

  const _SummaryTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.iconBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(data.icon, color: data.iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: const TextStyle(
                  color: Color(0xFF6F7B99),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: const TextStyle(
                  color: Color(0xFF1B2440),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.note,
                style: const TextStyle(
                  color: Color(0xFF6F7B99),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 24);
    path.quadraticBezierTo(size.width * 0.28, 38, size.width * 0.62, 18);
    path.quadraticBezierTo(size.width * 0.84, 10, size.width, 1);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _BubbleShape extends StatelessWidget {
  final double size;
  final Color color;

  const _BubbleShape({required this.size, required this.color});

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

class _TopStatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const _TopStatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });
}

class _MenuItemData {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });
}

class _SummaryItemData {
  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _SummaryItemData({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}
