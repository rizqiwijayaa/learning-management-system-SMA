import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/student_grade.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/services/guru_scoped_data_service.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

class NilaiPage extends StatefulWidget {
  const NilaiPage({super.key});

  @override
  State<NilaiPage> createState() => _NilaiPageState();
}

class _NilaiPageState extends State<NilaiPage> {
  int _currentTab = 3;
  String _selectedMapel = 'Semua';
  String _selectedKelas = 'Semua';
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  bool _loading = true;
  String? _errorText;

  final List<StudentGrade> _scores = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  List<String> get _subjects {
    final values = _scores.map((item) => item.subject).toSet().toList()..sort();
    return ['Semua', ...values];
  }

  List<String> get _classes {
    final values = _scores.map((item) => item.className).toSet().toList()..sort();
    return ['Semua', ...values];
  }

  List<StudentGrade> get _filteredScores => _scores
      .where(
        (item) =>
            (_selectedMapel == 'Semua' || item.subject == _selectedMapel) &&
            (_selectedKelas == 'Semua' || item.className == _selectedKelas),
      )
      .toList();

  Future<void> _loadGrades() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }
    try {
      final data = await _scopedData.getGrades();
      if (!mounted) return;
      setState(() {
        _scores
          ..clear()
          ..addAll(data);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scores
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

  Future<void> _handleBack() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  Future<void> _openEditScore(StudentGrade item) async {
    await ProfileStore.instance.ensureLoaded();
    final profile = ProfileStore.instance.profile;
    final scoreController = TextEditingController(text: item.score.toString());
    String selectedMapel = item.subject;
    String selectedKelas = item.className;

    final updatedItem = await showDialog<StudentGrade>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text(
                'Edit Nilai Siswa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2740),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF303757),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Nilai',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF70789A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nilai',
                      filled: true,
                      fillColor: const Color(0xFFF7F8FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDDE1F4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDDE1F4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4764F8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Mapel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF70789A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DialogDropdown(
                    value: selectedMapel,
                    items: _subjects,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() {
                        selectedMapel = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Kelas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF70789A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DialogDropdown(
                    value: selectedKelas,
                    items: _classes,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() {
                        selectedKelas = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF70789A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newScore = int.tryParse(scoreController.text.trim());
                    if (newScore == null || newScore < 0 || newScore > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nilai harus berupa angka 0 sampai 100.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop(
                      item.copyWith(
                        teacherId: item.teacherId ?? profile?.id,
                        teacherNip: item.teacherNip.isNotEmpty
                            ? item.teacherNip
                            : (profile?.nip ?? ''),
                        teacherName: item.teacherName.isNotEmpty
                            ? item.teacherName
                            : (profile?.name ?? ''),
                        score: newScore,
                        subject: selectedMapel,
                        className: selectedKelas,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4764F8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    scoreController.dispose();

    if (updatedItem == null) return;

    final index = _scores.indexOf(item);
    if (index == -1) return;

    try {
      final saved = updatedItem.id != null ? await _api.updateGrade(updatedItem) : updatedItem;
      if (!mounted) return;
      setState(() {
        _scores[index] = saved;
        _selectedMapel = saved.subject;
        _selectedKelas = saved.className;
      });
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    final content = Column(
      children: [
        _NilaiHero(onBack: _handleBack),
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
                            label: 'Mapel',
                            value: _selectedMapel,
                            items: _subjects,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedMapel = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _FilterDropdown(
                            label: 'Kelas',
                            value: _selectedKelas,
                            items: _classes,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedKelas = value;
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Mapel',
                              value: _selectedMapel,
                              items: _subjects,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedMapel = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Kelas',
                              value: _selectedKelas,
                              items: _classes,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedKelas = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
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
                            onRetry: _loadGrades,
                          )
                     : _filteredScores.isEmpty
                         ? const _EmptyState()
                         : Column(
                            children: _filteredScores
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _ScoreCard(
                                      item: item,
                                      onEdit: () => _openEditScore(item),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
              ),
              const SizedBox(height: 96),
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
      backgroundColor: const Color(0xFFF7F6FE),
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

class _NilaiHero extends StatelessWidget {
  final Future<void> Function() onBack;

  const _NilaiHero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(34),
        bottomRight: Radius.circular(34),
      ),
      child: SizedBox(
        height: compact ? 244 : 228,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2031E8),
                    Color(0xFF3049F5),
                    Color(0xFF4B6CFF),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: -72,
              top: -52,
              child: _HeaderGlow(size: 214, color: Color(0x22FFFFFF)),
            ),
            const Positioned(
              right: -48,
              top: 10,
              child: _HeaderGlow(size: 194, color: Color(0x18FFFFFF)),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: _HeroWaveLayers(),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(
                      height: 92,
                      color: const Color(0xFFF7F6FE),
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
                                'Nilai',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Daftar nilai siswa',
                          style: TextStyle(
                            color: Color(0xFFF0F3FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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

class _ScoreCard extends StatelessWidget {
  final StudentGrade item;
  final VoidCallback onEdit;

  const _ScoreCard({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final passed = item.score >= 70;
    final compact = MediaQuery.of(context).size.width < 420;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                Text(
                  item.studentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E233A),
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Nilai: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2E344B),
                        ),
                      ),
                      TextSpan(
                        text: '${item.score}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D45D5),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2E344B),
                      ),
                    ),
                    _StatusBadge(passed: passed),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E233A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Nilai: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2E344B),
                              ),
                            ),
                            TextSpan(
                              text: '${item.score}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D45D5),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 8,
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E344B),
                            ),
                          ),
                          _StatusBadge(passed: passed),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F2FF),
                      foregroundColor: const Color(0xFF3151E0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool passed;

  const _StatusBadge({required this.passed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFE2F6EF) : const Color(0xFFFFE1EB),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        passed ? 'Lulus' : 'Tidak Lulus',
        style: TextStyle(
          color: passed ? const Color(0xFF2E8C6A) : const Color(0xFFBA4B70),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EBF8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, size: 42, color: Color(0xFF8C95BF)),
          SizedBox(height: 12),
          Text(
            'Belum ada data nilai untuk filter ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A627D),
            ),
          ),
        ],
      ),
    );
  }
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
            'Data nilai gagal dimuat dari server.',
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

class _DialogDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DialogDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE1F4)),
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
                    item,
                    overflow: TextOverflow.ellipsis,
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

class _HeaderGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _HeaderGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          radius: 0.96,
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
