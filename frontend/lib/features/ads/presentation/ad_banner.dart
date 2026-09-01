import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_background.dart';
import '../domain/ad_models.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key, required this.ad, this.onTap});

  final AdSlot ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _parseColor(ad.accentHex) ?? BauhausColors.brand;
    return PressableScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 122),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: accent,
          border: Border.all(color: BauhausColors.ink, width: 3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ad.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  if (ad.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ad.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GeometricMark(color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  ad.actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String raw) {
    final value = raw.replaceFirst('#', '');
    if (value.length != 6) return null;
    final parsed = int.tryParse('FF$value', radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
