import 'package:flutter/material.dart';

class KepsekBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KepsekBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<(IconData, String)> items = const [
      (Icons.home_rounded, 'Dashboard'),
      (Icons.groups_rounded, 'Kesiswaan'),
      (Icons.menu_book_rounded, 'Kurikulum'),
      (Icons.inventory_2_rounded, 'Sarpras'),
      (Icons.campaign_rounded, 'Humas'),
      (Icons.receipt_long_rounded, 'Jurnal'),
      (Icons.assignment_turned_in_rounded, 'Absensi'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        final compact = constraints.maxWidth < 430;
        final canFillRow = compact || constraints.maxWidth >= 720;
        final itemWidth = isWide ? 132.0 : compact ? 72.0 : 92.0;

        return Container(
          height: compact ? 78 : 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: canFillRow
              ? Row(
                  children: List.generate(items.length, (index) {
                    return Expanded(
                      child: _NavItem(
                        icon: items[index].$1,
                        label: items[index].$2,
                        isSelected: currentIndex == index,
                        isWide: isWide,
                        compact: compact,
                        onTap: () => onTap(index),
                      ),
                    );
                  }),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: List.generate(items.length, (index) {
                      return SizedBox(
                        width: itemWidth,
                        child: _NavItem(
                          icon: items[index].$1,
                          label: items[index].$2,
                          isSelected: currentIndex == index,
                          isWide: isWide,
                          compact: compact,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  ),
                ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isWide;
  final bool compact;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isWide,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFF2F6BFF)
        : const Color(0xFF8D97B2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: compact ? 8 : 10),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : isWide ? 12 : 8,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFBFD1FF)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: compact ? 20 : 22),
            SizedBox(height: compact ? 4 : 6),
            Text(
              compact ? _shortLabel(label) : label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 9 : isWide ? 12 : 11,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortLabel(String value) {
    switch (value) {
      case 'Dashboard':
        return 'Home';
      case 'Kesiswaan':
        return 'Siswa';
      case 'Kurikulum':
        return 'Kuri';
      case 'Sarpras':
        return 'Sarpras';
      case 'Humas':
        return 'Humas';
      case 'Jurnal':
        return 'Jurnal';
      case 'Absensi':
        return 'Absensi';
      default:
        return value;
    }
  }
}
