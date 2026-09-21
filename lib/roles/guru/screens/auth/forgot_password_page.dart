import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final LmsApiService _api = LmsApiService();
  OverlayEntry? _notificationOverlay;
  bool _submitting = false;

  @override
  void dispose() {
    _removeNotification();
    _emailController.dispose();
    super.dispose();
  }

  void _removeNotification() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  void _showTopNotification({
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
  }) {
    _removeNotification();

    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40191A1C),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0x26FFFFFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * -18),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_notificationOverlay!);

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _removeNotification();
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showTopNotification(
        message: 'Masukkan email terlebih dahulu.',
        backgroundColor: const Color(0xFFCB2B20),
        borderColor: const Color(0xFFFFD2CE),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      _showTopNotification(
        message: 'Masukkan email dengan benar.',
        backgroundColor: const Color(0xFFCB2B20),
        borderColor: const Color(0xFFFFD2CE),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final message = await _api.forgotPassword(email: email);
      if (!mounted) return;
      _showTopNotification(
        message: message,
        backgroundColor: const Color(0xFF2762F3),
        borderColor: const Color(0xFFBFD2FF),
        icon: Icons.mark_email_read_outlined,
      );
    } catch (err) {
      if (!mounted) return;

      final message = err.toString();
      String userMessage = 'Gagal memproses lupa password.';

      if (message.contains('Email tidak ditemukan') ||
          message.contains('Email tidak terdaftar')) {
        userMessage = 'Email tidak ditemukan.';
      } else if (message.contains('Email wajib diisi')) {
        userMessage = 'Masukkan email terlebih dahulu.';
      } else if (message.contains('Failed to fetch') ||
          message.contains('ClientException')) {
        userMessage =
            'Backend belum tersambung. Jalankan server terlebih dahulu.';
      } else if (message.contains('Route tidak ditemukan')) {
        userMessage = 'Backend belum diperbarui untuk fitur lupa password.';
      }

      _showTopNotification(
        message: userMessage,
        backgroundColor: const Color(0xFFCB2B20),
        borderColor: const Color(0xFFFFD2CE),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = kIsWeb;
    final screenSize = MediaQuery.sizeOf(context);
    final mobileHeroHeight = (screenSize.height * 0.325).clamp(250.0, 320.0);
    final mobileTitleFontSize = (screenSize.width * 0.115).clamp(30.0, 40.0);
    final mobileSubtitleFontSize = (screenSize.width * 0.037).clamp(12.0, 13.0);
    final mobileIllustrationScale = (screenSize.width / 390).clamp(0.62, 0.82);
    final content = _ForgotPasswordContent(
      isDesktop: isWebLayout,
      mobileHeroHeight: mobileHeroHeight,
      mobileTitleFontSize: mobileTitleFontSize,
      mobileSubtitleFontSize: mobileSubtitleFontSize,
      mobileIllustrationScale: mobileIllustrationScale,
      emailController: _emailController,
      isSubmitting: _submitting,
      onSubmit: _submit,
      onBack: () => Navigator.of(context).maybePop(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: isWebLayout
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 0,
                ),
                child: content,
              )
            : Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: double.infinity),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ForgotPasswordContent extends StatelessWidget {
  final bool isDesktop;
  final double mobileHeroHeight;
  final double mobileTitleFontSize;
  final double mobileSubtitleFontSize;
  final double mobileIllustrationScale;
  final TextEditingController emailController;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;
  final VoidCallback onBack;

  const _ForgotPasswordContent({
    required this.isDesktop,
    required this.mobileHeroHeight,
    required this.mobileTitleFontSize,
    required this.mobileSubtitleFontSize,
    required this.mobileIllustrationScale,
    required this.emailController,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ForgotPasswordHero(
          onBack: onBack,
          heroHeight: isDesktop ? 360 : mobileHeroHeight,
          titleFontSize: isDesktop ? 50 : mobileTitleFontSize,
          subtitleFontSize: isDesktop ? 15 : mobileSubtitleFontSize,
          illustrationScale: isDesktop ? 1 : mobileIllustrationScale,
        ),
        SizedBox(height: isDesktop ? 24 : 20),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 22 : 18,
            isDesktop ? 22 : 18,
            isDesktop ? 22 : 18,
            isDesktop ? 22 : 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lupa Password?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202126),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan email Anda, lalu kami akan mengirimkan instruksi untuk mengatur ulang kata sandi.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF61657A),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Email address',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF202126),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: emailController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isSubmitting) {
                      onSubmit();
                    }
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2B2D35),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: const TextStyle(
                      color: Color(0xFFADB2C3),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FB),
                    prefixIcon: const Icon(
                      Icons.mail_outline,
                      color: Color(0xFFC3C8D8),
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD7DBE8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF5674FF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF496EFF), Color(0xFF3462F2)],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2B3550C8),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Kirim Instruksi',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 19),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Kembali ke login',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6280FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordHero extends StatelessWidget {
  final VoidCallback onBack;
  final double heroHeight;
  final double titleFontSize;
  final double subtitleFontSize;
  final double illustrationScale;

  const _ForgotPasswordHero({
    required this.onBack,
    required this.heroHeight,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.illustrationScale,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = heroHeight >= 350;
    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isDesktop ? 26 : 22),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2738FF), Color(0xFF2028CE)],
                      ),
                    ),
                  ),
                  const _ForgotHeroPattern(),
                  Positioned(
                    left: 18,
                    right: 18,
                    top: isDesktop ? 18 : 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reset\nPassword',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 0.95,
                                ),
                              ),
                              SizedBox(height: isDesktop ? 8 : 6),
                              Text(
                                'Tetap lanjut belajar dengan akses akun yang aman dan cepat.',
                                style: TextStyle(
                                  color: const Color(0xFFE4E9FF),
                                  fontSize: subtitleFontSize,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: isDesktop ? 40 : 38,
                            height: isDesktop ? 40 : 38,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF303FCC),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: ClipPath(
                  clipper: _ForgotCurveClipper(),
                  child: Container(
                    height: isDesktop ? 170 : 92,
                    color: const Color(0xFFF7F8FB),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: isDesktop ? 22 : 24,
            right: isDesktop ? 22 : 24,
            bottom: isDesktop ? 28 : -4,
            child: Transform.translate(
              offset: Offset(0, isDesktop ? 0 : 18),
              child: Transform.scale(
                scale: illustrationScale,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: isDesktop ? 170 : 132,
                  child: const _ForgotHeroIllustration(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotHeroPattern extends StatelessWidget {
  const _ForgotHeroPattern();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          left: -90,
          top: -40,
          child: _ForgotBubble(size: 220, color: Color(0x1EFFFFFF)),
        ),
        Positioned(
          right: -75,
          top: 30,
          child: _ForgotBubble(size: 190, color: Color(0x18FFFFFF)),
        ),
        Positioned(
          left: -70,
          bottom: 10,
          child: _ForgotBubble(size: 250, color: Color(0x20FFFFFF)),
        ),
      ],
    );
  }
}

class _ForgotBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _ForgotBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          radius: 0.9,
        ),
      ),
    );
  }
}

class _ForgotCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 124);
    path.quadraticBezierTo(size.width * 0.24, 66, size.width * 0.58, 96);
    path.quadraticBezierTo(size.width * 0.84, 128, size.width, 72);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _ForgotHeroIllustration extends StatelessWidget {
  const _ForgotHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        final phoneLeft = compact ? 8.0 : 14.0;
        final tabletRight = compact ? -14.0 : 4.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: phoneLeft,
              bottom: 26,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  width: 94,
                  height: 136,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9EAAFF), Color(0xFF4A61FF)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2A2F43AF),
                        blurRadius: 12,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF4A61FF),
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: tabletRight,
              bottom: 42,
              child: Container(
                width: 182,
                height: 106,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFCFF),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFD3DCF8)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A3B50A8),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _ForgotLine(width: 82),
                      SizedBox(height: 10),
                      _ForgotLine(width: 126),
                      SizedBox(height: 10),
                      _ForgotLine(width: 92),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 4,
              top: 78,
              child: Icon(
                Icons.mark_email_unread_outlined,
                color: Color(0xFFFA738D),
                size: 30,
              ),
            ),
            const Positioned(
              left: 42,
              bottom: 38,
              child: Icon(
                Icons.shield_outlined,
                color: Color(0xFF2BA8F8),
                size: 34,
              ),
            ),
            const Positioned(
              right: 26,
              top: 86,
              child: Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF61D4EE),
                size: 22,
              ),
            ),
            const Positioned(
              right: 34,
              bottom: 34,
              child: Icon(Icons.send_outlined, color: Color(0xFFEC5D9B), size: 24),
            ),
          ],
        );
      },
    );
  }
}

class _ForgotLine extends StatelessWidget {
  final double width;

  const _ForgotLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECFF),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
