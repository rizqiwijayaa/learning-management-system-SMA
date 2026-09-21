import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_humas/kelola_humas_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_jurnal/kelola_jurnal_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_kesiswaan/kelola_kesiswaan_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_sarpras/kelola_sarpras_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kurikulum/kelola_kurikulum_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/rekap_absensi/rekap_absensi_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/users/kelola_user_page.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';

class KelolaMenuPage extends StatefulWidget {
  const KelolaMenuPage({super.key});

  @override
  State<KelolaMenuPage> createState() => _KelolaMenuPageState();
}

class _KelolaMenuPageState extends State<KelolaMenuPage> {
  final ProfileStore _profileStore = ProfileStore.instance;

  static const _items = <_KelolaMenuItem>[
    _KelolaMenuItem(
      title: 'Kelola User',
      subtitle: 'Kelola akun pengguna dan hak akses.',
      icon: Icons.person_rounded,
      iconColor: Color(0xFF3366F3),
      background: Color(0xFFEAF0FF),
    ),
    _KelolaMenuItem(
      title: 'Kelola Kurikulum',
      subtitle: 'Kelola mapel, kelas, jurusan, dan guru pengampu.',
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF18A860),
      background: Color(0xFFEAF8EF),
    ),
    _KelolaMenuItem(
      title: 'Kelola Kesiswaan',
      subtitle: 'Kelola siswa, mutasi, pelanggaran, dan aktivitas.',
      icon: Icons.gavel_rounded,
      iconColor: Color(0xFF7C4DFF),
      background: Color(0xFFF1EAFF),
    ),
    _KelolaMenuItem(
      title: 'Kelola Sarpras',
      subtitle: 'Kelola sarana dan prasarana sekolah.',
      icon: Icons.inventory_2_rounded,
      iconColor: Color(0xFFF28A1B),
      background: Color(0xFFFFF3E6),
    ),
    _KelolaMenuItem(
      title: 'Kelola Humas',
      subtitle: 'Kelola agenda dan informasi humas.',
      icon: Icons.campaign_rounded,
      iconColor: Color(0xFFE84D67),
      background: Color(0xFFFFEDF1),
    ),
    _KelolaMenuItem(
      title: 'Lihat Rekap Absensi',
      subtitle: 'Pantau rekap kehadiran siswa.',
      icon: Icons.fact_check_rounded,
      iconColor: Color(0xFF17A2A0),
      background: Color(0xFFE8FAF7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
  }

  @override
  void dispose() {
    _profileStore.removeListener(_handleProfileChanged);
    super.dispose();
  }

  void _handleProfileChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String get _name => (_profileStore.profile?.name.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.name.trim()
      : 'Profil Kesiswaan';

  String get _role => (_profileStore.profile?.role.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.role.trim()
      : 'Kesiswaan';

  String get _initial => _name.substring(0, 1).toUpperCase();

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  void _openBottomNav(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KesiswaanDashboardPage()),
      );
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KelolaJurnalPage()),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RekapAbsensiPage()));
      return;
    }
    if (index == 4) {
      _openProfile();
    }
  }

  void _openItem(_KelolaMenuItem item) {
    final Widget page;
    switch (item.title) {
      case 'Kelola User':
        page = const KelolaUserPage();
        break;
      case 'Kelola Kurikulum':
        page = const KelolaKurikulumPage();
        break;
      case 'Kelola Kesiswaan':
        page = const KelolaKesiswaanPage();
        break;
      case 'Kelola Sarpras':
        page = const KelolaSarprasPage();
        break;
      case 'Kelola Humas':
        page = const KelolaHumasPage();
        break;
      case 'Lihat Rekap Absensi':
        page = const RekapAbsensiPage();
        break;
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KelolaHeader(
                    name: _name,
                    role: _role,
                    initial: _initial,
                    avatarBytes: _profileStore.profile?.avatarBytes,
                    onProfileTap: _openProfile,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Kelola',
                    style: TextStyle(
                      color: Color(0xFF1A2A61),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih modul manajemen yang ingin dikelola oleh tim kesiswaan.',
                    style: TextStyle(
                      color: Color(0xFF607094),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: _items
                        .map(
                          (item) => _KelolaCard(
                            item: item,
                            compact: compact,
                            onTap: () => _openItem(item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: KesiswaanBottomNavBar(
            currentIndex: 2,
            onTap: _openBottomNav,
          ),
        ),
      ),
    );
  }
}

class _KelolaHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final Uint8List? avatarBytes;
  final VoidCallback onProfileTap;

  const _KelolaHeader({
    required this.name,
    required this.role,
    required this.initial,
    required this.avatarBytes,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
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
                  child: _HeaderBubble(size: 150, color: Color(0x1EFFFFFF)),
                ),
                const Positioned(
                  right: -60,
                  top: 8,
                  child: _HeaderBubble(size: 165, color: Color(0x10FFFFFF)),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      child: ClipPath(
                        clipper: _HeaderCurveClipper(),
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
                              child: _HeaderIdentity(
                                name: name,
                                role: role,
                                title: 'Kelola',
                                subtitle: 'Pusat modul manajemen kesiswaan',
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: InkWell(
                                onTap: onProfileTap,
                                borderRadius: BorderRadius.circular(32),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFEFF3FF),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: KesiswaanHeaderAvatar(
                                      initial: initial,
                                      avatarBytes: avatarBytes,
                                      radius: 26,
                                      outerColor: Colors.white,
                                      innerColor: const Color(0xFF2953E3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _HeaderIdentity(
                                name: name,
                                role: role,
                                title: 'Kelola',
                                subtitle: 'Pusat modul manajemen kesiswaan',
                                compact: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: onProfileTap,
                              borderRadius: BorderRadius.circular(18),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  KesiswaanHeaderAvatar(
                                    initial: initial,
                                    avatarBytes: avatarBytes,
                                    radius: 18,
                                    outerColor: Colors.white,
                                    innerColor: const Color(0xFF2953E3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderIdentity extends StatelessWidget {
  final String name;
  final String role;
  final String title;
  final String subtitle;
  final bool compact;

  const _HeaderIdentity({
    required this.name,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        SizedBox(height: compact ? 8 : 6),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFDDE5FF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _KelolaCard extends StatelessWidget {
  final _KelolaMenuItem item;
  final bool compact;
  final VoidCallback onTap;

  const _KelolaCard({
    required this.item,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: compact ? double.infinity : 350,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8ECF7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: item.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A2A61),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF607094),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A0BF),
            ),
          ],
        ),
      ),
    );
  }
}

class _KelolaMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _KelolaMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.background,
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
    path.moveTo(0, 52);
    path.quadraticBezierTo(size.width * 0.34, 24, size.width * 0.68, 44);
    path.quadraticBezierTo(size.width * 0.9, 58, size.width, 36);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
