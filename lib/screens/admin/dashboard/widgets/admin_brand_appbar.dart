import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtvts_app/widgets/logout_action.dart';
import '../../../../core/brand_assets.dart';
import '../../notifications/providers/admin_notifications_provider.dart';
import '../../notifications/admin_notifications_screen.dart';
import '../../../../core/brand_assets.dart';

class AdminBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminBrandAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800);

    return AppBar(
      titleSpacing: 12,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              BrandAssets.logo, // ✅ uses your TMU/MTVTS logo
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text('Administrator', style: titleStyle),
        ],
      ),
        actions: [
          // Notification Bell
          Consumer<AdminNotificationsProvider>(
            builder: (context, p, _) {
              final count = p.unresolvedCount;
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
                  ).then((_) => p.fetchRequests());
                },
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const LogoutAction(),
        ],
    );
  }
}
