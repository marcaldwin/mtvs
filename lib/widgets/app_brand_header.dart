import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const AppBrandHeader({
    super.key,
    this.title = 'MTVTS',
    this.subtitle = 'TMEU Kidapawan',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/tmeu_logo.png',
              width: 44,
              height: 44,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.white.withOpacity(.85)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
