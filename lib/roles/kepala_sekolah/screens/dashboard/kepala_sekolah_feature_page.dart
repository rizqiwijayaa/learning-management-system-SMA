import 'package:flutter/material.dart';

class KepalaSekolahFeaturePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<KepalaSekolahMetric> metrics;
  final List<KepalaSekolahHighlight> highlights;
  final List<String> focusItems;
  final List<String> actionNotes;
  final Color accentColor;

  const KepalaSekolahFeaturePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.metrics,
    required this.highlights,
    required this.focusItems,
    required this.actionNotes,
    this.accentColor = const Color(0xFF2E4DE8),
  });

  @override
  Widget build(BuildContext context) {
    final heroGradient = [
      const Color(0xFF2B3BFF),
      accentColor,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Column(
                children: [
                  _FeatureHero(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    gradientColors: heroGradient,
                  ),
                  const SizedBox(height: 14),
                  _InsightStrip(metrics: metrics, accentColor: accentColor),
                  const SizedBox(height: 14),
                  _HighlightPanel(
                    title: 'Sorotan Hari Ini',
                    icon: Icons.insights_rounded,
                    accentColor: accentColor,
                    children: highlights
                        .map(
                          (item) => _HighlightTile(
                            item: item,
                            accentColor: accentColor,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _HighlightPanel(
                    title: 'Fokus Kepala Sekolah',
                    icon: Icons.track_changes_rounded,
                    accentColor: accentColor,
                    children: focusItems
                        .map(
                          (item) => _BulletLine(
                            text: item,
                            accentColor: accentColor,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _HighlightPanel(
                    title: 'Catatan Tindak Lanjut',
                    icon: Icons.assignment_rounded,
                    accentColor: accentColor,
                    children: actionNotes
                        .asMap()
                        .entries
                        .map(
                          (entry) => _ActionTile(
                            number: entry.key + 1,
                            text: entry.value,
                            accentColor: accentColor,
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
    );
  }
}

class KepalaSekolahMetric {
  final String label;
  final String value;
  final String note;

  const KepalaSekolahMetric({
    required this.label,
    required this.value,
    required this.note,
  });
}

class KepalaSekolahHighlight {
  final String title;
  final String description;
  final String badge;

  const KepalaSekolahHighlight({
    required this.title,
    required this.description,
    required this.badge,
  });
}

class _FeatureHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  const _FeatureHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 186,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
            ),
            const Positioned(
              left: -48,
              top: -34,
              child: _HeaderBubble(size: 168, color: Color(0x20FFFFFF)),
            ),
            const Positioned(
              right: -30,
              top: 24,
              child: _HeaderBubble(size: 142, color: Color(0x16FFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(
                      height: 80,
                      color: const Color(0xFFF3F5FB),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Kembali',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFDDE5FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  final List<KepalaSekolahMetric> metrics;
  final Color accentColor;

  const _InsightStrip({
    required this.metrics,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: metrics
          .map(
            (metric) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: metric == metrics.last ? 0 : 10,
                ),
                child: Container(
                  height: 110,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4E8F4)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A233B7A),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.label,
                        style: const TextStyle(
                          color: Color(0xFF6A7592),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        metric.value,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.note,
                        style: const TextStyle(
                          color: Color(0xFF4D5876),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HighlightPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _HighlightPanel({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E8F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E2433),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final KepalaSekolahHighlight item;
  final Color accentColor;

  const _HighlightTile({
    required this.item,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EBF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF1E2433),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Color(0xFF68738E),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.badge,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _BulletLine({
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E5975),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final int number;
  final String text;
  final Color accentColor;

  const _ActionTile({
    required this.number,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E5975),
                fontSize: 13,
                height: 1.45,
              ),
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
    path.moveTo(0, 48);
    path.quadraticBezierTo(size.width * 0.28, 22, size.width * 0.62, 44);
    path.quadraticBezierTo(size.width * 0.86, 58, size.width, 30);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
