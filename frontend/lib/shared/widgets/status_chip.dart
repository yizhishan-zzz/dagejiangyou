import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isInk = color == BauhausColors.ink;
    final foreground = color == BauhausColors.brandSoft
        ? BauhausColors.brandDark
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isInk
            ? Colors.white
            : color == BauhausColors.brandSoft
            ? BauhausColors.brandSoft
            : color.withValues(alpha: 0.16),
        border: Border.all(color: BauhausColors.ink, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isInk ? BauhausColors.ink : foreground,
            ),
          ),
        ],
      ),
    );
  }
}
