import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class TugasDetailPage extends StatefulWidget {
  final TugasItem item;

  const TugasDetailPage({super.key, required this.item});

  @override
  State<TugasDetailPage> createState() => _TugasDetailPageState();
}

class _TugasDetailPageState extends State<TugasDetailPage> {
  late TugasItem _item;
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  bool _deleting = false;
  final List<_StudentSubmission> _students = [];
  bool _loadingStudents = true;
  String? _studentsError;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadStudentRoster();
  }

  int get _gradedCount => _students.where((student) => student.submitted).length;

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

  Future<void> _openEditTugas() async {
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
            'Pengingat berhasil dikirim.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFDCE3F4)),
          ),
        ),
      );
  }

  Future<void> _downloadAttachment() async {
    if (!_item.hasAttachment) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'File tugas belum tersedia untuk diunduh.',
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

  void _showAllStudentsSheet() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Siswa Backend (${_students.length})',
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
        );
      },
    );
  }

  Future<void> _openAnswersPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _JawabanDetailPage(
          item: _item,
          students: _students,
          onDownloadTaskAttachment: _downloadAttachment,
        ),
      ),
    );
  }

  Future<void> _deleteTugas() async {
    if (_item.id == null || _deleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Yakin ingin menghapus tugas ini?'),
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
              'Gagal menghapus tugas: $e',
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

  @override
  Widget build(BuildContext context) {
    final bool isWebLayout = kIsWeb;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          title: _item.title,
          onBack: () => Navigator.of(context).pop(_item),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Spacer(),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _openEditTugas,
                icon: const Icon(Icons.edit, size: 14),
                label: const Text(
                  'Edit Tugas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1D2),
                  foregroundColor: const Color(0xFF6B5700),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoCard(
          date: _item.date,
          statusText: _loadingStudents
              ? 'Memuat siswa dan nilai backend...'
              : _studentsError != null
              ? 'Gagal membaca nilai backend.'
              : _gradedCount > 0
              ? '$_gradedCount siswa sudah memiliki nilai backend.'
              : 'Belum ada nilai backend untuk mapel ini.',
          attachmentName: _item.attachmentName,
          hasAttachment: _item.hasAttachment,
          onDownload: _downloadAttachment,
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Deskripsi Tugas',
          icon: Icons.assignment,
          text: _item.description.isEmpty
              ? 'Belum ada deskripsi tugas.'
              : _item.description,
        ),
        const SizedBox(height: 10),
        _SubmissionCard(
          students: _students,
          onTapTotal: _showAllStudentsSheet,
          onOpenAnswers: _openAnswersPage,
          loading: _loadingStudents,
          errorText: _studentsError,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A69FF), Color(0xFF2E4DE8)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: ElevatedButton(
              onPressed: _showReminderSentNotice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Kirim Pengingat Tugas',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: _deleting ? null : _deleteTugas,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD83A3A),
              side: const BorderSide(color: Color(0xFFE7D8D8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Text(
              _deleting ? 'Menghapus...' : 'Hapus Tugas',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: isWebLayout
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: content,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _DetailHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 170,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B3BFF), Color(0xFF2028D2)],
                ),
              ),
            ),
            const Positioned(
              left: -52,
              top: -36,
              child: _HeaderBubble(size: 170, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -48,
              top: 18,
              child: _HeaderBubble(size: 155, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(
                      height: 82,
                      color: const Color(0xFFF3F5FB),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(20),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Detail Tugas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE0E8FF),
                            fontSize: 16,
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

class _InfoCard extends StatelessWidget {
  final String date;
  final String statusText;
  final String attachmentName;
  final bool hasAttachment;
  final VoidCallback onDownload;

  const _InfoCard({
    required this.date,
    required this.statusText,
    required this.attachmentName,
    required this.hasAttachment,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E7F3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, color: Color(0xFF2E4DE8), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline: $date',
                      style: const TextStyle(
                        color: Color(0xFF2A3040),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: Color(0xFF6D768F),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: hasAttachment ? onDownload : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDE5FA)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.file_download,
                    color: hasAttachment
                        ? const Color(0xFF2E4DE8)
                        : const Color(0xFFA4B1D9),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      attachmentName.isEmpty
                          ? 'Belum ada file tugas.'
                          : attachmentName,
                      style: TextStyle(
                        color: hasAttachment
                            ? const Color(0xFF2E4DE8)
                            : const Color(0xFF7D87A6),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration:
                            hasAttachment ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                  const Icon(Icons.check, color: Color(0xFFA4B1D9), size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E7F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE7EBF8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2F4DE8), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2A3040),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF353B48),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final List<_StudentSubmission> students;
  final VoidCallback onTapTotal;
  final VoidCallback onOpenAnswers;
  final bool loading;
  final String? errorText;

  const _SubmissionCard({
    required this.students,
    required this.onTapTotal,
    required this.onOpenAnswers,
    required this.loading,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final previewStudents = students.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E7F3)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE7EBF8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups, color: Color(0xFF2F4DE8), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Daftar Siswa',
                    style: TextStyle(
                      color: Color(0xFF2A3040),
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onTapTotal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E4DE8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${students.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorText != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Roster backend belum bisa dimuat.\n$errorText',
                style: const TextStyle(
                  color: Color(0xFF6D768F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...previewStudents.map(
              (student) => _StudentRow(
                initials: student.initials,
                name: student.name,
                submitted: student.submitted,
                color: student.color,
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenAnswers,
              child: const Text(
                'Pantau Nilai',
                style: TextStyle(
                  color: Color(0xFF2E4DE8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _StudentRow extends StatelessWidget {
  final String initials;
  final String name;
  final bool submitted;
  final Color color;

  const _StudentRow({
    required this.initials,
    required this.name,
    required this.submitted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF5E657A),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF2A3040),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: submitted
                  ? const Color(0xFFDCF3E2)
                  : const Color(0xFFF1F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              submitted ? 'Sudah ternilai' : 'Belum ternilai',
              style: TextStyle(
                color: submitted
                    ? const Color(0xFF2F8E4E)
                    : const Color(0xFF7A8299),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JawabanDetailPage extends StatefulWidget {
  final TugasItem item;
  final List<_StudentSubmission> students;
  final Future<void> Function() onDownloadTaskAttachment;

  const _JawabanDetailPage({
    required this.item,
    required this.students,
    required this.onDownloadTaskAttachment,
  });

  @override
  State<_JawabanDetailPage> createState() => _JawabanDetailPageState();
}

class _JawabanDetailPageState extends State<_JawabanDetailPage> {
  int _currentTab = 2;

  int get _submittedCount => widget.students.where((e) => e.submitted).length;
  int get _pendingCount => widget.students.length - _submittedCount;

  List<_AnswerStudentEntry> get _entries => widget.students.take(3).map((student) {
        if (student.submitted) {
          return _AnswerStudentEntry(
            student: student,
            submittedAt: 'Nilai backend tersedia',
            statusLabel: 'Sudah ternilai',
            noteLabel: 'Siap dipantau dari data nilai',
            statusColor: const Color(0xFF2F8E4E),
            statusBackground: const Color(0xFFDCF3E2),
            noteColor: const Color(0xFF2F8E4E),
            fileName: '-',
            fileSize: '',
            canOpen: false,
          );
        }
        return _AnswerStudentEntry(
          student: student,
          submittedAt: 'Nilai backend belum tersedia',
          statusLabel: 'Belum ternilai',
          noteLabel: 'Menunggu data nilai backend',
          statusColor: const Color(0xFFB7791F),
          statusBackground: const Color(0xFFFFF3D6),
          noteColor: const Color(0xFF7181A6),
          fileName: '-',
          fileSize: '',
          canOpen: false,
        );
      }).toList(growable: false);

  void _openAnswer(_AnswerStudentEntry entry) {
    if (!entry.canOpen) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Jawaban ${entry.student.name}'),
        content: Text(
          'File ${entry.fileName} siap ditinjau.\n\nFitur isi jawaban siswa belum dihubungkan ke backend terpisah.',
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

  void _sendReminder() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Pengingat tugas berhasil dikirim.',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      Navigator.of(context).maybePop();
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
    final compact = width < 1120;

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
                  _AnswersHeroHeader(
                    subtitle: widget.item.title,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 18),
                  _AnswersTopCard(
                    item: widget.item,
                    statusLabel: _pendingCount > 0
                        ? 'Belum ternilai'
                        : 'Sudah ternilai',
                    onDownloadTaskAttachment: widget.onDownloadTaskAttachment,
                  ),
                  const SizedBox(height: 18),
                  if (compact)
                    Column(
                      children: [
                        _AnswersListPanel(
                          entries: _entries,
                          totalStudents: widget.students.length,
                          onOpenAnswer: _openAnswer,
                        ),
                        const SizedBox(height: 16),
                        _AnswersSummaryPanel(
                          total: widget.students.length,
                          submitted: _submittedCount,
                          pending: _pendingCount,
                          subject: widget.item.subject,
                          topic: widget.item.title,
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _AnswersListPanel(
                            entries: _entries,
                            totalStudents: widget.students.length,
                            onOpenAnswer: _openAnswer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _AnswersSummaryPanel(
                            total: widget.students.length,
                            submitted: _submittedCount,
                            pending: _pendingCount,
                            subject: widget.item.subject,
                            topic: widget.item.title,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendReminder,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Kirim Pengingat Tugas'),
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
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Hapus Tugas'),
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

class _AnswersHeroHeader extends StatelessWidget {
  final String subtitle;
  final VoidCallback onBack;

  const _AnswersHeroHeader({
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 170,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2F61F4), Color(0xFF1450E6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: 180,
              top: 18,
              child: Icon(
                Icons.assignment_rounded,
                color: Color(0x18FFFFFF),
                size: 90,
              ),
            ),
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Lihat Jawaban',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE5EDFF),
                            fontSize: 15,
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

class _AnswersTopCard extends StatelessWidget {
  final TugasItem item;
  final String statusLabel;
  final Future<void> Function() onDownloadTaskAttachment;

  const _AnswersTopCard({
    required this.item,
    required this.statusLabel,
    required this.onDownloadTaskAttachment,
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TopMeta(
                  icon: Icons.event_note_rounded,
                  title: 'Deadline',
                  value: item.date,
                  note: statusLabel,
                  accent: const Color(0xFF2E61F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TopMeta(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Status',
                  value: statusLabel,
                  note: '',
                  accent: const Color(0xFF2E61F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _TopMeta(
                  icon: Icons.description_outlined,
                  title: 'Keterangan',
                  value: item.description.isEmpty
                      ? 'Kerjakan tugas sesuai instruksi.'
                      : item.description,
                  note: '',
                  accent: const Color(0xFF2E61F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6ECF8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 46,
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
                  child: Text(
                    item.attachmentName.isEmpty ? 'Belum ada file tugas.' : item.attachmentName,
                    style: const TextStyle(
                      color: Color(0xFF2D3F6F),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  '215 KB',
                  style: TextStyle(
                    color: Color(0xFF7181A6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                OutlinedButton.icon(
                  onPressed: item.hasAttachment ? onDownloadTaskAttachment : null,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Unduh File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E61F3),
                    side: const BorderSide(color: Color(0xFFD9E3FB)),
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

class _TopMeta extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String note;
  final Color accent;

  const _TopMeta({
    required this.icon,
    required this.title,
    required this.value,
    required this.note,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF2FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accent, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6D80A7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E3161),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswersListPanel extends StatelessWidget {
  final List<_AnswerStudentEntry> entries;
  final int totalStudents;
  final ValueChanged<_AnswerStudentEntry> onOpenAnswer;

  const _AnswersListPanel({
    required this.entries,
    required this.totalStudents,
    required this.onOpenAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 900;

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
          Text(
            'Daftar Penilaian Siswa ($totalStudents Siswa)',
            style: const TextStyle(
              color: Color(0xFF1E3161),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => _AnswerEntryCard(
              entry: entry,
              compact: compact,
              onOpenAnswer: onOpenAnswer,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF6FAFF), Color(0xFFEFF5FF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD7E3FB)),
            ),
            child: const Text(
                'Status siswa dibaca dari data nilai backend pada mapel yang sama. Detail file jawaban belum tersedia dari server.',
              style: TextStyle(
                color: Color(0xFF56709B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerEntryCard extends StatelessWidget {
  final _AnswerStudentEntry entry;
  final bool compact;
  final ValueChanged<_AnswerStudentEntry> onOpenAnswer;

  const _AnswerEntryCard({
    required this.entry,
    required this.compact,
    required this.onOpenAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: entry.student.color,
          child: Text(
            entry.student.initials,
            style: const TextStyle(
              color: Color(0xFF5E657A),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.student.name,
                style: const TextStyle(
                  color: Color(0xFF20356B),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.submittedAt,
                style: const TextStyle(
                  color: Color(0xFF6E80A8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final statusSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: entry.statusBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.statusLabel,
            style: TextStyle(
              color: entry.statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.noteLabel,
          style: TextStyle(
            color: entry.noteColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final fileSection = entry.canOpen
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6ECF8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 44,
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2D3F6F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.fileSize,
                        style: const TextStyle(
                          color: Color(0xFF7A89AB),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const Text(
            '-',
            style: TextStyle(
              color: Color(0xFF7A89AB),
              fontWeight: FontWeight.w700,
            ),
          );

    final actionButton = OutlinedButton.icon(
      onPressed: entry.canOpen ? () => onOpenAnswer(entry) : null,
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('Lihat Status'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2E61F3),
        side: const BorderSide(color: Color(0xFFD9E3FB)),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.canOpen ? const Color(0xFFFDFEFF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.canOpen
              ? const Color(0xFF8FB4FF)
              : const Color(0xFFE6ECF8),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 14),
                statusSection,
                const SizedBox(height: 14),
                fileSection,
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            )
          : Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                SizedBox(width: 220, child: statusSection),
                const SizedBox(width: 12),
                SizedBox(width: 250, child: fileSection),
                const SizedBox(width: 12),
                actionButton,
              ],
            ),
    );
  }
}

class _AnswersSummaryPanel extends StatelessWidget {
  final int total;
  final int submitted;
  final int pending;
  final String subject;
  final String topic;

  const _AnswersSummaryPanel({
    required this.total,
    required this.submitted,
    required this.pending,
    required this.subject,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                'Ringkasan Penilaian',
                style: TextStyle(
                  color: Color(0xFF1E3161),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: total == 0 ? 0 : submitted / total,
                          strokeWidth: 12,
                          backgroundColor: const Color(0xFFEAEFFB),
                          color: const Color(0xFF64D28A),
                        ),
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Color(0xFF1E3161),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Siswa',
                          style: TextStyle(
                            color: Color(0xFF6D80A7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LegendDot(
                          color: Color(0xFF64D28A),
                          label: 'Sudah ternilai',
                          value: '$submitted',
                        ),
                        const _LegendDot(
                          color: Color(0xFFF59E0B),
                          label: 'Data belum tersedia',
                          value: '0',
                        ),
                        _LegendDot(
                          color: Color(0xFF8FB4FF),
                          label: 'Belum ternilai',
                          value: '$pending',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
                'Informasi Tugas',
                style: TextStyle(
                  color: Color(0xFF1E3161),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _MiniInfo(label: 'Mata Pelajaran', value: subject),
              _MiniInfo(label: 'Topik', value: topic),
              const _MiniInfo(label: 'Dibuat oleh', value: 'Bu Rani'),
              const _MiniInfo(label: 'Tanggal dibuat', value: '15 Mei 2026'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6D80A7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E3161),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6D80A7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2D3F6F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerStudentEntry {
  final _StudentSubmission student;
  final String submittedAt;
  final String statusLabel;
  final String noteLabel;
  final Color statusColor;
  final Color statusBackground;
  final Color noteColor;
  final String fileName;
  final String fileSize;
  final bool canOpen;

  const _AnswerStudentEntry({
    required this.student,
    required this.submittedAt,
    required this.statusLabel,
    required this.noteLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.noteColor,
    required this.fileName,
    required this.fileSize,
    required this.canOpen,
  });
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
    path.moveTo(0, 56);
    path.quadraticBezierTo(size.width * 0.32, 22, size.width * 0.65, 44);
    path.quadraticBezierTo(size.width * 0.9, 58, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
