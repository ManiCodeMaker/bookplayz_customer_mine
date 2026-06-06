import 'package:flutter/material.dart';

/// A box that renders an inset (inner) shadow effect —
/// mimicking the CSS `inset box-shadow` look.
class InsetShadowBox extends StatelessWidget {
  final double size;
  final Widget? child;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color shadowColor;

  const InsetShadowBox({
    super.key,
    this.size = 72,
    this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.backgroundColor = const Color.fromARGB(255, 245, 25, 25),
    this.shadowColor = const Color.fromARGB(255, 74, 175, 84),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        // Outer subtle border to complete the look
        border: Border.all(
          color: shadowColor.withValues(alpha: 0.08),
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // ── Child content ──
            if (child != null)
              Center(child: child!),

            // ── Inset shadow overlay ──
            Positioned.fill(
              child: CustomPaint(
                painter: _InsetShadowPainter(
                  borderRadius: borderRadius,
                  shadowColor: shadowColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsetShadowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color shadowColor;

  const _InsetShadowPainter({
    required this.borderRadius,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // Top-left inner shadow
    final paintTL = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          shadowColor.withValues(alpha: 0.13),
          shadowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    // Bottom-right highlight (light reflection)
    final paintBR = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, paintTL);
    canvas.drawRect(rect, paintBR);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetShadowPainter old) => false;
}