import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppBackdrop extends StatefulWidget {
  const AppBackdrop({super.key, required this.child});
  final Widget child;

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _MemphisPainter(isDark: isDark, animation: _controller),
              child: ColoredBox(
                color: (isDark ? BauhausColors.darkPaper : BauhausColors.paper)
                    .withValues(alpha: .88),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MemphisPainter extends CustomPainter {
  _MemphisPainter({required this.isDark, required Animation<double> animation})
    : _animation = animation,
      super(repaint: animation);

  final bool isDark;
  final Animation<double> _animation;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = _animation.value * math.pi * 2;
    final alpha = isDark ? .16 : .22;
    final coral = Paint()..color = BauhausColors.coral.withValues(alpha: alpha);
    final cobalt = Paint()
      ..color = BauhausColors.cobalt.withValues(alpha: alpha);
    final yellow = Paint()
      ..color = BauhausColors.yellow.withValues(alpha: alpha);
    final ink = Paint()
      ..color = (isDark ? Colors.white : BauhausColors.ink).withValues(
        alpha: .12,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.save();
    canvas.translate(math.sin(phase) * 5, math.cos(phase) * 4);
    canvas.drawCircle(Offset(size.width - 34, 76), 44, yellow);
    canvas.drawRect(Rect.fromLTWH(-28, size.height * .33, 74, 32), cobalt);
    final triangle = Path()
      ..moveTo(size.width - 82, size.height * .58)
      ..lineTo(size.width - 24, size.height * .64)
      ..lineTo(size.width - 70, size.height * .69)
      ..close();
    canvas.drawPath(triangle, coral);
    canvas.restore();

    final wave = Path();
    final startY = size.height * .82;
    wave.moveTo(-8, startY);
    for (var x = -8.0; x <= size.width * .45; x += 8) {
      wave.lineTo(x, startY + math.sin((x / 18) + phase) * 8);
    }
    canvas.drawPath(wave, ink);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * .75 + (i % 2) * 16, 180 + i * 17),
        3,
        ink..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MemphisPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class BauhausPanel extends StatelessWidget {
  const BauhausPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.accent,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = isDark ? const Color(0xFFE8E8E8) : BauhausColors.ink;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? BauhausColors.darkPanel : Colors.white),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: outline, width: 2.5),
        boxShadow: [
          BoxShadow(color: outline, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (accent != null)
            Positioned(
              top: -28,
              right: -28,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: outline, width: 2.5),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class SlashedDivider extends StatelessWidget {
  const SlashedDivider({super.key, this.color = BauhausColors.ink});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 12, child: CustomPaint(painter: _SlashPainter(color)));
}

class GeometricMark extends StatelessWidget {
  const GeometricMark({super.key, required this.color, this.size = 34});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _SoyBottlePainter(color)),
  );
}

class CollageServiceIcon extends StatelessWidget {
  const CollageServiceIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 1,
            child: Transform.rotate(
              angle: .18,
              child: Container(
                width: size * .72,
                height: size * .72,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: BauhausColors.ink, width: 2.5),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size * .76,
              height: size * .76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: BauhausColors.ink, width: 2.5),
              ),
              child: Icon(icon, color: BauhausColors.ink, size: size * .42),
            ),
          ),
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              width: size * .2,
              height: size * .2,
              decoration: const BoxDecoration(
                color: BauhausColors.coral,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductNavIcon extends StatelessWidget {
  const ProductNavIcon({
    super.key,
    required this.icon,
    required this.selected,
    required this.color,
    required this.variant,
  });

  final IconData icon;
  final bool selected;
  final Color color;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = isDark && !selected ? Colors.white : BauhausColors.ink;
    return AnimatedRotation(
      duration: const Duration(milliseconds: 220),
      turns: selected ? (variant.isEven ? -.025 : .025) : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1.08 : .94,
        child: SizedBox(
          width: 42,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 38 : 30,
                height: selected ? 30 : 24,
                decoration: BoxDecoration(
                  color: selected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: outline, width: 2.5),
                ),
              ),
              Icon(
                icon,
                size: 21,
                color: selected
                    ? (color == BauhausColors.cobalt
                          ? Colors.white
                          : BauhausColors.ink)
                    : outline,
              ),
              Positioned(
                right: variant == 2 ? 1 : null,
                left: variant == 2 ? null : 1,
                top: variant.isEven ? 0 : null,
                bottom: variant.isEven ? null : 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: variant == 3
                        ? BauhausColors.mint
                        : BauhausColors.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: outline, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  _SlashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SlashPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SoyBottlePainter extends CustomPainter {
  _SoyBottlePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = BauhausColors.ink;
    final fill = Paint()..color = color;
    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .18,
        size.height * .25,
        size.width * .53,
        size.height * .68,
      ),
      Radius.circular(size.width * .08),
    );
    canvas.drawRRect(bottle, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .24,
          size.height * .31,
          size.width * .41,
          size.height * .56,
        ),
        Radius.circular(size.width * .05),
      ),
      fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .31,
        size.height * .11,
        size.width * .27,
        size.height * .19,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .36,
        size.height * .08,
        size.width * .17,
        size.height * .11,
      ),
      fill,
    );
    final label = Paint()..color = BauhausColors.ink.withValues(alpha: .9);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .29,
        size.height * .50,
        size.width * .31,
        size.height * .16,
      ),
      label,
    );
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .75),
      size.width * .09,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SoyBottlePainter oldDelegate) =>
      oldDelegate.color != color;
}

class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
