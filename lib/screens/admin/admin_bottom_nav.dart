import 'package:flutter/material.dart';

/// Indices:
/// 0 = Users | 1 = Violations | 2 = Dashboard(FAB) | 3 = Payments | 4 = Reports
class AdminBottomNav extends StatelessWidget {
  
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AdminBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const barColor = Color(0xFF111827); // Deep Charcoal from your palette
    const unselected = Colors.white70;
    const selected = Colors.white;

    return BottomAppBar(
      color: barColor,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(
              icon: Icons.manage_accounts_rounded,
              label: 'Users',
              color: selectedIndex == 0 ? selected : unselected,
              bold: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _item(
              icon: Icons.rule_rounded,
              label: 'Violations',
              color: selectedIndex == 1 ? selected : unselected,
              bold: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),

            // Leave room for FAB notch
            const SizedBox(width: 64),

            _item(
              icon: Icons.payments_rounded,
              label: 'Payments',
              color: selectedIndex == 3 ? selected : unselected,
              bold: selectedIndex == 3,
              onTap: () => onChanged(3),
            ),
            _item(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              color: selectedIndex == 4 ? selected : unselected,
              bold: selectedIndex == 4,
              onTap: () => onChanged(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required Color color,
    required bool bold,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
