import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import 'app_loader.dart';

// ── Sport Filter Chips Row ────────────────────────────────
class SportFilterRow extends StatelessWidget {
  final List<Map<String, String>> sports;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const SportFilterRow({
    super.key,
    required this.sports,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final isActive = activeIndex == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: SportFilterCard(
              label: sports[i]['label']!,
              icon: sports[i]['icon']!,
              isActive: isActive,
            ),
          );
        },
      ),
    );
  }
}

// ── Single Sport Filter Card ──────────────────────────────
class SportFilterCard extends StatelessWidget {
  final String label;
  final String icon;
  final bool isActive;

  const SportFilterCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
  });

  bool get _isNetwork =>
      icon.startsWith('http://') || icon.startsWith('https://');

  bool get _isSvg =>
      icon.toLowerCase().endsWith('.svg') || icon.contains('.svg');

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? Colors.white : AppColors.navyBlue;
    final labelColor = isActive
        ? AppColors.limeGreen
        : AppColors.white.withValues(alpha: 0.6);

    final iconOnly = Center(child: _buildIcon(iconColor));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isActive ? AppColors.limeGreen : AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: isActive
                  ? const EdgeInsets.all(17)
                  : const EdgeInsets.all(4),
              child: isActive
                  ? iconOnly
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(13),
                      child: iconOnly,
                    ),
            ),
            if (!isActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: const _SportTabInnerShadow(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(Color iconColor) {
    if (icon.isEmpty) {
      return Icon(Icons.sports, color: iconColor, size: 36);
    }

    if (_isNetwork) {
      if (_isSvg) {
        return SvgPicture.network(
          icon,
          width: 36,
          height: 36,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          placeholderBuilder: (_) => const AppLoader(size: 36),
        );
      } else {
        // JPEG/PNG network image (e.g. Basketball)
        return SizedBox(
          width: 36,
          height: 36,
          child: Image.network(
            icon,
            fit: BoxFit.contain,
            color: iconColor,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.sports, color: iconColor, size: 36),
          ),
        );
      }
    }

    // Local SVG asset
    return SvgPicture.asset(
      icon,
      width: 36,
      height: 36,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}

// ── Sort / Filter Chips Row ───────────────────────────────
class VenueFilterChipsRow extends StatelessWidget {
  final List<VenueFilterChipData> chips;

  const VenueFilterChipsRow({
    super.key,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: chips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: VenueFilterChip(data: chip),
              ),
            )
            .toList(),
      ),
    );
  }
}

class VenueFilterChipData {
  final String label;
  final IconData? icon;
  final bool hasDropdown;
  final VoidCallback? onTap;

  const VenueFilterChipData({
    required this.label,
    this.icon,
    this.hasDropdown = false,
    this.onTap,
  });
}

class VenueFilterChip extends StatelessWidget {
  final VenueFilterChipData data;

  const VenueFilterChip({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              data.hasDropdown
                  ? Icons.keyboard_arrow_down_rounded
                  : (data.icon ?? Icons.swap_vert_rounded),
              color: AppColors.white.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SportTabInnerShadow extends CustomPainter {
  const _SportTabInnerShadow();

  static const double _r = 14;
  static const double _b = 7;
  static const Color _c = Color(0x44000000);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_r),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..color = _c
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _b);

    final w = size.width;
    final h = size.height;
    const b = _b;

    canvas.drawRect(Rect.fromLTWH(-b, -b * 2, w + b * 2, b * 2), paint);
    canvas.drawRect(Rect.fromLTWH(-b, h, w + b * 2, b * 2), paint);
    canvas.drawRect(Rect.fromLTWH(-b * 2, -b, b * 2, h + b * 2), paint);
    canvas.drawRect(Rect.fromLTWH(w, -b, b * 2, h + b * 2), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SportTabInnerShadow old) => false;
}