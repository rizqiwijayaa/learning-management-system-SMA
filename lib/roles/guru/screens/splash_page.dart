import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lms_guru/roles/guru/screens/auth/login_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    void openLogin() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }

    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }

          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter) {
            openLogin();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2936FF), Color(0xFF1A1FCF)],
                ),
              ),
            ),
            const _BackgroundPattern(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWebLayout = kIsWeb;

                  if (isWebLayout) {
                    return _SplashWebLayout(onGetStarted: openLogin);
                  }

                  return _SplashMobileLayout(onGetStarted: openLogin);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashWebLayout extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _SplashWebLayout({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: _SplashContent(
            logoSize: 230,
            textSize: 26,
            buttonHeight: 60,
            buttonFontSize: 20,
            onGetStarted: onGetStarted,
          ),
        ),
      ),
    );
  }
}

class _SplashMobileLayout extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _SplashMobileLayout({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: _SplashContent(
        logoSize: 170,
        textSize: 20,
        buttonHeight: 52,
        buttonFontSize: 16,
        onGetStarted: onGetStarted,
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  final double logoSize;
  final double textSize;
  final double buttonHeight;
  final double buttonFontSize;
  final VoidCallback onGetStarted;

  const _SplashContent({
    required this.logoSize,
    required this.textSize,
    required this.buttonHeight,
    required this.buttonFontSize,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/cropped-favicon.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
        const Spacer(flex: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Enjoy Your Education at Your Fingertips !',
                style: TextStyle(
                  color: const Color(0xFF1E1E1E),
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _BackgroundPattern extends StatelessWidget {
  const _BackgroundPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const _Shape(
            size: 420,
            left: -170,
            top: -60,
            color: Color(0x1FFFFFFF),
          ),
          const _Shape(
            size: 360,
            left: -140,
            top: 180,
            color: Color(0x24FFFFFF),
          ),
          const _Shape(
            size: 420,
            right: -170,
            top: 80,
            color: Color(0x18FFFFFF),
          ),
          const _Shape(
            size: 370,
            right: -150,
            bottom: 110,
            color: Color(0x1DFFFFFF),
          ),
          const _Shape(
            size: 430,
            left: -180,
            bottom: -140,
            color: Color(0x20FFFFFF),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [Color(0x14000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shape extends StatelessWidget {
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final Color color;

  const _Shape({
    required this.size,
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withAlpha(0)],
            radius: .92,
          ),
        ),
      ),
    );
  }
}
