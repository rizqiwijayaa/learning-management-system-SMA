import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/buat_jurnal_page.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_detail_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/services/guru_scoped_data_service.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

class JurnalPage extends StatefulWidget {
  const JurnalPage({super.key});

  @override
  State<JurnalPage> createState() => _JurnalPageState();
}

class _JurnalPageState extends State<JurnalPage> {
  int _currentTab = 5;
  String _selectedClass = 'Semua';
  String _selectedSubject = 'Semua';
  String _selectedDate = 'Semua';
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  bool _loading = true;
  String? _errorText;

  final List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  List<String> get _classes {
    final values = _entries
        .map((entry) => entry.className.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...values];
  }

  List<String> get _subjects {
    final values = _entries
        .map((entry) => entry.subject.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...values];
  }

  List<String> get _dates {
    final values = _entries
        .map((entry) => entry.dateLabel.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...values];
  }

  Future<void> _loadJournals() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }
    try {
      final data = await _scopedData.getJournals();
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(data);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _entries
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

  List<JournalEntry> get _filteredEntries {
    return _entries.where((entry) {
      final classMatches =
          _selectedClass == 'Semua' || entry.className == _selectedClass;
      final subjectMatches =
          _selectedSubject == 'Semua' || entry.subject == _selectedSubject;
      final dateMatches =
          _selectedDate == 'Semua' || entry.dateLabel == _selectedDate;
      return classMatches && subjectMatches && dateMatches;
    }).toList();
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

  Future<void> _openTambahJurnal() async {
    final result = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute(builder: (_) => const BuatJurnalPage()),
    );
    if (result == null || !mounted) return;

    try {
      final created = await _api.createJournal(result);
      if (!mounted) return;
      setState(() {
        _entries.insert(0, created);
        _selectedClass = 'Semua';
        _selectedSubject = 'Semua';
        _selectedDate = 'Semua';
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showEntryDetail(JournalEntry entry) {
    Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => JurnalDetailPage(entry: entry),
      ),
    ).then((result) async {
      if (result == null || !mounted) return;
      if (result == 'deleted') {
        setState(() {
          _entries.remove(entry);
        });
        return;
      }
      if (result is! JournalEntry) return;
      try {
        final saved = result.id != null ? await _api.updateJournal(result) : result;
        if (!mounted) return;
        setState(() {
          final index = _entries.indexWhere((item) => item.id == (saved.id ?? result.id));
          if (index != -1) {
            _entries[index] = saved;
            return;
          }
          final fallbackIndex = _entries.indexOf(entry);
          if (fallbackIndex != -1) {
            _entries[fallbackIndex] = saved;
          }
        });
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    final content = Column(
      children: [
        _JournalHero(
          onBack: _handleBack,
          onAdd: _openTambahJurnal,
        ),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: compact ? Alignment.center : Alignment.centerRight,
                  child: compact
                      ? SizedBox(
                          width: double.infinity,
                          child: _AddJournalButton(onTap: _openTambahJurnal),
                        )
                      : _AddJournalButton(onTap: _openTambahJurnal),
                ),
              ),
              const SizedBox(height: 12),
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
                            label: 'Mapel',
                            value: _selectedSubject,
                            items: _subjects,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedSubject = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _FilterDropdown(
                            label: 'Tanggal',
                            value: _selectedDate,
                            items: _dates,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedDate = value;
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
                              label: 'Mapel',
                              value: _selectedSubject,
                              items: _subjects,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedSubject = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FilterDropdown(
                              label: 'Tanggal',
                              value: _selectedDate,
                              items: _dates,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedDate = value;
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
                 child: _loading
                     ? const Padding(
                         padding: EdgeInsets.symmetric(vertical: 24),
                         child: Center(child: CircularProgressIndicator()),
                       )
                     : _errorText != null
                     ? _LoadErrorCard(
                         message: _errorText!,
                         onRetry: _loadJournals,
                       )
                     : _filteredEntries.isEmpty
                     ? const _EmptyState()
                     : Column(
                        children: _filteredEntries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _JournalCard(
                                  entry: entry,
                                  onDetail: () => _showEntryDetail(entry),
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

class _JournalHero extends StatelessWidget {
  final Future<void> Function() onBack;
  final Future<void> Function() onAdd;

  const _JournalHero({required this.onBack, required this.onAdd});

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
              top: 35,
              child: _HeaderBubble(size: 150, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
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

class _AddJournalButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _AddJournalButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2E4DE8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22253D80),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: compact
                  ? const Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tambah Jurnal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tambah Jurnal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D20307B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B779C),
          ),
          style: const TextStyle(
            color: Color(0xFF24304B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text('$label: $item', overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onDetail;

  const _JournalCard({required this.entry, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
            entry.dateLabel,
            style: const TextStyle(
              color: Color(0xFF475067),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
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
                    const SizedBox(height: 4),
                    Text(
                      'Materi: ${entry.materialSummary}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6F7891),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                                child: TextButton(
                                  onPressed: onDetail,
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1EEFF),
                                    foregroundColor: const Color(0xFF4052E8),
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 16),
                                      ],
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
                                child: TextButton(
                                  onPressed: onDetail,
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1EEFF),
                                    foregroundColor: const Color(0xFF4052E8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
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
            Icons.library_books_outlined,
            size: 36,
            color: Color(0xFF8D9AC4),
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada jurnal untuk filter ini.',
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
            'Data jurnal gagal dimuat dari server.',
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
