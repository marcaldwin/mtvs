import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;
  final Color accent;
  final double width;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF192231),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: accent.withOpacity(.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    value != null ? value.toString() : '—',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
