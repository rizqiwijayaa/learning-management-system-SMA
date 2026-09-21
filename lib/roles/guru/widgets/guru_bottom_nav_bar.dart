import 'package:flutter/material.dart';

class GuruBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool mobile;
  final bool includeNilai;

  const GuruBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.compact = false,
    this.mobile = false,
    this.includeNilai = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, mobile ? 'Beranda' : 'Dashboard'),
      (Icons.menu_book_rounded, 'Materi'),
      (Icons.assignment_rounded, 'Tugas'),
      if (includeNilai) (Icons.bar_chart_rounded, 'Nilai'),
      (Icons.calendar_month_rounded, 'Absensi'),
      (Icons.receipt_long_rounded, 'Jurnal'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0819407F),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final active = currentIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$1,
                      size: 24,
                      color: active
                          ? const Color(0xFF2F61F3)
                          : const Color(0xFF7E88A4),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF2F61F3)
                            : const Color(0xFF7E88A4),
                        fontSize: mobile ? 11 : (compact ? 11 : 13),
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? 54 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F61F3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
