import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class KepsekHero extends StatelessWidget {
  final String name;
  final String nip;
  final Uint8List? avatarBytes;
  final VoidCallback onLogout;
  final VoidCallback onProfileTap;

  const KepsekHero({
    super.key,
    required this.name,
    required this.nip,
    required this.avatarBytes,
    required this.onLogout,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: compact ? 220 : 152,
            child: InkWell(
              onTap: onProfileTap,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2454FF), Color(0xFF1224CE)],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: -42,
                    top: -34,
                    child: _HeroBubble(size: 150, color: Color(0x22FFFFFF)),
                  ),
                  const Positioned(
                    right: -28,
                    top: 18,
                    child: _HeroBubble(size: 138, color: Color(0x16FFFFFF)),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(
                        child: ClipPath(
                          clipper: _HeroCurveClipper(),
                          child: Container(
                            height: compact ? 34 : 44,
                            color: const Color(0xFFF6F8FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                    child: compact
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Selamat datang,',
                                      style: TextStyle(
                                        color: Color(0xFFE3EBFF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Kepala Sekolah',
                                      style: TextStyle(
                                        color: Color(0xFFE3EBFF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _HeroAvatar(avatarBytes: avatarBytes),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selamat datang,',
                                      style: TextStyle(
                                        color: Color(0xFFE3EBFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Kepala Sekolah',
                                      style: TextStyle(
                                        color: Color(0xFFE3EBFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _HeroAvatar(avatarBytes: avatarBytes),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final Uint8List? avatarBytes;
  const _HeroAvatar({required this.avatarBytes});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFEFF3FF),
      child: CircleAvatar(
        radius: 21,
        backgroundColor: Colors.white,
        backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes!) : null,
        child: avatarBytes == null
            ? const Icon(
                Icons.person_rounded,
                color: Color(0xFF2E4DE8),
                size: 24,
              )
            : null,
      ),
    );
  }
}

class _HeroBubble extends StatelessWidget {
  final double size;
  final Color color;
  const _HeroBubble({required this.size, required this.color});

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

class _HeroCurveClipper extends CustomClipper<Path> {
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
