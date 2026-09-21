import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ProfileStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final profile = store.profile;
        final name = profile?.name ?? 'Rizqi';
        final role = profile?.role ?? 'Guru';
        final compact = MediaQuery.of(context).size.width < 420;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: compact ? 188 : 170,
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
                          height: 85,
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
                            const SizedBox(height: 4),
                            const Text(
                              'Selamat datang,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 30 : 36,
                                fontWeight: FontWeight.w700,
                                height: .95,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role,
                              style: const TextStyle(
                                color: Color(0xFFC8D3FF),
                                fontSize: 16,
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
      },
    );
  }
}

class StatsRow extends StatelessWidget {
  final int materiCount;
  final int tugasCount;
  final int studentCount;

  const StatsRow({
    super.key,
    required this.materiCount,
    required this.tugasCount,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              StatCard(title: 'Materi', value: '$materiCount'),
              const SizedBox(height: 10),
              StatCard(title: 'Tugas', value: '$tugasCount'),
              const SizedBox(height: 10),
              StatCard(title: 'Siswa', value: '$studentCount'),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: StatCard(title: 'Materi', value: '$materiCount')),
            const SizedBox(width: 10),
            Expanded(child: StatCard(title: 'Tugas', value: '$tugasCount')),
            const SizedBox(width: 10),
            Expanded(child: StatCard(title: 'Siswa', value: '$studentCount')),
          ],
        );
      },
    );
  }
}

class StatCard extends StatefulWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, required this.value});

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 420;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: narrow ? 84 : 92,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E4BE8), Color(0xFF2B45D6)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1F2A47C8),
              blurRadius: _pressed ? 6 : 10,
              offset: Offset(0, _pressed ? 2 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: const Color(0x22FFFFFF),
            highlightColor: const Color(0x12FFFFFF),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFDDE5FF),
                    fontSize: narrow ? 14 : 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: narrow ? 30 : 38,
                    fontWeight: FontWeight.w700,
                    height: .9,
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

class FeatureCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool fullWidth;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 116,
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4E8F4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF3250E8), size: 34),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1F2433),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuruBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const GuruBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.home_rounded, 'Dashboard'),
      (Icons.menu_book_rounded, 'Materi'),
      (Icons.check_box_rounded, 'Tugas'),
      (Icons.show_chart_rounded, 'Nilai'),
      (Icons.bar_chart_rounded, 'Absensi'),
      (Icons.library_books_rounded, 'Jurnal'),
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F4)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = index == currentIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.$1,
                    size: 22,
                    color: active
                        ? const Color(0xFF2E4DE8)
                        : const Color(0xFF91A0CF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF2E4DE8)
                          : const Color(0xFF91A0CF),
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
