import 'package:flutter/material.dart';
import 'package:mtvts_app/widgets/logout_action.dart';
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
      actions: const [LogoutAction()],
    );
  }
}
