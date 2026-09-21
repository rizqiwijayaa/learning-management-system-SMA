// Pindahkan file ini ke lib/roles/kepala_sekolah/widgets/

import 'package:flutter/material.dart';

class KepalaSekolahFeaturePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<KepalaSekolahMetric> metrics;
  final List<KepalaSekolahHighlight> highlights;
  final List<String> focusItems;
  final List<String> actionNotes;
  final List<KepalaSekolahHighlightSection> extraHighlightSections;
  final KepalaSekolahDetailSection? detailSection;
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
    this.extraHighlightSections = const [],
    this.detailSection,
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
              constraints: const BoxConstraints(maxWidth: 1180),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth;
                  final isWide = contentWidth >= 980;
                  final sidePanelWidth = isWide ? (contentWidth - 12) / 2 : contentWidth;
                  final panels = <Widget>[
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
                    ...extraHighlightSections.map(
                      (section) => _HighlightPanel(
                        title: section.title,
                        icon: section.icon,
                        accentColor: accentColor,
                        children: section.items
                            .map(
                              (item) => _HighlightTile(
                                item: item,
                                accentColor: accentColor,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ];

                  return Column(
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
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: List.generate(panels.length, (index) => index)
                                    .where((index) => index.isEven)
                                    .map(
                                      (index) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index == panels.length - 2 ||
                                                  (panels.length.isOdd &&
                                                      index == panels.length - 1)
                                              ? 0
                                              : 12,
                                        ),
                                        child: panels[index],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: List.generate(panels.length, (index) => index)
                                    .where((index) => index.isOdd)
                                    .map(
                                      (index) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index == panels.length - 1 ? 0 : 12,
                                        ),
                                        child: panels[index],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(panels.length, (index) {
                            return SizedBox(
                              width: sidePanelWidth,
                              child: panels[index],
                            );
                          }),
                        ),
                      if (detailSection != null) ...[
                        const SizedBox(height: 14),
                        _DetailExplorer(
                          section: detailSection!,
                          accentColor: accentColor,
                        ),
                      ],
                    ],
                  );
                },
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

class KepalaSekolahHighlightSection {
  final String title;
  final IconData icon;
  final List<KepalaSekolahHighlight> items;

  const KepalaSekolahHighlightSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class KepalaSekolahDetailSection {
  final String title;
  final IconData icon;
  final String searchHint;
  final List<KepalaSekolahDetailEntry> entries;

  const KepalaSekolahDetailSection({
    required this.title,
    required this.icon,
    required this.searchHint,
    required this.entries,
  });
}

class KepalaSekolahDetailEntry {
  final String title;
  final String subtitle;
  final String badge;
  final List<KepalaSekolahDetailField> fields;

  const KepalaSekolahDetailEntry({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.fields,
  });
}

class KepalaSekolahDetailField {
  final String label;
  final String value;

  const KepalaSekolahDetailField({
    required this.label,
    required this.value,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: compact ? 232 : 186,
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
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BackButtonLine(onTap: () => Navigator.of(context).maybePop()),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
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
                            const SizedBox(height: 14),
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
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BackButtonLine(
                                    onTap: () => Navigator.of(context).maybePop(),
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
      },
    );
  }
}

class _BackButtonLine extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButtonLine({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columnCount = maxWidth >= 980
            ? 4
            : maxWidth >= 640
                ? 2
                : 1;
        final itemWidth = (maxWidth - ((columnCount - 1) * 10)) / columnCount;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
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
              )
              .toList(),
        );
      },
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

class _DetailExplorer extends StatefulWidget {
  final KepalaSekolahDetailSection section;
  final Color accentColor;

  const _DetailExplorer({
    required this.section,
    required this.accentColor,
  });

  @override
  State<_DetailExplorer> createState() => _DetailExplorerState();
}

class _DetailExplorerState extends State<_DetailExplorer> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredEntries = widget.section.entries.where((entry) {
      final haystack = [
        entry.title,
        entry.subtitle,
        entry.badge,
        ...entry.fields.map((field) => '${field.label} ${field.value}'),
      ].join(' ').toLowerCase();
      return query.isEmpty || haystack.contains(query);
    }).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.section.icon,
                  color: widget.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.section.title,
                  style: const TextStyle(
                    color: Color(0xFF1F273A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.section.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE3F4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE3F4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: widget.accentColor),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (filteredEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Tidak ada data yang cocok dengan pencarian.',
                style: TextStyle(
                  color: Color(0xFF6A7592),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...filteredEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _showEntryDetail(context, entry),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E8F4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  color: Color(0xFF1F273A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF6A7592),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            entry.badge,
                            style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }

  Future<void> _showEntryDetail(
    BuildContext context,
    KepalaSekolahDetailEntry entry,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(entry.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6A7592),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ...entry.fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            field.label,
                            style: const TextStyle(
                              color: Color(0xFF1F273A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            field.value,
                            style: const TextStyle(color: Color(0xFF4D5876)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
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
