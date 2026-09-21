import 'package:flutter/material.dart';

class KesiswaanBottomNavBar extends StatelessWidget {
  const KesiswaanBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = <_NavItemData>[
    _NavItemData(Icons.home_rounded, 'Home'),
    _NavItemData(Icons.library_books_rounded, 'Jurnal'),
    _NavItemData(Icons.dashboard_customize_rounded, 'Kelola'),
    _NavItemData(Icons.fact_check_rounded, 'Absensi'),
    _NavItemData(Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return Container(
          height: compact ? 66 : 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8ECF7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F21438A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final active = currentIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: active ? (compact ? 24 : 30) : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D60F1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(height: active ? 6 : 9),
                        Icon(
                          item.icon,
                          size: compact ? 20 : 24,
                          color: active
                              ? const Color(0xFF2D60F1)
                              : const Color(0xFF7682A5),
                        ),
                        SizedBox(height: compact ? 3 : 5),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active
                                ? const Color(0xFF2D60F1)
                                : const Color(0xFF7682A5),
                            fontSize: compact ? 9.5 : 11,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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
      },
    );
  }

}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData(this.icon, this.label);
}
