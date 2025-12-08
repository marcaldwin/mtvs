// lib/screens/admin/users/widgets/role_filter_bar.dart
import 'package:flutter/material.dart';

class RoleFilterBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const RoleFilterBar({Key? key, required this.value, required this.onChanged})
    : super(key: key);

  static const _roles = <_RoleOption>[
    _RoleOption(key: 'all', label: 'All', icon: Icons.group),
    _RoleOption(key: 'admin', label: 'Admins', icon: Icons.verified_user),
    _RoleOption(key: 'enforcer', label: 'Enforcers', icon: Icons.shield),
    _RoleOption(
      key: 'cashier',
      label: 'Cashiers',
      icon: Icons.account_balance_wallet,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBg = theme.colorScheme.primary.withOpacity(0.12);
    final selectedBorder = theme.colorScheme.primary.withOpacity(0.22);
    final unselectedBg = Colors.transparent;
    final unselectedBorder = Colors.white.withOpacity(0.06);

    // Left padding to match typical list padding in your screen.
    const leftPadding = 16.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(leftPadding, 6, 16, 6),
      child: SizedBox(
        height: 44, // fixed row height so chips stay compact and aligned
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _roles.map((r) {
              final isSelected = r.key == value;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    if (!isSelected) onChanged(r.key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: 40,
                    constraints: const BoxConstraints(minWidth: 72),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedBg : unselectedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? selectedBorder : unselectedBorder,
                        width: isSelected ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          r.icon,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final String key;
  final String label;
  final IconData icon;
  const _RoleOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}
