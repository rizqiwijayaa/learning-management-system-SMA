import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_guru/roles/guru/models/student_grade.dart';
import 'package:lms_guru/roles/guru/models/student_record.dart';
import 'package:lms_guru/roles/guru/models/tugas_item.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/edit_tugas_page.dart';
import 'package:lms_guru/roles/guru/services/guru_scoped_data_service.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/utils/file_download.dart';

class UjianDetailPage extends StatefulWidget {
  final TugasItem item;

  const UjianDetailPage({super.key, required this.item});

  @override
  State<UjianDetailPage> createState() => _UjianDetailPageState();
}

class _UjianDetailPageState extends State<UjianDetailPage> {
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  late TugasItem _item;
  bool _deleting = false;
  int _selectedTab = 0;
  int _currentTab = 2;
  final List<_StudentSubmission> _students = [];
  bool _loadingStudents = true;
  String? _studentsError;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadStudentRoster();
  }

  int get _submittedCount => _students.where((e) => e.submitted).length;
  int get _pendingCount => _students.length - _submittedCount;

  String get _subjectTitle {
    if (_item.subject.trim().isEmpty) return 'Ujian';
    return 'Ujian ${_item.subject}';
  }

  String get _materialLabel {
    final title = _item.title.trim();
    if (title.isEmpty) return 'Materi Ujian';
    final cleaned = title.replaceFirst(RegExp(r'^Ujian\s+', caseSensitive: false), '');
    return cleaned.isEmpty ? title : cleaned;
  }

  String get _classLabel => 'Siswa aktif';

  Future<void> _loadStudentRoster() async {
    try {
      final results = await Future.wait([
        _scopedData.getStudents(),
        _scopedData.getGrades(),
      ]);
      if (!mounted) return;
      final students = results[0] as List<StudentRecord>;
      final grades = results[1] as List<StudentGrade>;
      final gradedNames = grades
          .where(
            (grade) => grade.subject.trim().toLowerCase() == _item.subject.trim().toLowerCase(),
          )
          .map((grade) => grade.studentName.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
      final activeStudents = students.where((student) {
        final status = student.status.trim().toLowerCase();
        return status.isEmpty || status == 'aktif';
      });

      setState(() {
        _students
          ..clear()
          ..addAll(
            activeStudents.map(
              (student) => _StudentSubmission(
                name: student.name,
                submitted: gradedNames.contains(student.name.trim().toLowerCase()),
                color: _avatarColor(student.name),
              ),
            ),
          );
        _studentsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _students
          ..clear();
        _studentsError = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingStudents = false;
        });
      }
    }
  }

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFFFFE4E4),
      Color(0xFFE4ECFF),
      Color(0xFFECE3FF),
      Color(0xFFE0F4E8),
      Color(0xFFFFECCF),
      Color(0xFFDFF6FF),
      Color(0xFFFFDFEF),
      Color(0xFFD9F4EC),
    ];
    final index = name.trim().isEmpty
        ? 0
        : name.codeUnits.fold(0, (sum, unit) => sum + unit) % palette.length;
    return palette[index];
  }

  Future<void> _downloadAttachment() async {
    if (!_item.hasAttachment) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'File ujian belum tersedia untuk diunduh.',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    try {
      final savedPath = await downloadBase64File(
        fileName: _item.attachmentName,
        base64Data: _item.attachmentData,
        mimeType: _item.attachmentMimeType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Download dimulai untuk ${_item.attachmentName}.'
                  : 'File tersimpan: $savedPath',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Download file gagal: $error',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _openEdit() async {
    final result = await Navigator.of(context).push<TugasItem>(
      MaterialPageRoute(builder: (_) => EditTugasPage(item: _item)),
    );
    if (result != null) {
      setState(() {
        _item = result;
      });
    }
  }

  void _showReminderSentNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Pengingat ujian berhasil dikirim.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFDCE3F4)),
          ),
        ),
      );
  }

  Future<void> _deleteUjian() async {
    if (_item.id == null || _deleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ujian'),
        content: const Text('Yakin ingin menghapus ujian ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD83A3A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() {
      _deleting = true;
    });

    try {
      await _api.deleteAssignment(_item.id!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus ujian: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  void _showAllStudentsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Siswa (${_students.length})',
                style: const TextStyle(
                  color: Color(0xFF1F2738),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _students.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: student.color,
                        child: Text(
                          student.initials,
                          style: const TextStyle(
                            color: Color(0xFF5E657A),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: const TextStyle(
                          color: Color(0xFF2A3040),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        student.submitted ? 'Sudah ternilai' : 'Belum ternilai',
                        style: TextStyle(
                          color: student.submitted
                              ? const Color(0xFF2F8E4E)
                              : const Color(0xFF7A8299),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyLink() async {
    final examLink =
        'https://localhost:50566/ujian/akses/${_item.date.toLowerCase().replaceAll(' ', '')}';
    try {
      await Clipboard.setData(ClipboardData(text: examLink));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Link ujian berhasil disalin.',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyalin link ujian: $error',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NilaiPage()),
      );
      return;
    }
    if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AbsensiPage()),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = !kIsWeb && width < 760;
    final examLink =
        'https://localhost:50566/ujian/akses/${_item.date.toLowerCase().replaceAll(' ', '')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 16 : 12,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroHeader(
                    title: _subjectTitle,
                    subtitle: _item.title,
                    onBack: () => Navigator.of(context).pop(_item),
                    compact: compact,
                  ),
                  const SizedBox(height: 18),
                  _StatRow(
                    duration: _item.durationMinutes ?? 90,
                    total: _students.length,
                    submitted: _submittedCount,
                    pending: _pendingCount,
                    compact: compact,
                  ),
                  const SizedBox(height: 14),
                  _TabSwitcher(
                    selectedIndex: _selectedTab,
                    totalStudents: _students.length,
                    onChanged: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedTab == 0)
                    compact
                        ? Column(
                            children: [
                              _InfoPanel(
                                item: _item,
                                onEdit: _openEdit,
                                onDownload: _downloadAttachment,
                                compact: compact,
                              ),
                              const SizedBox(height: 16),
                              _LinkPanel(
                                examLink: examLink,
                                onCopy: _copyLink,
                              ),
                              const SizedBox(height: 16),
                              _ExtraInfoPanel(
                                subject: _item.subject,
                                material: _materialLabel,
                                className: _classLabel,
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _InfoPanel(
                                  item: _item,
                                  onEdit: _openEdit,
                                  onDownload: _downloadAttachment,
                                  compact: compact,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _LinkPanel(
                                      examLink: examLink,
                                      onCopy: _copyLink,
                                    ),
                                    const SizedBox(height: 16),
                                    _ExtraInfoPanel(
                                      subject: _item.subject,
                                      material: _materialLabel,
                                      className: _classLabel,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                  else
                    _SubmissionPanel(
                      students: _students,
                      onOpenAll: _showAllStudentsDialog,
                    ),
                  const SizedBox(height: 16),
                  compact
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showReminderSentNotice,
                                icon: const Icon(Icons.send_outlined),
                                label: const Text('Kirim Pengingat ke Siswa'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E61F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _deleting ? null : _deleteUjian,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: Text(_deleting ? 'Menghapus...' : 'Hapus Ujian'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE44848),
                                  side: const BorderSide(color: Color(0xFFF1C9C9)),
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showReminderSentNotice,
                                icon: const Icon(Icons.send_outlined),
                                label: const Text('Kirim Pengingat ke Siswa'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E61F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _deleting ? null : _deleteUjian,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: Text(_deleting ? 'Menghapus...' : 'Hapus Ujian'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE44848),
                                  side: const BorderSide(color: Color(0xFFF1C9C9)),
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: kIsWeb
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GuruBottomNavBar(
                  currentIndex: _currentTab,
                  onChanged: _onBottomNavTap,
                  includeNilai: true,
                  compact: true,
                  mobile: true,
                ),
              ),
            ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool compact;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: compact ? 186 : 170,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2F61F4), Color(0xFF1450E6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
              if (!compact) ...const [
                Positioned(
                  right: 180,
                  top: 18,
                  child: Icon(
                    Icons.assignment_rounded,
                    color: Color(0x18FFFFFF),
                    size: 90,
                  ),
                ),
                Positioned(
                  right: 90,
                  top: 40,
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Color(0x18FFFFFF),
                    size: 62,
                  ),
                ),
              ],
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Detail Ujian',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 18 : 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFE5EDFF),
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w600,
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

class _StatRow extends StatelessWidget {
  final int duration;
  final int total;
  final int submitted;
  final int pending;
  final bool compact;

  const _StatRow({
    required this.duration,
    required this.total,
    required this.submitted,
    required this.pending,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.schedule_rounded,
        iconColor: const Color(0xFF2E61F3),
        iconBackground: const Color(0xFFEBF2FF),
        title: 'Durasi',
        value: '$duration menit',
        compact: compact,
      ),
      _StatCard(
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF8B5CF6),
        iconBackground: const Color(0xFFF1EAFE),
        title: 'Total Soal',
        value: '$total',
        compact: compact,
      ),
      _StatCard(
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF22C55E),
        iconBackground: const Color(0xFFE9FAEF),
        title: 'Sudah Ternilai',
        value: '$submitted',
        compact: compact,
      ),
      _StatCard(
        icon: Icons.hourglass_bottom_rounded,
        iconColor: const Color(0xFFF59E0B),
        iconBackground: const Color(0xFFFFF5E6),
        title: 'Belum Ternilai',
        value: '$pending',
        compact: compact,
      ),
    ];
    if (compact) {
      return Column(
        children: List.generate(cards.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == cards.length - 1 ? 0 : 12),
            child: cards[index],
          );
        }),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 48 : 56,
            height: compact ? 48 : 56,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: compact ? 26 : 30),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF64759C),
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: Color(0xFF1E3161),
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w800,
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

class _TabSwitcher extends StatelessWidget {
  final int selectedIndex;
  final int totalStudents;
  final ValueChanged<int> onChanged;

  const _TabSwitcher({
    required this.selectedIndex,
    required this.totalStudents,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Info Ujian', 'Siswa ($totalStudents)'];
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) {
            final active = index == selectedIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    border: active
                        ? const Border(
                            bottom: BorderSide(
                              color: Color(0xFF2E61F3),
                              width: 3,
                            ),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF2E61F3)
                            : const Color(0xFF62749B),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final TugasItem item;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final bool compact;

  const _InfoPanel({
    required this.item,
    required this.onEdit,
    required this.onDownload,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExamMetaCard(
                      date: item.date,
                      duration: item.durationMinutes ?? 90,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Ujian'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E61F3),
                          side: const BorderSide(color: Color(0xFFD9E3FB)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                      child: _ExamMetaCard(
                        date: item.date,
                        duration: item.durationMinutes ?? 90,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Ujian'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E61F3),
                        side: const BorderSide(color: Color(0xFFD9E3FB)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6ECF8)),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.attachmentName.isEmpty
                                      ? 'Belum ada file ujian.'
                                      : item.attachmentName,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF23356B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.hasAttachment
                                      ? 'File soal tersedia'
                                      : 'Tambahkan file pada edit ujian',
                                  style: const TextStyle(
                                    color: Color(0xFF7282A7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: item.hasAttachment ? onDownload : null,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Unduh File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E61F3),
                            side: const BorderSide(color: Color(0xFFD9E3FB)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
              children: [
                Container(
                  width: 42,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.attachmentName.isEmpty
                            ? 'Belum ada file ujian.'
                            : item.attachmentName,
                        style: const TextStyle(
                          color: Color(0xFF23356B),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.hasAttachment ? 'File soal tersedia' : 'Tambahkan file pada edit ujian',
                        style: const TextStyle(
                          color: Color(0xFF7282A7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: item.hasAttachment ? onDownload : null,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Unduh File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E61F3),
                    side: const BorderSide(color: Color(0xFFD9E3FB)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InstructionCard(text: item.description.isEmpty ? 'Belum ada instruksi ujian.' : item.description),
          const SizedBox(height: 18),
          const _NoticeCard(),
        ],
      ),
    );
  }
}

class _ExamMetaCard extends StatelessWidget {
  final String date;
  final int duration;

  const _ExamMetaCard({
    required this.date,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: Color(0xFF2E61F3),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal Ujian',
                  style: TextStyle(
                    color: Color(0xFF6D80A7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF1E3161),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Durasi: $duration menit',
                  style: const TextStyle(
                    color: Color(0xFF6D80A7),
                    fontWeight: FontWeight.w600,
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

class _InstructionCard extends StatelessWidget {
  final String text;

  const _InstructionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8FAEF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFF22C55E),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instruksi Ujian',
                  style: TextStyle(
                    color: Color(0xFF1E3161),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF5D719A),
                    fontSize: 15,
                    height: 1.5,
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6FAFF), Color(0xFFEFF5FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E3FB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2E61F3)),
              SizedBox(width: 8),
              Text(
                'Perhatikan!',
                style: TextStyle(
                  color: Color(0xFF2E61F3),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '• Kerjakan ujian dengan jujur dan mandiri.\n• Pastikan koneksi internet stabil sebelum memulai ujian.',
            style: TextStyle(
              color: Color(0xFF38527D),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkPanel extends StatelessWidget {
  final String examLink;
  final VoidCallback onCopy;

  const _LinkPanel({
    required this.examLink,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final compact = !kIsWeb && MediaQuery.of(context).size.width < 420;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Link Ujian',
            style: TextStyle(
              color: Color(0xFF1E3161),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bagikan link ini kepada siswa untuk mengakses ujian.',
            style: TextStyle(
              color: Color(0xFF6D80A7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          compact
              ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFCFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD8E2F5)),
                      ),
                      child: Text(
                        examLink,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF374F80),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_all_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFBFCFF),
                          foregroundColor: const Color(0xFF2E61F3),
                          side: const BorderSide(color: Color(0xFFD8E2F5)),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFCFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD8E2F5)),
                        ),
                        child: Text(
                          examLink,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF374F80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_all_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFBFCFF),
                        foregroundColor: const Color(0xFF2E61F3),
                        side: const BorderSide(color: Color(0xFFD8E2F5)),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.content_copy_rounded),
              label: const Text('Salin Link'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E61F3),
                side: const BorderSide(color: Color(0xFFD8E2F5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFBF3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBEFD5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF22C55E)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Link aktif\nDibuat pada 20 Mei 2026 10:30',
                    style: TextStyle(
                      color: Color(0xFF2F8E4E),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
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

class _ExtraInfoPanel extends StatelessWidget {
  final String subject;
  final String material;
  final String className;

  const _ExtraInfoPanel({
    required this.subject,
    required this.material,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Tambahan',
            style: TextStyle(
              color: Color(0xFF1E3161),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.menu_book_rounded, label: 'Mata Pelajaran', value: subject),
          _InfoRow(icon: Icons.bookmark_outline_rounded, label: 'Materi', value: material),
          _InfoRow(icon: Icons.groups_2_outlined, label: 'Kelas', value: className),
          const _InfoRow(icon: Icons.person_outline_rounded, label: 'Dibuat Oleh', value: 'Bu Rani'),
          const _InfoRow(icon: Icons.calendar_month_outlined, label: 'Dibuat Pada', value: '20 Mei 2026 10:30'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final compact = !kIsWeb && MediaQuery.of(context).size.width < 420;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: const Color(0xFF2E61F3), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF2D3F6F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF2D3F6F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF2E61F3), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF2D3F6F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2D3F6F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SubmissionPanel extends StatelessWidget {
  final List<_StudentSubmission> students;
  final VoidCallback onOpenAll;

  const _SubmissionPanel({
    required this.students,
    required this.onOpenAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                    'Siswa Terdata',
                style: TextStyle(
                  color: Color(0xFF1E3161),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenAll,
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...students.take(8).map(
            (student) => _StudentRow(student: student),
          ),
        ],
      ),
    );
  }
}

class _StudentSubmission {
  final String name;
  final bool submitted;
  final Color color;

  const _StudentSubmission({
    required this.name,
    required this.submitted,
    required this.color,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _StudentRow extends StatelessWidget {
  final _StudentSubmission student;

  const _StudentRow({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: student.color,
            child: Text(
              student.initials,
              style: const TextStyle(
                color: Color(0xFF5E657A),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.name,
              style: const TextStyle(
                color: Color(0xFF2A3040),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: student.submitted
                  ? const Color(0xFFDCF3E2)
                  : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              student.submitted ? 'Sudah ternilai' : 'Belum ternilai',
              style: TextStyle(
                color: student.submitted
                    ? const Color(0xFF2F8E4E)
                    : const Color(0xFFB7791F),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
