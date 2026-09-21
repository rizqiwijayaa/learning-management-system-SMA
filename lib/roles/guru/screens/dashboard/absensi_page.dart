import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/attendance_record.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/detail_absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/services/guru_scoped_data_service.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  int _currentTab = 4;
  String _selectedClass = 'Semua';
  String _selectedMonth = 'Semua';
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  bool _loading = true;
  String? _errorText;

  final List<AttendanceRecord> _students = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  List<String> get _classes {
    final values = _students
        .map((student) => student.className.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...values];
  }

  List<String> get _months {
    final values = _students
        .map((student) => student.monthLabel.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...values];
  }

  List<AttendanceRecord> get _filteredStudents => _students.where((student) {
    final classMatches =
        _selectedClass == 'Semua' || student.className == _selectedClass;
    final monthMatches =
        _selectedMonth == 'Semua' || student.monthLabel == _selectedMonth;
    return classMatches && monthMatches;
  }).toList();

  int get _totalPresent =>
      _filteredStudents.fold(0, (sum, student) => sum + student.presentDays);
  int get _totalIzin =>
      _filteredStudents.fold(0, (sum, student) => sum + student.izinDays);
  int get _totalAlfa =>
      _filteredStudents.fold(0, (sum, student) => sum + student.alfaDays);

  Future<void> _loadAttendance() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }
    try {
      final data = await _scopedData.getAttendance();
      if (!mounted) return;
      final classes = data
          .map((student) => student.className.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
      final months = data
          .map((student) => student.monthLabel.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
      setState(() {
        _students
          ..clear()
          ..addAll(data);
        _selectedClass =
            classes.contains(_selectedClass) ? _selectedClass : 'Semua';
        _selectedMonth =
            months.contains(_selectedMonth) ? _selectedMonth : 'Semua';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _students
          ..clear();
        _errorText = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MateriPage()),
      );
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TugasPage()),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NilaiPage()),
      );
      return;
    }
    if (index == 5) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const JurnalPage()),
      );
      return;
    }

    setState(() {
      _currentTab = index;
    });
  }

  Future<void> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  Future<void> _openDetail(AttendanceRecord student) async {
    final result = await Navigator.of(context).push<AttendanceRecord>(
      MaterialPageRoute(
        builder: (_) => DetailAbsensiPage(student: student),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      final index = _students.indexWhere((item) => item.id == result.id);
      if (index != -1) {
        _students[index] = result;
        return;
      }

      final fallbackIndex = _students.indexWhere(
        (item) =>
            item.studentName == result.studentName &&
            item.className == result.className &&
            item.monthLabel == result.monthLabel,
      );
      if (fallbackIndex != -1) {
        _students[fallbackIndex] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    final content = Column(
      children: [
        _AbsensiHero(onBack: _handleBack),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: compact
                    ? Column(
                        children: [
                          _FilterDropdown(
                            label: 'Kelas',
                            value: _selectedClass,
                            items: _classes,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedClass = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _FilterDropdown(
                            label: 'Bulan',
                            value: _selectedMonth,
                            items: _months,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedMonth = value;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Kelas',
                              value: _selectedClass,
                              items: _classes,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedClass = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Bulan',
                              value: _selectedMonth,
                              items: _months,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedMonth = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _SummaryCard(
                  present: _totalPresent,
                  izin: _totalIzin,
                  alfa: _totalAlfa,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                 child: _loading
                     ? const Padding(
                         padding: EdgeInsets.symmetric(vertical: 24),
                         child: Center(child: CircularProgressIndicator()),
                       )
                     : _errorText != null
                     ? _LoadErrorCard(
                         message: _errorText!,
                         onRetry: _loadAttendance,
                       )
                     : _filteredStudents.isEmpty
                     ? const _EmptyState()
                     : Column(
                         children: _filteredStudents
                             .map(
                               (student) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AttendanceCard(
                                  student: student,
                                  onDetail: () => _openDetail(student),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 92),
            ],
          ),
        ),
      ],
    );

    final body = kIsWeb
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: content,
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: content,
              ),
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(child: body),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: GuruBottomNavBar(
            currentIndex: _currentTab,
            onChanged: _onBottomNavTap,
            includeNilai: true,
          ),
        ),
      ),
    );
  }
}

class _AbsensiHero extends StatelessWidget {
  final Future<void> Function() onBack;

  const _AbsensiHero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: compact ? 236 : 212,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B3BFF), Color(0xFF2028D2)],
                ),
              ),
            ),
            const Positioned(
              left: -50,
              top: -35,
              child: _HeaderBubble(size: 170, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -35,
              top: 25,
              child: _HeaderBubble(size: 150, color: Color(0x1AFFFFFF)),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: _HeroWaveLayers(),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(
                      height: 88,
                      color: const Color(0xFFF3F5FB),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: onBack,
                              borderRadius: BorderRadius.circular(18),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Absensi',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Riwayat kehadiran siswa',
                          style: TextStyle(
                            color: Color(0xFFE7EBFF),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ProfileAvatarButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE1F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D23357A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4A63E7),
            size: 24,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$label: ',
                          style: const TextStyle(
                            color: Color(0xFF58617C),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: item,
                          style: const TextStyle(
                            color: Color(0xFF1F2740),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int present;
  final int izin;
  final int alfa;

  const _SummaryCard({
    required this.present,
    required this.izin,
    required this.alfa,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08283974),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: compact
          ? Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF2FBE86),
                    label: 'Hadir',
                    value: present,
                  ),
                ),
                const _SummaryDivider(),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.error_rounded,
                    iconColor: const Color(0xFFF5C84B),
                    label: 'Izin',
                    value: izin,
                  ),
                ),
                const _SummaryDivider(),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.cancel_rounded,
                    iconColor: const Color(0xFFE25666),
                    label: 'Alfa',
                    value: alfa,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF2FBE86),
                    label: 'Hadir',
                    value: present,
                  ),
                ),
                const _SummaryDivider(),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.error_rounded,
                    iconColor: const Color(0xFFF5C84B),
                    label: 'Izin',
                    value: izin,
                  ),
                ),
                const _SummaryDivider(),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.cancel_rounded,
                    iconColor: const Color(0xFFE25666),
                    label: 'Alfa',
                    value: alfa,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 16 : 20, color: iconColor),
              SizedBox(width: compact ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF1F2433),
                  fontSize: compact ? 12 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 2 : 6),
          Text(
            '$value',
            style: TextStyle(
              color: Color(0xFF1F2433),
              fontSize: compact ? 16 : 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  final bool vertical;

  const _SummaryDivider() : vertical = false;
  const _SummaryDivider.vertical() : vertical = true;

  @override
  Widget build(BuildContext context) {
    return vertical
        ? Container(
            width: double.infinity,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFE8EAF5),
          )
        : Container(
            width: 1,
            height: 58,
            color: const Color(0xFFE8EAF5),
          );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord student;
  final VoidCallback onDetail;

  const _AttendanceCard({required this.student, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(compact ? 14 : 16, compact ? 14 : 16, compact ? 14 : 16, compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08283974),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: compact ? 20 : 24,
                      backgroundColor: student.accent,
                      child: Text(
                        student.initial,
                        style: TextStyle(
                          color: Color(0xFF3546AF),
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 17 : 20,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.studentName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF1F2433),
                              fontSize: compact ? 16 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kelas: ${student.className}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF70789A),
                              fontSize: compact ? 13 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 10),
                Wrap(
                  spacing: compact ? 8 : 10,
                  runSpacing: compact ? 4 : 6,
                  children: [
                    _CountChip(
                      color: const Color(0xFF2FBE86),
                      icon: Icons.check_circle,
                      value: student.presentDays,
                    ),
                    _CountChip(
                      color: const Color(0xFFF5C84B),
                      icon: Icons.error_rounded,
                      value: student.izinDays,
                    ),
                    _CountChip(
                      color: const Color(0xFFE25666),
                      icon: Icons.cancel_rounded,
                      value: student.alfaDays,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F2FF),
                      foregroundColor: const Color(0xFF3151E0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: student.accent,
                  child: Text(
                    student.initial,
                    style: const TextStyle(
                      color: Color(0xFF3546AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1F2433),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelas: ${student.className}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF70789A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          _CountChip(
                            color: const Color(0xFF2FBE86),
                            icon: Icons.check_circle,
                            value: student.presentDays,
                          ),
                          _CountChip(
                            color: const Color(0xFFF5C84B),
                            icon: Icons.error_rounded,
                            value: student.izinDays,
                          ),
                          _CountChip(
                            color: const Color(0xFFE25666),
                            icon: Icons.cancel_rounded,
                            value: student.alfaDays,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F2FF),
                      foregroundColor: const Color(0xFF3151E0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Detail',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final int value;

  const _CountChip({required this.color, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: compact ? 14 : 16),
        SizedBox(width: compact ? 3 : 4),
        Text(
          '$value',
          style: TextStyle(
            color: Color(0xFF2C334F),
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _HeroWaveLayers extends StatelessWidget {
  const _HeroWaveLayers();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Stack(
        children: [
          Positioned(
            left: -16,
            right: -16,
            bottom: 0,
            child: Container(
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x663E7AFF), Color(0x4D5188FF)],
                ),
                borderRadius: BorderRadius.all(Radius.elliptical(320, 58)),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: Container(
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x4DFFFFFF), Color(0x10FFFFFF)],
                ),
                borderRadius: BorderRadius.all(Radius.elliptical(280, 44)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 52);
    path.quadraticBezierTo(size.width * 0.3, 24, size.width * 0.62, 46);
    path.quadraticBezierTo(size.width * 0.84, 60, size.width, 30);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _LoadErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _LoadErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD7D7)),
      ),
      child: Column(
        children: [
          const Text(
            'Data absensi gagal dimuat dari server.',
            style: TextStyle(
              color: Color(0xFFC53A3A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF925B5B),
              fontWeight: FontWeight.w500,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8F4)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 36,
            color: Color(0xFF8D9AC4),
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada data absensi dari backend.',
            style: TextStyle(
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
