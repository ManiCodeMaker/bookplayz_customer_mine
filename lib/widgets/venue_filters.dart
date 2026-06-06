import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

// ── Sport Filter Chips Row ────────────────────────────────
class SportFilterRow extends StatelessWidget {
  final List<Map<String, String>> sports;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  // Optional overrides for use on white/light backgrounds (e.g. venue detail)
  final Color? inactiveBgColor;
  final Color? inactiveBorderColor;
  final Color? inactiveIconColor;
  final Color? inactiveLabelColor;

  const SportFilterRow({
    super.key,
    required this.sports,
    required this.activeIndex,
    required this.onChanged,
    this.inactiveBgColor,
    this.inactiveBorderColor,
    this.inactiveIconColor,
    this.inactiveLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
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
              inactiveBgColor: inactiveBgColor,
              inactiveBorderColor: inactiveBorderColor,
              inactiveIconColor: inactiveIconColor,
              inactiveLabelColor: inactiveLabelColor,
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

  // Optional color overrides (for light bg contexts)
  final Color? inactiveBgColor;
  final Color? inactiveBorderColor;
  final Color? inactiveIconColor;
  final Color? inactiveLabelColor;

  const SportFilterCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    this.inactiveBgColor,
    this.inactiveBorderColor,
    this.inactiveIconColor,
    this.inactiveLabelColor,
  });

  bool get _isNetwork =>
      icon.startsWith('http://') || icon.startsWith('https://');

  bool get _isSvg =>
      icon.toLowerCase().endsWith('.svg') || icon.contains('.svg');

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? AppColors.limeGreen
        : (inactiveBgColor ?? AppColors.white.withValues(alpha: 0.08));

    final borderColor = isActive
        ? AppColors.limeGreen
        : (inactiveBorderColor ?? AppColors.white.withValues(alpha: 0.15));

    final iconColor = isActive
        ? AppColors.navyBlue
        : (inactiveIconColor ?? AppColors.white);

    final labelColor = isActive
        ? AppColors.navyBlue
        : (inactiveLabelColor ?? AppColors.white.withValues(alpha: 0.8));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(iconColor),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
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
          placeholderBuilder: (_) => SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: iconColor.withValues(alpha: 0.4),
            ),
          ),
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