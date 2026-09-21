import 'package:flutter/material.dart';
import 'dashboard_models.dart';

class BoardCard extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final Color leadingColor;
  final String trailingLabel;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const BoardCard({
    super.key,
    required this.title,
    required this.leadingIcon,
    required this.leadingColor,
    required this.trailingLabel,
    this.onTrailingTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 880;
        final width = isWide
            ? (constraints.maxWidth - 14) / 2
            : double.infinity;

        return SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6EBF7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A20387A),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(leadingIcon, color: leadingColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF171D2D),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onTrailingTap,
                      child: Text(
                        trailingLabel,
                        style: const TextStyle(
                          color: Color(0xFF2F6BFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class IssueList extends StatelessWidget {
  final List<IssueItem> items;
  final VoidCallback? onTap;

  const IssueList({
    super.key,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFFFF8A00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFF202636),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  item.status,
                  style: const TextStyle(
                    color: Color(0xFFFF6E2F),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        _SoftActionButton(
          label: 'Selengkapnya',
          color: const Color(0xFFEEDCB8),
          textColor: const Color(0xFFD1971A),
          onTap: onTap,
        ),
      ],
    );
  }
}

class EventList extends StatelessWidget {
  final List<EventItem> items;
  final VoidCallback? onTap;
  const EventList({super.key, required this.items, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EBFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Color(0xFF8B52E8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Color(0xFF202636),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${item.schedule} - ${item.location}',
                        style: const TextStyle(
                          color: Color(0xFF757F98),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _SoftActionButton(
          label: 'Selengkapnya',
          color: const Color(0xFFF0E9FF),
          textColor: const Color(0xFF8B52E8),
          onTap: onTap,
        ),
      ],
    );
  }
}

class JournalPreviewList extends StatelessWidget {
  final List<dynamic> entries;
  final VoidCallback? onTap;
  const JournalPreviewList({super.key, required this.entries, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...entries.map((entry) {
          final e = entry as dynamic;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F6BFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.subject} - ${e.className}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        e.title.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        _SoftActionButton(
          label: 'Selengkapnya',
          color: const Color(0xFFEAF0FF),
          textColor: const Color(0xFF2F6BFF),
          onTap: onTap,
        ),
      ],
    );
  }
}

class AttendanceRecap extends StatelessWidget {
  final int siswaHadir;
  final int totalSiswa;
  final int guruHadir;
  final int totalGuru;
  final double persentaseSiswa;
  final double persentaseGuru;
  final String primaryLabel;
  final String secondaryLabel;

  const AttendanceRecap({
    super.key,
    required this.siswaHadir,
    required this.totalSiswa,
    required this.guruHadir,
    required this.totalGuru,
    required this.persentaseSiswa,
    required this.persentaseGuru,
    this.primaryLabel = 'Siswa Hadir',
    this.secondaryLabel = 'Guru Hadir',
  });

  @override
  Widget build(BuildContext context) {
    final primaryMissing = (totalSiswa - siswaHadir).clamp(0, totalSiswa);
    final secondaryMissing = (totalGuru - guruHadir).clamp(0, totalGuru);

    return Column(
      children: [
        _RecapRow(
          label: primaryLabel,
          value: '$siswaHadir/$totalSiswa',
          percentage: persentaseSiswa,
          color: const Color(0xFF2CB34A),
        ),
        const SizedBox(height: 12),
        _RecapRow(
          label: secondaryLabel,
          value: '$guruHadir/$totalGuru',
          percentage: persentaseGuru,
          color: const Color(0xFF2F6BFF),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AttendanceBadge(
                label: 'Perlu Cek',
                value: '$primaryMissing data',
                toneColor: const Color(0xFFFF8A00),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AttendanceBadge(
                label: 'Catatan Kedua',
                value: '$secondaryMissing data',
                toneColor: const Color(0xFF8B52E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6EBF7)),
          ),
          child: Text(
            '$primaryLabel dan $secondaryLabel dipakai sebagai pembacaan cepat kondisi absensi siswa hari ini.',
            style: const TextStyle(
              color: Color(0xFF6A7592),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color toneColor;

  const _AttendanceBadge({
    required this.label,
    required this.value,
    required this.toneColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: toneColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: toneColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F273A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ComparisonList extends StatelessWidget {
  final List<ComparisonItem> items;

  const ComparisonList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
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
                            color: Color(0xFF1F273A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF6A7592),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge,
                      style: const TextStyle(
                        color: Color(0xFF2F6BFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class TrendSummaryList extends StatelessWidget {
  final List<TrendItem> items;

  const TrendSummaryList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF1F273A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6EBF7)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.primaryValue,
                              style: const TextStyle(
                                color: Color(0xFF2F6BFF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.secondaryValue,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFF8B52E8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class InsightSummaryList extends StatelessWidget {
  final List<InsightItem> items;

  const InsightSummaryList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE4C2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: Color(0xFFFF8A00),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF1F273A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Color(0xFF6A7592),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.badge,
                    style: const TextStyle(
                      color: Color(0xFFD67B00),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class CrossModuleList extends StatelessWidget {
  final List<CrossModuleItem> items;

  const CrossModuleList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCEEDF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF1F273A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.note,
                          style: const TextStyle(
                            color: Color(0xFF6A7592),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: Color(0xFF2CB34A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class SnapshotGrid extends StatelessWidget {
  final List<SnapshotItem> items;

  const SnapshotGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => SizedBox(
              width: 140,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6EBF7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF6A7592),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: Color(0xFF1F273A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.note,
                      style: const TextStyle(
                        color: Color(0xFF6A7592),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final String label;
  final String value;
  final double percentage;
  final Color color;

  const _RecapRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}

class _SoftActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _SoftActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
