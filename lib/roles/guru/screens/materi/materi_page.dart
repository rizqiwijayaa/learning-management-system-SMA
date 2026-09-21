import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/buat_materi_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_detail_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/services/guru_scoped_data_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';

class MateriPage extends StatefulWidget {
  const MateriPage({super.key});

  @override
  State<MateriPage> createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  int _currentTab = 1;
  final LmsApiService _api = LmsApiService();
  late final GuruScopedDataService _scopedData = GuruScopedDataService(api: _api);
  bool _loading = true;
  String? _errorText;

  final List<MateriItem> _materiItems = [];

  @override
  void initState() {
    super.initState();
    _loadMateri();
  }

  Future<void> _loadMateri() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }
    try {
      final data = await _scopedData.getMateri();
      if (!mounted) return;
      setState(() {
        _materiItems
          ..clear()
          ..addAll(data);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _materiItems
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

  Future<void> _openTambahMateri() async {
    final result = await Navigator.of(context).push<MateriItem>(
      MaterialPageRoute(builder: (_) => const BuatMateriPage()),
    );
    if (result != null && mounted) {
      await _loadMateri();
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const TugasPage()));
      return;
    }
    if (index == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NilaiPage()));
      return;
    }
    if (index == 4) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AbsensiPage()));
      return;
    }
    if (index == 5) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const JurnalPage()));
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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MateriHeader(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Materi: ${_materiItems.length}',
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 24 : 30,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E2433),
                      ),
                    ),
                  ),
                  if (isWebLayout)
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _openTambahMateri,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E4DE8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Tambah Materi',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              if (!isWebLayout) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _AddMateriButton(onTap: _openTambahMateri),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: _LoadErrorCard(
              message: _errorText!,
              onRetry: _loadMateri,
            ),
          )
        else if (_materiItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'Belum ada data materi.',
                style: TextStyle(
                  color: Color(0xFF6B7693),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          ..._materiItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MateriCard(
                item: item,
                onDetail: () async {
                  final updated = await Navigator.of(context).push<dynamic>(
                    MaterialPageRoute(
                      builder: (_) => MateriDetailPage(item: item),
                    ),
                  );
                  if (updated != null && mounted) {
                    await _loadMateri();
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

class _AddMateriButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _AddMateriButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return SizedBox(
      height: 42,
      child: Material(
        color: const Color(0xFF2E4DE8),
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        shadowColor: const Color(0x22253D80),
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
                          Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Tambah Materi',
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
                      Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Tambah Materi',
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
            'Data materi gagal dimuat dari server.',
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

class _MateriHeader extends StatelessWidget {
  const _MateriHeader();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: compact ? 206 : 170,
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
              left: -60,
              top: -36,
              child: _HeaderBubble(size: 180, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -45,
              top: 22,
              child: _HeaderBubble(size: 155, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(
                      height: 78,
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
                        const SizedBox(height: 3),
                        Text(
                          'Materi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 42 : 52,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Daftar materi pembelajaran',
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

class _MateriCard extends StatelessWidget {
  final MateriItem item;
  final VoidCallback onDetail;

  const _MateriCard({required this.item, required this.onDetail});

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
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
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
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Upload: ${item.uploadDate}',
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Upload: ${item.uploadDate}',
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
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

