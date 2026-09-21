import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/buat_jurnal_page.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

class JurnalDetailPage extends StatefulWidget {
  final JournalEntry entry;

  const JurnalDetailPage({super.key, required this.entry});

  @override
  State<JurnalDetailPage> createState() => _JurnalDetailPageState();
}

class _JurnalDetailPageState extends State<JurnalDetailPage> {
  int _currentTab = 5;
  late JournalEntry _entry;
  final LmsApiService _api = LmsApiService();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
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
    if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AbsensiPage()),
      );
      return;
    }
    if (index == 5) {
      Navigator.of(context).pop(_entry);
      return;
    }

    setState(() {
      _currentTab = index;
    });
  }

  Future<void> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_entry);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  Future<void> _openEditJurnal() async {
    final result = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute(
        builder: (_) => BuatJurnalPage(initialEntry: _entry),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _entry = result;
    });
  }

  Future<void> _deleteJurnal() async {
    if (_deleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jurnal'),
        content: const Text('Yakin ingin menghapus jurnal ini?'),
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
      if (_entry.id != null) {
        await _api.deleteJournal(_entry.id!);
      }
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus jurnal: $e',
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
    final entry = _entry;

    final content = Column(
      children: [
        _Hero(onBack: _handleBack),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _TopCard(
                  entry: entry,
                  onEdit: _openEditJurnal,
                  onDelete: _deleteJurnal,
                  deleting: _deleting,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _SectionCard(
                  title: 'Materi Pembelajaran',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.learningPoints
                        .map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 7),
                                  child: Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: Color(0xFF4A72F4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: const TextStyle(
                                      color: Color(0xFF2D354B),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _SectionCard(
                  title: 'Ringkasan Materi dan Catatan',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...entry.summaryParagraphs.map(
                        (paragraph) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            paragraph,
                            style: const TextStyle(
                              color: Color(0xFF3F4861),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Progress Pembelajaran',
                        style: TextStyle(
                          color: Color(0xFF33405C),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                entry.progressNote,
                                style: const TextStyle(
                                  color: Color(0xFF5C6786),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 116,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: entry.imageBytes == null
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFEAF0FF), Color(0xFFD6E0FF)],
                                    )
                                  : null,
                              image: entry.imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(entry.imageBytes!),
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                    )
                                  : null,
                            ),
                            child: entry.imageBytes == null
                                ? const _MiniGraph()
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _TaskCard(entry: entry),
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

class _Hero extends StatelessWidget {
  final Future<void> Function() onBack;

  const _Hero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 182,
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
              child: _Bubble(size: 170, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -35,
              top: 35,
              child: _Bubble(size: 150, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _CurveClipper(),
                    child: Container(
                      height: 84,
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
                              borderRadius: BorderRadius.circular(20),
                              onTap: onBack,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Jurnal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Catatan kegiatan pembelajaran',
                          style: TextStyle(
                            color: Color(0xFFC7D2FF),
                            fontSize: 13,
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

class _TopCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool deleting;

  const _TopCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.deleting,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10253D89),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: entry.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.library_books_rounded,
                  color: entry.accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3559E0),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1C2437),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          compact
              ? Column(
                  children: [
                    _MetaChip(label: 'Kelas: ${entry.className}'),
                    const SizedBox(height: 10),
                    _MetaChip(label: 'Tanggal: ${entry.dateLabel}'),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _MetaChip(label: 'Kelas: ${entry.className}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetaChip(label: 'Tanggal: ${entry.dateLabel}'),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          size: 18,
                          color: Color(0xFF1FB973),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Hadir: ${entry.attendanceCount} siswa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF3E4760),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: TextButton.icon(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1EEFF),
                          foregroundColor: const Color(0xFF4052E8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Edit',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: TextButton.icon(
                        onPressed: deleting ? null : onDelete,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEFF1),
                          foregroundColor: const Color(0xFFD74B5A),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: deleting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline_rounded, size: 15),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            deleting ? 'Menghapus' : 'Hapus',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 18,
                      color: Color(0xFF1FB973),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hadir: ${entry.attendanceCount} siswa',
                      style: const TextStyle(
                        color: Color(0xFF3E4760),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 34,
                      child: TextButton.icon(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1EEFF),
                          foregroundColor: const Color(0xFF4052E8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 34,
                      child: TextButton.icon(
                        onPressed: deleting ? null : onDelete,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEFF1),
                          foregroundColor: const Color(0xFFD74B5A),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: deleting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline_rounded, size: 15),
                        label: Text(
                          deleting ? 'Menghapus' : 'Hapus',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF42506D),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10253D89),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF28314A),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final JournalEntry entry;

  const _TaskCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10253D89),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Color(0xFF4561EC),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tugas Hari Ini',
                  style: TextStyle(
                    color: Color(0xFF2D3960),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.taskTitle,
                  style: const TextStyle(
                    color: Color(0xFF2E3447),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Deadline: ${entry.taskDeadline}',
                  style: const TextStyle(
                    color: Color(0xFF7B839A),
                    fontSize: 13,
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

class _MiniGraph extends StatelessWidget {
  const _MiniGraph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniGraphPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MiniGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFB7C6F6)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF4D73F5)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFF4D73F5);

    for (var i = 1; i < 4; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 8), Offset(dx, size.height - 8), gridPaint);
      canvas.drawLine(Offset(8, dy), Offset(size.width - 8, dy), gridPaint);
    }

    final path = Path()
      ..moveTo(14, size.height - 18)
      ..lineTo(size.width * .48, size.height * .42)
      ..lineTo(size.width - 16, 18);
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(Offset(size.width * .48, size.height * .42), 4.2, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;

  const _Bubble({required this.size, required this.color});

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

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 42);
    path.quadraticBezierTo(size.width * 0.22, 20, size.width * 0.55, 48);
    path.quadraticBezierTo(size.width * 0.82, 74, size.width, 28);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
