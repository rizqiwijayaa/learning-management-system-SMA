import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:lms_guru/roles/guru/models/user_profile.dart';
import 'package:lms_guru/roles/guru/screens/auth/forgot_password_page.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _pageFocusNode = FocusNode();
  final LmsApiService _api = LmsApiService();
  final ProfileStore _profileStore = ProfileStore.instance;
  bool _rememberMe = false;
  bool _loggingIn = false;
  bool _obscurePassword = true;
  OverlayEntry? _errorOverlay;

  void _focusPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageFocusNode.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();
    _restoreRememberedLogin();
  }

  Future<void> _restoreRememberedLogin() async {
    final remembered = await _profileStore.getRememberedLogin();
    if (!mounted) return;
    setState(() {
      _rememberMe = remembered.rememberMe;
      if (remembered.email.isNotEmpty) {
        _emailController.text = remembered.email;
      }
    });
  }

  @override
  void dispose() {
    _removeErrorOverlay();
    _pageFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _removeErrorOverlay() {
    _errorOverlay?.remove();
    _errorOverlay = null;
  }

  void _showTopErrorNotification(String message) {
    _removeErrorOverlay();

    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    _errorOverlay = OverlayEntry(
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
                      color: const Color(0xFFCB2B20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD2CE),
                        width: 1.2,
                      ),
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
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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

    overlay.insert(_errorOverlay!);

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _removeErrorOverlay();
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showTopErrorNotification('Email dan password wajib diisi.');
      return;
    }

    setState(() {
      _loggingIn = true;
    });

    try {
      final loginProfile = await _api.login(email: email, password: password);
      UserProfile profile = loginProfile;
      ProfileStore.instance.setProfile(loginProfile);

      try {
        final fetchedProfile = await _api.getProfile(
          id: loginProfile.id,
          nip: loginProfile.nip,
          email: loginProfile.email,
        );

        final sameUser =
            fetchedProfile.nip.trim() == loginProfile.nip.trim() &&
            fetchedProfile.email.trim().toLowerCase() ==
                loginProfile.email.trim().toLowerCase();

        if (sameUser) {
          profile = fetchedProfile;
        } else {
          profile = loginProfile;
        }
      } catch (_) {
        profile = loginProfile;
      }

      ProfileStore.instance.setProfile(profile);
      await _profileStore.persistRememberedLogin(
        rememberMe: _rememberMe,
        email: email,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (err) {
      if (!mounted) return;
      final message = err.toString();
      String userMessage = 'Login gagal. Coba lagi.';

      if (message.contains('Failed to fetch') ||
          message.contains('ClientException')) {
        userMessage =
            'Backend belum tersambung. Jalankan server terlebih dahulu.';
      } else if (message.contains('Email tidak terdaftar') ||
          message.contains('Password salah') ||
          message.contains('Email atau password salah')) {
        userMessage = 'Email atau kata sandi yang Anda masukkan salah.';
      } else if (message.contains('Email dan password wajib diisi')) {
        userMessage = 'Email dan password wajib diisi.';
      }

      _showTopErrorNotification(userMessage);
    } finally {
      if (mounted) {
        setState(() {
          _loggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focusPage,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWebLayout = kIsWeb;

              if (isWebLayout) {
                return _LoginWebLayout(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  rememberMe: _rememberMe,
                  onRememberChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                    _focusPage();
                  },
                  onLogin: _handleLogin,
                  isLoading: _loggingIn,
                  obscurePassword: _obscurePassword,
                  onTogglePasswordVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onForgotPassword: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  onBack: () => Navigator.of(context).maybePop(),
                  pageFocusNode: _pageFocusNode,
                  onTapOutsideField: _focusPage,
                );
              }

              return _LoginMobileLayout(
                emailController: _emailController,
                passwordController: _passwordController,
                rememberMe: _rememberMe,
                onRememberChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                  _focusPage();
                },
                onLogin: _handleLogin,
                isLoading: _loggingIn,
                obscurePassword: _obscurePassword,
                onTogglePasswordVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onForgotPassword: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  );
                },
                onBack: () => Navigator.of(context).maybePop(),
                pageFocusNode: _pageFocusNode,
                onTapOutsideField: _focusPage,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginWebLayout extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberChanged;
  final Future<void> Function() onLogin;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;
  final FocusNode pageFocusNode;
  final VoidCallback onTapOutsideField;

  const _LoginWebLayout({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onForgotPassword,
    required this.onBack,
    required this.pageFocusNode,
    required this.onTapOutsideField,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginContent(
      horizontalPadding: 40,
      maxWidth: double.infinity,
      isDesktop: true,
      fullWidth: true,
      emailController: emailController,
      passwordController: passwordController,
      rememberMe: rememberMe,
      onRememberChanged: onRememberChanged,
      onLogin: onLogin,
      isLoading: isLoading,
      obscurePassword: obscurePassword,
      onTogglePasswordVisibility: onTogglePasswordVisibility,
      onForgotPassword: onForgotPassword,
      onBack: onBack,
      pageFocusNode: pageFocusNode,
      onTapOutsideField: onTapOutsideField,
    );
  }
}

class _LoginMobileLayout extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberChanged;
  final Future<void> Function() onLogin;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;
  final FocusNode pageFocusNode;
  final VoidCallback onTapOutsideField;

  const _LoginMobileLayout({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onForgotPassword,
    required this.onBack,
    required this.pageFocusNode,
    required this.onTapOutsideField,
  });

  @override
  Widget build(BuildContext context) {
    return _LoginContent(
      horizontalPadding: 12,
      maxWidth: double.infinity,
      isDesktop: false,
      fullWidth: true,
      emailController: emailController,
      passwordController: passwordController,
      rememberMe: rememberMe,
      onRememberChanged: onRememberChanged,
      onLogin: onLogin,
      isLoading: isLoading,
      obscurePassword: obscurePassword,
      onTogglePasswordVisibility: onTogglePasswordVisibility,
      onForgotPassword: onForgotPassword,
      onBack: onBack,
      pageFocusNode: pageFocusNode,
      onTapOutsideField: onTapOutsideField,
    );
  }
}

class _LoginContent extends StatelessWidget {
  final double horizontalPadding;
  final double maxWidth;
  final bool isDesktop;
  final bool fullWidth;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberChanged;
  final Future<void> Function() onLogin;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;
  final FocusNode pageFocusNode;
  final VoidCallback onTapOutsideField;

  const _LoginContent({
    required this.horizontalPadding,
    required this.maxWidth,
    required this.isDesktop,
    required this.fullWidth,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onForgotPassword,
    required this.onBack,
    required this.pageFocusNode,
    required this.onTapOutsideField,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final mobileHeroHeight = (screenSize.height * 0.31).clamp(236.0, 304.0);
    final mobileTitleFontSize = (screenSize.width * 0.115).clamp(30.0, 40.0);
    final mobileSubtitleFontSize = (screenSize.width * 0.037).clamp(12.0, 13.0);
    final mobileIllustrationScale = (screenSize.width / 390).clamp(0.62, 0.82);

    final content = Focus(
      focusNode: pageFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent || isLoading) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          onLogin();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Column(
          children: [
            _LoginHero(
              onBack: onBack,
              heroHeight: isDesktop ? 360 : mobileHeroHeight,
              titleFontSize: isDesktop ? 52 : mobileTitleFontSize,
              subtitleFontSize: isDesktop ? 15 : mobileSubtitleFontSize,
              illustrationScale: isDesktop ? 1 : mobileIllustrationScale,
            ),
            SizedBox(height: isDesktop ? 24 : 22),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email address',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF202126),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: emailController,
              hintText: 'Email address',
              icon: Icons.mail_outline,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              onTapOutside: onTapOutsideField,
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF202126),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: passwordController,
              hintText: 'Password',
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                onPressed: onTogglePasswordVisibility,
                splashRadius: 18,
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFC3C8D8),
                  size: 20,
                ),
              ),
              onTapOutside: onTapOutsideField,
              onSubmitted: (_) {
                if (!isLoading) {
                  onLogin();
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: rememberMe,
                    activeColor: const Color(0xFF4666FF),
                    side: const BorderSide(color: Color(0xFFCCD1E2)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: onRememberChanged,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 13, color: Color(0xFF61657A)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Lupa password?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6280FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  onPressed: isLoading ? null : onLogin,
                  style: ElevatedButton.styleFrom(
                    shadowColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: isLoading
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
                                      'Login Now',
                                      style: TextStyle(
                                        fontSize: 18,
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
          ],
        ),
    );

    if (fullWidth) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 0,
        ),
        child: content,
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  final VoidCallback onBack;
  final double heroHeight;
  final double titleFontSize;
  final double subtitleFontSize;
  final double illustrationScale;

  const _LoginHero({
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
                  const _HeroPattern(),
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
                                'Log In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 0.95,
                                ),
                              ),
                              SizedBox(height: isDesktop ? 8 : 6),
                              Text(
                                'Experience a better learning\nenvironment.',
                                style: TextStyle(
                                  color: Color(0xFFE4E9FF),
                                  fontSize: subtitleFontSize,
                                  height: 1.3,
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
                  clipper: _CurveClipper(),
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
            bottom: isDesktop ? 28 : 4,
            child: Transform.translate(
              offset: Offset(0, isDesktop ? 0 : -6),
              child: Transform.scale(
                scale: illustrationScale,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: isDesktop ? 170 : 132,
                  child: const _HeroIllustration(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTapOutside;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.onTapOutside,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        onTapOutside: (_) => onTapOutside?.call(),
        style: const TextStyle(fontSize: 14, color: Color(0xFF2B2D35)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFADB2C3), fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          prefixIcon: Icon(icon, color: const Color(0xFFC3C8D8), size: 20),
          suffixIcon: suffixIcon,
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
    );
  }
}

class _HeroPattern extends StatelessWidget {
  const _HeroPattern();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          left: -90,
          top: -40,
          child: _Bubble(size: 220, color: Color(0x1EFFFFFF)),
        ),
        Positioned(
          right: -75,
          top: 30,
          child: _Bubble(size: 190, color: Color(0x18FFFFFF)),
        ),
        Positioned(
          left: -70,
          bottom: 10,
          child: _Bubble(size: 250, color: Color(0x20FFFFFF)),
        ),
      ],
    );
  }
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
          radius: 0.9,
        ),
      ),
    );
  }
}

class _CurveClipper extends CustomClipper<Path> {
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

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        final phoneLeft = compact ? 4.0 : 10.0;
        final tabletRight = compact ? -12.0 : 6.0;
        final personLeft = compact ? 112.0 : 122.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: phoneLeft,
              bottom: 30,
              child: Transform.rotate(
                angle: -0.26,
                child: Container(
                  width: 88,
                  height: 144,
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
                    child: Stack(
                      children: const [
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.check_circle,
                            size: 15,
                            color: Color(0xFFF07AA9),
                          ),
                        ),
                        Center(
                          child: _StackLogo(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: tabletRight,
              bottom: 42,
              child: Container(
                width: 178,
                height: 104,
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
                child: Column(
                  children: [
                    Container(
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            _MiniPillar(h: 20),
                            SizedBox(width: 5),
                            _MiniPillar(h: 34),
                            SizedBox(width: 5),
                            _MiniPillar(h: 48),
                            SizedBox(width: 5),
                            _MiniPillar(h: 26),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              top: 78,
              child: Icon(
                Icons.wifi_tethering_rounded,
                color: Color(0xFFFA738D),
                size: 30,
              ),
            ),
            const Positioned(
              left: 38,
              bottom: 38,
              child: Icon(Icons.public, color: Color(0xFF2BA8F8), size: 34),
            ),
            const Positioned(
              right: 24,
              top: 88,
              child: Icon(
                Icons.headset_mic_outlined,
                color: Color(0xFF61D4EE),
                size: 22,
              ),
            ),
            const Positioned(
              right: 34,
              bottom: 34,
              child: Icon(Icons.search, color: Color(0xFFEC5D9B), size: 24),
            ),
            Positioned(
              left: personLeft,
              bottom: 28,
              child: const Icon(Icons.person, color: Color(0xFF4A5CE7), size: 22),
            ),
          ],
        );
      },
    );
  }
}

class _StackLogo extends StatelessWidget {
  const _StackLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 52,
      child: Stack(
        children: const [
          Positioned(
            left: 2,
            bottom: 4,
            child: _LogoBlock(
              width: 14,
              height: 24,
              color: Color(0xFF69D3FF),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 8,
            child: _LogoBlock(
              width: 14,
              height: 28,
              color: Color(0xFF55A9FF),
            ),
          ),
          Positioned(
            left: 26,
            bottom: 14,
            child: _LogoBlock(
              width: 14,
              height: 24,
              color: Color(0xFFF7A9D8),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 22,
            child: _LogoBlock(
              width: 14,
              height: 22,
              color: Color(0xFFFFD574),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _LogoBlock({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _MiniPillar extends StatelessWidget {
  final double h;

  const _MiniPillar({required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF4B66FF),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
