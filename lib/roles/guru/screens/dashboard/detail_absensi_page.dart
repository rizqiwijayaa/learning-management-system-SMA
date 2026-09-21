import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/attendance_record.dart';
import 'package:lms_guru/roles/guru/models/daily_attendance_record.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/edit_absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';
import 'package:lms_guru/roles/role_home_page.dart';

class DetailAbsensiPage extends StatefulWidget {
  final AttendanceRecord student;

  const DetailAbsensiPage({super.key, required this.student});

  @override
  State<DetailAbsensiPage> createState() => _DetailAbsensiPageState();
}

class _DetailAbsensiPageState extends State<DetailAbsensiPage> {
  final int _currentTab = 4;
  final LmsApiService _api = LmsApiService();
  late AttendanceRecord _student;
  late String _selectedMonth;
  bool _loading = true;
  bool _saving = false;
  String? _errorText;
  final List<DailyAttendanceRecord> _entries = [];

  static const Map<String, int> _monthMap = {
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };

  List<String> get _months => [_student.monthLabel];

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _selectedMonth = widget.student.monthLabel;
    _loadDailyAttendance();
  }

  int get _presentCount => _student.presentDays;
  int get _izinCount => _student.izinDays;
  int get _alfaCount => _student.alfaDays;

  AttendanceRecord get _updatedStudent => _student;

  Future<void> _loadDailyAttendance() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }
    try {
      final records = await _api.getDailyAttendance(
        attendanceRecordId: _student.id,
        studentName: _student.studentName,
        className: _student.className,
        month: _selectedMonth,
      );
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(records);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _entries.clear();
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
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MateriPage()));
      return;
    }
    if (index == 2) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const TugasPage()));
      return;
    }
    if (index == 3) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const NilaiPage()));
      return;
    }
    if (index == 4) {
      Navigator.of(context).pop(_updatedStudent);
      return;
    }
    if (index == 5) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const JurnalPage()));
      return;
    }
  }

  Future<void> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_updatedStudent);
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AbsensiPage()));
  }

  String _buildDateLabel(int dayOrder, String monthLabel) {
    final match = RegExp(r'^([A-Za-z]+)\s+(\d{4})$').firstMatch(monthLabel.trim());
    if (match == null) {
      return 'Pertemuan $dayOrder';
    }
    final monthName = match.group(1)!;
    final year = match.group(2)!;
    if (dayOrder > _daysInMonth(monthLabel)) {
      return 'Pertemuan $dayOrder - $monthName $year';
    }
    return '$dayOrder $monthName $year';
  }

  int _daysInMonth(String monthLabel) {
    final match = RegExp(r'^([A-Za-z]+)\s+(\d{4})$').firstMatch(monthLabel.trim());
    if (match == null) return math.max(31, _entries.length + 1);
    final month = _monthMap[match.group(1)!.toLowerCase()];
    final year = int.tryParse(match.group(2)!);
    if (month == null || year == null) return math.max(31, _entries.length + 1);
    return DateTime(year, month + 1, 0).day;
  }

  Future<void> _openEditor(DailyAttendanceRecord entry) async {
    final result = await Navigator.of(context).push<DailyAttendanceEditResult>(
      MaterialPageRoute(
        builder: (_) => EditAbsensiPage(student: _student, entry: entry),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      final mutation = result.delete
          ? await _api.deleteDailyAttendance(result.record.id!)
          : result.record.id == null
          ? await _api.createDailyAttendance(result.record)
          : await _api.updateDailyAttendance(result.record);
      if (!mounted) return;

      setState(() {
        _student = mutation.summary;
        if (result.delete) {
          _entries.removeWhere((item) => item.id == result.record.id);
        } else if (mutation.record != null) {
          final next = mutation.record!;
          final index = _entries.indexWhere((item) => item.id == next.id);
          if (index == -1) {
            _entries.add(next);
          } else {
            _entries[index] = next;
          }
          _entries.sort((a, b) => a.dayOrder.compareTo(b.dayOrder));
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.delete
                ? 'Absensi harian berhasil dihapus'
                : 'Absensi harian berhasil disimpan',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan absensi harian: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _handleCreate() async {
    final nextDayOrder = (_entries.isEmpty
            ? 0
            : _entries.map((entry) => entry.dayOrder).reduce(math.max)) +
        1;
    final draft = DailyAttendanceRecord(
      attendanceRecordId: _student.id,
      teacherId: _student.teacherId,
      teacherNip: _student.teacherNip,
      teacherName: _student.teacherName,
      studentName: _student.studentName,
      className: _student.className,
      monthLabel: _selectedMonth,
      dateLabel: _buildDateLabel(nextDayOrder, _selectedMonth),
      dayOrder: nextDayOrder,
      status: DailyAttendanceStatus.hadir,
      note: '',
      accentColor: _student.accentColor,
      initial: _student.initial,
    );
    await _openEditor(draft);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _DetailHero(onBack: _handleBack),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _StudentHeaderCard(student: _student),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _SummaryCard(
                  present: _presentCount,
                  izin: _izinCount,
                  alfa: _alfaCount,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _MonthDropdown(
                  value: _selectedMonth,
                  items: _months,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedMonth = value;
                    });
                    _loadDailyAttendance();
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _ActionToolbar(
                  saving: _saving,
                  onAdd: _handleCreate,
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
                    ? _DetailLoadErrorCard(
                        message: _errorText!,
                        onRetry: _loadDailyAttendance,
                      )
                    : _entries.isEmpty
                    ? _DailyEmptyCard(onAdd: _handleCreate)
                    : Column(
                        children: _entries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _DayCard(
                                  entry: entry,
                                  onEdit: () => _openEditor(entry),
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

class _DetailHero extends StatelessWidget {
  final Future<void> Function() onBack;

  const _DetailHero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: compact ? 206 : 182,
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
                    child: Row(
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
                            'Detail Absensi',
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

class _StudentHeaderCard extends StatelessWidget {
  final AttendanceRecord student;

  const _StudentHeaderCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
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
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2433),
                    fontSize: 17,
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
              ],
            ),
          ),
        ],
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
      child: Row(
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
                  color: const Color(0xFF1F2433),
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
              color: const Color(0xFF1F2433),
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
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 58, color: const Color(0xFFE8EAF5));
  }
}

class _MonthDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _MonthDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
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
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4A63E7),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    'Bulan: $item',
                    style: const TextStyle(
                      color: Color(0xFF1F2740),
                      fontWeight: FontWeight.w600,
                    ),
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

class _ActionToolbar extends StatelessWidget {
  final bool saving;
  final VoidCallback onAdd;

  const _ActionToolbar({
    required this.saving,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: saving ? null : onAdd,
        icon: saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: Text(saving ? 'Menyimpan...' : 'Tambah Absensi Harian'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: const Color(0xFF3151E0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DailyAttendanceRecord entry;
  final VoidCallback onEdit;

  const _DayCard({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.dateLabel,
            style: const TextStyle(
              color: Color(0xFF2B3147),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(entry.status.icon, color: entry.status.color, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.status.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: entry.status.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Edit',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F2FF),
                          foregroundColor: const Color(0xFF3151E0),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(entry.status.icon, color: entry.status.color, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      entry.status.label,
                      style: TextStyle(
                        color: entry.status.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F2FF),
                          foregroundColor: const Color(0xFF3151E0),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.note,
                style: const TextStyle(
                  color: Color(0xFF61708F),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailLoadErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DetailLoadErrorCard({
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
            'Data absensi harian gagal dimuat dari server.',
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

class _DailyEmptyCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _DailyEmptyCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF8)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 34,
            color: Color(0xFF7B87AA),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum ada data absensi harian untuk siswa ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF44506B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Data Harian'),
          ),
        ],
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
