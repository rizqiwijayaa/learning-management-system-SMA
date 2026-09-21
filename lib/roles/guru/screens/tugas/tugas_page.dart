import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/tugas_item.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/buat_tugas_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_detail_page.dart';
import 'package:lms_guru/roles/guru/screens/tugas/ujian_detail_page.dart';
import 'package:lms_guru/roles/guru/services/guru_scoped_data_service.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

enum _TugasQuickAction { buatTugas, uploadUjian }
enum _TugasSection { tugas, ujian }

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  int _currentTab = 2;
  bool _showQuickActions = false;
  _TugasSection _selectedSection = _TugasSection.tugas;
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  bool _loading = true;
  String? _errorText;

  final List<TugasItem> _tugasItems = [];

  final List<TugasItem> _ujianItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }
    try {
      final tugas = await _scopedData.getAssignments('tugas');
      final ujian = await _scopedData.getAssignments('ujian');
      if (!mounted) return;
      setState(() {
        _tugasItems
          ..clear()
          ..addAll(tugas);
        _ujianItems
          ..clear()
          ..addAll(ujian);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _tugasItems
            ..clear();
          _ujianItems
            ..clear();
          _errorText = '$error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleQuickAction(_TugasQuickAction action) async {
    if (_showQuickActions) {
      setState(() {
        _showQuickActions = false;
      });
    }
    if (action == _TugasQuickAction.buatTugas) {
      final result = await Navigator.of(context).push<TugasItem>(
        MaterialPageRoute(builder: (_) => const BuatTugasPage(mode: 'tugas')),
      );
      if (result != null && mounted) {
        _selectedSection = _TugasSection.tugas;
        await _loadData();
      }
      return;
    }
    final result = await Navigator.of(context).push<TugasItem>(
      MaterialPageRoute(builder: (_) => const BuatTugasPage(mode: 'ujian')),
    );
    if (result != null && mounted) {
      _selectedSection = _TugasSection.ujian;
      await _loadData();
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
    final bool isWebLayout = kIsWeb;
    final compact = MediaQuery.of(context).size.width < 420;
    final activeItems =
        _selectedSection == _TugasSection.tugas ? _tugasItems : _ujianItems;
    final bool isTugas = _selectedSection == _TugasSection.tugas;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TugasHeader(
          isWebLayout: isWebLayout,
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Total Tugas',
                      value: _tugasItems.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'Total Ujian',
                      value: _ujianItems.length.toString(),
                    ),
                  ),
                  if (isWebLayout) const SizedBox(width: 10),
                  if (isWebLayout)
                    PopupMenuButton<_TugasQuickAction>(
                      tooltip: '',
                      onSelected: _handleQuickAction,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _TugasQuickAction.buatTugas,
                          child: _WebMenuItem(
                            icon: Icons.assignment_rounded,
                            label: 'Buat Tugas',
                          ),
                        ),
                        PopupMenuItem(
                          value: _TugasQuickAction.uploadUjian,
                          child: _WebMenuItem(
                            icon: Icons.file_upload,
                            label: 'Upload Ujian',
                          ),
                        ),
                      ],
                      child: SizedBox(
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Tambah Tugas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!isWebLayout) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _AddTaskButton(onSelected: _handleQuickAction),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionSwitcher(
          selected: _selectedSection,
          onChanged: (section) {
            setState(() {
              _selectedSection = section;
            });
          },
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _LoadErrorCard(
              message: _errorText!,
              onRetry: _loadData,
            ),
          )
        else if (activeItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'Belum ada data tugas.',
                style: TextStyle(
                  color: Color(0xFF6B7693),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          ...activeItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TugasCard(
                item: item,
                icon: isTugas ? Icons.assignment_rounded : Icons.fact_check_rounded,
                dateLabel: isTugas ? 'Deadline' : 'Jadwal Ujian',
                onDetail: () async {
                  final result = await Navigator.of(context).push<dynamic>(
                    MaterialPageRoute(
                      builder: (_) => isTugas
                          ? TugasDetailPage(item: item)
                          : UjianDetailPage(item: item),
                    ),
                  );
                  if (result != null && mounted) {
                    await _loadData();
                  }
                },
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: isWebLayout
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: content,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: content,
                  ),
                ),
              ),
      ),
      bottomNavigationBar: isWebLayout
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

class _LoadErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _LoadErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
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
            'Data tugas gagal dimuat dari server.',
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

class _AddTaskButton extends StatelessWidget {
  final ValueChanged<_TugasQuickAction> onSelected;

  const _AddTaskButton({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return PopupMenuButton<_TugasQuickAction>(
      tooltip: '',
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _TugasQuickAction.buatTugas,
          child: _WebMenuItem(
            icon: Icons.assignment_rounded,
            label: 'Buat Tugas',
          ),
        ),
        PopupMenuItem(
          value: _TugasQuickAction.uploadUjian,
          child: _WebMenuItem(
            icon: Icons.file_upload,
            label: 'Upload Ujian',
          ),
        ),
      ],
      child: SizedBox(
        height: 42,
        child: Material(
          color: const Color(0xFF2E4DE8),
          borderRadius: BorderRadius.circular(14),
          elevation: 2,
          shadowColor: const Color(0x22253D80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: compact
                ? const Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Tambah Tugas',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Tambah Tugas',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 23, color: const Color(0xFF2E4DE8)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2433),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TugasHeader extends StatelessWidget {
  final bool isWebLayout;

  const _TugasHeader({required this.isWebLayout});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: compact ? 206 : 176,
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
              left: -56,
              top: -36,
              child: _HeaderBubble(size: 182, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -44,
              top: 22,
              child: _HeaderBubble(size: 155, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(height: 78, color: const Color(0xFFF3F5FB)),
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
                        const SizedBox(height: 2),
                        Text(
                          'Tugas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 42 : 52,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Daftar tugas pembelajaran',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFDCE4FF),
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

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      height: compact ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E7F3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF59617A),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 20 : 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E4DE8),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSwitcher extends StatelessWidget {
  final _TugasSection selected;
  final ValueChanged<_TugasSection> onChanged;

  const _SectionSwitcher({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitchButton(
              active: selected == _TugasSection.tugas,
              label: 'Tugas',
              onTap: () => onChanged(_TugasSection.tugas),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SwitchButton(
              active: selected == _TugasSection.ujian,
              label: 'Ujian',
              onTap: () => onChanged(_TugasSection.ujian),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF2E4DE8) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF6072A7),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _WebMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WebMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF2E4DE8)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2433),
          ),
        ),
      ],
    );
  }
}

class _TugasCard extends StatelessWidget {
  final TugasItem item;
  final IconData icon;
  final String dateLabel;
  final VoidCallback onDetail;

  const _TugasCard({
    required this.item,
    required this.icon,
    required this.dateLabel,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1221336C),
            blurRadius: 8,
            offset: Offset(0, 3),
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
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2E4DE8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 31),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E2433),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mapel: ${item.subject}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF3A3F4B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.type == 'ujian' && item.durationMinutes != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Durasi: ${item.durationMinutes} menit',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF3A3F4B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$dateLabel: ${item.date}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF353B48),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: onDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E4DE8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2E4DE8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 31),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E2433),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mapel: ${item.subject}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3A3F4B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.type == 'ujian' && item.durationMinutes != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Durasi: ${item.durationMinutes} menit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF3A3F4B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$dateLabel: ${item.date}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF353B48),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: onDetail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E4DE8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lihat Detail',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 16),
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
    path.moveTo(0, 54);
    path.quadraticBezierTo(size.width * 0.34, 24, size.width * 0.68, 44);
    path.quadraticBezierTo(size.width * 0.9, 58, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
